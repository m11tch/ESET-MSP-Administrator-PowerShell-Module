function Invoke-EmaAuthenticate {
    param(
        $EmaUsername,
        $EmaPassword
    )

    $Body = @{
        "username" = "$EmaUsername"
        "password" = "$EmaPassword"
    } | ConvertTo-Json

    try {
        $AuthResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/Token/Get' -Method Post -Headers @{'accept'= '*/*'} -Body $Body -contentType 'application/json'
    
        #accessToken for further aPI reqs
        $JWT = $AuthResponse.accessToken
        Set-Variable -name Headers -scope Script -value @{
            "accept" = "*/*"
            "Authorization" = "Bearer $JWT"
        }        
    } catch { 
        Write-Error($_.ErrorDetails.Message)
        break
    }

}

function Get-EmaCompanies {
    param(
        $MasterCompanyId
    )
    $Body = @{
        "skip" = 0
        "take" =  100
        "companyId" = "$MastercompanyId"
    } | ConvertTo-Json

    Write-Debug($Body)
    $ChildrenResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/Company/Children' -method Post -Headers $Headers -Body $Body -contentType 'application/json'
    $Companies = $ChildrenResponse.companies
    Return $Companies
}

function Get-EmaMasterCompanyID {

    #Get Current User
    $CurrentUserResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/User/Current' -Method Get -Headers $Headers
    Write-Debug ($CurrentUserResponse.company.companyId)
    Return $CurrentUserResponse.company.companyId
}

function Get-EmaCompanyLicenses {
    param(
        $CompanyPublicId
    )
    $Body = @{
        "skip" = 0
        "take" = 100
        "customerId" = "$CompanyPublicId"
    } | ConvertTo-Json


    $LicensesResponse = Invoke-restMethod -Uri 'https://mspapi.eset.com/api/Search/Licenses' -method Post -Headers $Headers -Body $Body -contentType 'application/json'
    $PublicLicenseId = $LicensesResponse.Search.publicLicenseKey
    return $PublicLicenseId
}

function Get-EmaLicenseDetails {
    param(
        $PublicLicenseKey
    )
    $Body = @{
        "publicLicenseKey" = "$PublicLicenseKey"
    } | ConvertTo-Json

    Write-Debug($body)
    $LicenseDetails = Invoke-Restmethod -Uri 'https://mspapi.eset.com/api/License/Detail' -method Post -Headers $Headers -Body $Body -contentType 'application/json'
    Return $LicenseDetails
}

function Set-EmaLicenseQuantity { 
    param(
        $PublicLicenseKey,
        [int]$Quantity
    )
    $Body = @{
        quantity = $Quantity
        publicLicenseKey = $PublicLicenseKey
    } | ConvertTo-Json
    
    Write-Debug($body)
    try { 
        $Request = Invoke-Restmethod -Uri 'https://mspapi.eset.com/api/License/UpdateQuantity' -method Post -Headers $Headers -Body $Body -ContentType 'application/json'
    } catch {
        Write-Error($_.ErrorDetails.Message)
    }
    
}
function Invoke-EmaUpdateLicenses {
    param(
        [switch]$DryRun,
        [string[]]$IgnoredPublicLicenseKeys,
        [int]$MaxPositiveChange,
        [int]$MaxNegativeChange
    )
    $IgnoredPublicLicenseKeys

    #Get companies from MSP
    $Companies = Get-EmaCompanies -MasterCompanyId (Get-EmaMasterCompanyID)
    #Loop through all companies
    foreach ($Company in $Companies) {
        Write-Host("[+] License info for Customer: " + $Company.name + " company ID: " + $company.publicId) -foregroundColor Green
        #Loop through all licenes
        foreach ($PublicId in (Get-EmaCompanyLicenses -CompanyPublicId $Company.publicId)) {
            #Get License details
            $LicenseDetails = (Get-EmaLicenseDetails -PublicLicenseKey $PublicId)
            Write-Host("[-] " + $LicenseDetails.productName + " - " + $LicenseDetails.publicLicenseKey + " purchased seats: " + $LicenseDetails.quantity + " activated seats: " + $LicenseDetails.usage)
            # Only update license quantity if usage is different and not 0
            if (($LicenseDetails.quantity -ne $LicenseDetails.usage) -and ($LicenseDetails.usage -gt 0) -and ($IgnoredPublicLicenseKeys -inotcontains $LicenseDetails.PublicLicenseKey)){ 
                
                #TODO: Add feature to prevent large changes
                #Update License Quantity
                if ($LicenseDetails.quantity -gt $LicenseDetails.usage){
                    Write-Host("[-] Purchased seats is higher than activated seats, difference: " + ($LicenseDetails.usage - $LicenseDetails.quantity))
                    if (($PSBoundParameters.ContainsKey("MaxNegativeChange")) -and ($LicenseDetails.quantity - $LicenseDetails.usage) -gt $MaxNegativeChange) {
                        Write-Host("[-] License change is too big, skipping") -ForegroundColor DarkYellow
                    } else { 
                        if (!$DryRun) {
                            Write-Host("[=] Updating License quantity to: " + $LicenseDetails.usage)
                            Set-EmaLicenseQuantity -PublicLicenseKey $LicenseDetails.publicLicenseKey -Quantity $LicenseDetails.usage
                        }
                    }
                } else {
                    Write-Host("[-] Purchased seats is lower than activated seats, difference: +" + ($LicenseDetails.usage - $LicenseDetails.quantity))
                    if (($PSBoundParameters.ContainsKey("MaxPositiveChange")) -and ($LicenseDetails.usage - $LicenseDetails.quantity) -gt $MaxPositiveChange) {
                        Write-Host("[-] License change is too big, skipping") -ForegroundColor DarkYellow
                    } else { 
                        if (!$DryRun) {
                            Write-Host("[=] Updating License quantity to: " + $LicenseDetails.usage)
                            Set-EmaLicenseQuantity -PublicLicenseKey $LicenseDetails.publicLicenseKey -Quantity $LicenseDetails.usage
                        }
                    }
                }


                
            } else {
                Write-Host("[-] No update needed or license usage is 0") -ForegroundColor DarkYellow
            }
            
        }
    }
}



