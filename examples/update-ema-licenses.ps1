#Change path if module is stored elsewhere
import-module -force ../module/ema.psm1
#Credentials for EMA user with write access to companies.
Invoke-EmaAuthenticate -EmaUsername "user@example.com" -EmaPassword "passwordhere"
#Use the following command to check if there are licenses that have a differce between quantity (purchased seats) and usage (activated seats) and up/downgrade the licenses to the number of activated seats 
Invoke-EmaUpdateLicenses

#If you want to ignore certain licenses, you can use: 
#Invoke-EmaUpdateLicenses -IgnoredPublicLicenseKeys "3a9-ms5-pkk","3A9-MS7-9JD"

#If you want to limit changes over a certain threshold you can use: 
#Invoke-EmaUpdateLicenses -MaxPositiveChange 10 -MaxNegativeChange 10
#This example will not perform changes above 10 seats, numbers are customizable and you can differentiatie in Positive and Negative values.

#If you don't want to make changes in you can execute: 
#Invoke-EmaUpdateLicenses -DryRun

#All above parameters can be combined.