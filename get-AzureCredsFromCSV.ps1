<# 
.SYNOPSIS 
    Decrypts credentials from CSV

.DESCRIPTION 

.NOTES 
    Author: Paul Bui   

.REQUIREMENTS
    Requires Credential and Encryption Key files to be located in folder path listed below

.LINK 
    
#>  
cls
# DEFAULT PARAMETERS 
$debugMode = $false # Additional info to console set to $true
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$path = $scriptPath+"\config"
$colorSelected = "gray"
$lineColor = "white"
$txtColor = "cyan"
$timeStamp = Get-Date
write-host " =========================================================================================================================================" -ForegroundColor $lineColor 
write-host
write-host "    ____    ___ ______         __ __  _____   ___  ____      __  ____     ___  ___   _____ _____  ____   ___   ___ ___    __ _____ __ __ "  -ForegroundColor $txtcolor
write-host "   /    |  /  _]      |       |  |  |/ ___/  /  _]|    \    /  ]|    \   /  _]|   \ / ___/|     ||    \ /   \ |   |   |  /  ] ___/|  |  |"  -ForegroundColor $txtcolor
write-host "  |   __| /  [_|      | _____ |  |  (   \_  /  [_ |  D  )  /  / |  D  ) /  [_ |    (   \_ |   __||  D  )     || _   _ | /  (   \_ |  |  |"  -ForegroundColor $txtcolor
write-host "  |  |  ||    _]_|  |_||     ||  |  |\__  ||    _]|    /  /  /  |    / |    _]|  D  \__  ||  |_  |    /|  O  ||  \_/  |/  / \__  ||  |  |"  -ForegroundColor $txtcolor
write-host "  |  |_ ||   [_  |  |  |_____||  :  |/  \ ||   [_ |    \ /   \_ |    \ |   [_ |     /  \ ||   _] |    \|     ||   |   /   \_/  \ ||  :  |"  -ForegroundColor $txtcolor
write-host "  |     ||     | |  |         |     |\    ||     ||  .  \\     ||  .  \|     ||     \    ||  |   |  .  \     ||   |   \     \    | \   / "  -ForegroundColor $txtcolor
write-host "  |___,_||_____| |__|          \__,_| \___||_____||__|\_| \____||__|\_||_____||_____|\___||__|   |__|\_|\___/ |___|___|\____|\___|  \_/  "  -ForegroundColor $txtcolor
write-host                                                                                                                                       
write-host " =========================================================================================================================================" -ForegroundColor $lineColor 
write-Host "   Get-AzureCredsFromCsv v1.0"  -ForegroundColor $txtcolor
write-host " =========================================================================================================================================" -ForegroundColor $lineColor 
write-Host "   FETCHING FILES"  -ForegroundColor $txtcolor
write-host " =========================================================================================================================================" -ForegroundColor $lineColor 
if (Test-Path -Path $path)
{
     write-host "    - [$path] Folder Valid: PASSED " -ForegroundColor green
}
else
{
    throw "Folder not found [$path]"
}

$encryptionKeyFileFullName = $path+"\key.txt"
if (Test-Path -Path $encryptionKeyFileFullName)
{
     write-host "    - [$encryptionKeyFileFullName] File Found: PASSED " -ForegroundColor green
}
else
{
    throw "File not found [$encryptionKeyFileFullName]"
}
$encryptionKey = Get-Content -Path $encryptionKeyFileFullName -Force 

$vmCredsCSVFileFullName = $path+"\credentials.csv"
if (Test-Path -Path $vmCredsCSVFileFullName)
{
     write-host "    - [$vmCredsCSVFileFullName] File Found: PASSED " -ForegroundColor green
}
else
{
    throw "File not found [$path]"
}

$vmCredsCSV = Import-Csv -Path $vmCredsCSVFileFullName  


write-host " =========================================================================================================================================" -ForegroundColor $lineColor 
write-Host "   FETCHING USER CREDENTIALS"  -ForegroundColor $txtcolor
write-host " =========================================================================================================================================" -ForegroundColor $lineColor 
$vmLocalcreds = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist ($vmCredsCSV.localUsername),( ($vmCredsCSV.localPassword) | ConvertTo-SecureString -Key $encryptionkey)
$vmDomaincreds  = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist ($vmCredsCSV.domainUsername),( ($vmCredsCSV.domainPassword) | ConvertTo-SecureString -key $encryptionkey)
write-host "    - Last Modified Date : " ($vmCredsCSV.ModifiedDate)
write-host "    - Local Username     : " ($vmLocalcreds.UserName)
write-host "    - Local Password     : " ($vmLocalcreds.GetNetworkCredential().Password)
write-host "    - Domain Username    : " ($vmDomaincreds.UserName)
write-host "    - Domain Password    : " ($vmDomaincreds.GetNetworkCredential().Password)
