#Change path if module is stored elsewhere
import-module -force ../module/ema.psm1
#Credentials for EMA user with read access to companies.
Invoke-EmaAuthenticate -EmaUsername "user@example.com" -EmaPassword "passwordhere"

#Get all companies under MSP account
$Companies = Get-EmaCompanies -MasterCompanyId (Get-EmaMasterCompanyID)
#Loop through all companies and get details
foreach ($Company in $Companies) {
    Get-EmaCompanyDetails -CompanyPublicId ($Company.publicId)
    
    #If needed, you can also get license information using the following calls:
    $Licenses = Get-EmaCompanyLicenses -CompanyPublicId ($Company.publicId)
    foreach ($License in $Licenses) {
        Get-EmaLicenseDetails -PublicLicenseKey $License
    }
}