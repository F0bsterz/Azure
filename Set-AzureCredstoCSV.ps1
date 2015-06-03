<# 
.SYNOPSIS 
    Saves Local User and Domain User information as an Encrypted string. Then saves that information as a CSV File and exports the encryptedKey file to make the CSV file portable for decrytion.

.DESCRIPTION 

.PARAMETER
    - Path - Folder Location on where to export the script. Ie. C:\output
    - KeyPassPhrase - PassPhrase to be used when generating the key

.EXAMPLE
    Set-AzureCredstoCSV.ps1
    Set-AzureCredstoCSV.ps1 -Path C:\Output 
    Set-AzureCredstoCSV.ps1 -Path C:\Output -KeyPassPhrase "HelloWorld"
    
.OUTPUTS
    
.NOTES 
    Author: Paul Bui
    Version : 1.0
    
.REQUIREMENTS

.LINK 
    
#>  
Param(
    
    # The directory path to save credentials.csv and key.txt 
    [Parameter(Mandatory = $false)]
    $Path = $null, # c:\temp, default it creates a config folder where the actual script resides and places the files in that folder
    
    # Create encryption key with PassPhrase. Must be under 23 characters
    [Parameter(Mandatory = $false)]
    $keyPassphrase = $null # ie "12345678901234567890123" 

)

function get-randomKey ($keyLength) 
{
    [int[]]$randomKey =@()

    for ($i=1; $i-le $keyLength; $i++) 
    {
        #$randomNumber = 
        $randomKey+= (get-random -Minimum 1 -Maximum 255)
    }
    
    return $randomKey
}

function get-randomString ([int]$Length=8)
{
    $charSet = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
    $result = ""
    for ($x = 0; $x -lt $Length; $x++) {
        $result += $charSet | Get-Random
    }
    return $result
}

function get-encryptionKey ($passPhrase = $null) 
{
    if ($passPhrase -ne $null) 
    {
        #check length 
        if ( ($passPhrase.length) -le 23 )
        {
            # GO
            $randomSalt= get-randomString

            # Create a COM Object for RijndaelManaged Cryptography
            $rComObj = new-Object System.Security.Cryptography.RijndaelManaged
            # Convert the Passphrase to UTF8 Bytes
            $pass = [Text.Encoding]::UTF8.GetBytes($Passphrase)
            # Convert the Salt to UTF8 Bytes
            $salt = [Text.Encoding]::UTF8.GetBytes($randomSalt)

            # Create the Encryption Key using the passphrase and salt at 192 bit key size and 192 bit Block Size
            $encryptionKey = (new-Object Security.Cryptography.Rfc2898DeriveBytes $pass, $salt, 1000)
            $rComObj.KeySize = 192
            $rComObj.Key = $encryptionKey.GetBytes($rComObj.KeySize / 8)
            $rComObj.BlockSize = 192
            $rComObj.IV = $encryptionKey.GetBytes($rComObj.BlockSize / 8)
 
            # Set the CipherMode to Cipher Block Chaining
            $rComObj.Mode = [System.Security.Cryptography.CipherMode]::CBC
 
            # Create the Encryptor using the Key and IV 
            $tmpEncryptor = $rComObj.CreateEncryptor()
            # Create a MemoryStream to do the encryption in
            $MemStream = new-Object IO.MemoryStream
            # Create the new Cryptology Stream and Outputs to the Memory Stream object $MemStream
            $CryptoStream = new-Object Security.Cryptography.CryptoStream $MemStream,$tmpEncryptor,"Write"
            # Create a StreamWriter for the new Cryptology Stream
            $StreamWriter = new-Object IO.StreamWriter $CryptoStream
            # Write the passphrase in the Cryptology Stream
            $StreamWriter.Write($passphrase)
 
            # Stop the StreamWriter, CryptologyStream, and MemoryStream
            $StreamWriter.Close()
            $CryptoStream.Close()
            $MemStream.Close()

            # Clear the IV from memory to prevent memory read attacks
            $rComObj.Clear() 
 
            [byte[]]$enckey = $MemStream.ToArray() # Byte array from the encrypted memory stream
            if ($debugMode)
            {
                write-host "       ------------------------------------------------------------------------"
                write-host "        Passphrase :$Passphrase"
                write-host "        Salt: $randomSalt"
                write-host "       ------------------------------------------------------------------------"
                write-host "        Byte Array" 
                write-host "       ------------------------------------------------------------------------"
                write-host "       {" $enckey "}" -ForegroundColor Gray
                write-host
                write-host "       ------------------------------------------------------------------------"
                write-host "        Array count = " ($enckey.Count) -ForegroundColor Cyan
                write-host "       ------------------------------------------------------------------------"
                $encString = [Convert]::ToBase64String($enckey)
                write-host $encString
            }
        } 
        else 
        {
            throw "Passphrase cannot be over 23 characters"
        }
    }
    else 
    {
        throw "Passphrase cannot be null"
    }
    return $encKey 
}

cls
# DEFAULT PARAMETERS 
$timeStamp = Get-Date
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$ColorSelected = "gray"
$lineColor = "white"
$txtColor = "cyan"

write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
write-host "    _____   ___ ______         __ __  _____   ___  ____      __  ____     ___  ___   _____ ______   ___     __ _____ __ __ "  -ForegroundColor $txtcolor
write-host "   / ___/  /  _]      |       |  |  |/ ___/  /  _]|    \    /  ]|    \   /  _]|   \ / ___/|      | /   \   /  ] ___/|  |  |"  -ForegroundColor $txtcolor
write-host "  (   \_  /  [_|      | _____ |  |  (   \_  /  [_ |  D  )  /  / |  D  ) /  [_ |    (   \_ |      ||     | /  (   \_ |  |  |"  -ForegroundColor $txtcolor
write-host "   \__  ||    _]_|  |_||     ||  |  |\__  ||    _]|    /  /  /  |    / |    _]|  D  \__  ||_|  |_||  O  |/  / \__  ||  |  |"  -ForegroundColor $txtcolor
write-host "   /  \ ||   [_  |  |  |_____||  :  |/  \ ||   [_ |    \ /   \_ |    \ |   [_ |     /  \ |  |  |  |     /   \_/  \ ||  :  |"  -ForegroundColor $txtcolor
write-host "   \    ||     | |  |         |     |\    ||     ||  .  \\     ||  .  \|     ||     \    |  |  |  |     \     \    | \   / "  -ForegroundColor $txtcolor
write-host "    \___||_____| |__|          \__,_| \___||_____||__|\_| \____||__|\_||_____||_____|\___|  |__|   \___/ \____|\___|  \_/  "  -ForegroundColor $txtcolor
write-host
write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
write-Host "   Set-AzureCredsToCsv v1.0"  -ForegroundColor $txtcolor
write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
write-Host "   VERIFYING PRE-REQUISITES"  -ForegroundColor $txtcolor
write-host " ====================================================================================================================================" -ForegroundColor $lineColor 

# If no path was passed, set path to path where script resides +"\config"
if ($path -eq $null)
{
    $Path = $scriptPath+"\config"
}

# output folder
$credentialsFullName = $Path+"\credentials.csv"
if (Test-Path -Path $credentialsFullName -IsValid)
{
    write-host "    - [$credentialsFullName] Syntax Valid: PASSED " -ForegroundColor green
    if (Test-Path -Path $Path )
    {
        write-host "    - [$Path] Folder Valid: PASSED " -ForegroundColor green
    }
    else 
    {
        throw "invalid Folder Path [$Path]"
        exit 1
    }
}
else 
{
    throw "invalid Folder Path [$Path]"
    exit 1
}

$encryptionKeyFullName = $Path+"\key.txt"
$boolCheck = Test-Path -Path $encryptionKeyFullName -IsValid

if (Test-Path -Path $encryptionKeyFullName -IsValid)
{
    write-host "    - [$encryptionKeyFullName] Syntax Valid: PASSED " -ForegroundColor green
    if (Test-Path -Path $Path )
    {
        write-host "    - [$Path] Folder Valid: PASSED " -ForegroundColor green
    }
    else 
    {
        throw "invalid Folder Path [$Path]"
        exit 1
    }
}
else 
{
    throw "invalid Folder Path [$Path]"
    exit 1
}

# Generate Random EncryptionKey if one was not passed
if ($keyPassphrase -eq $null) 
{
    Write-host "    - Passphrase not detected, creating random encryption key" -ForegroundColor Yellow
    $key = get-encryptionKey (get-randomString -Length 23) 
}
else 
{
    Write-host "    - Passphrase detected, creating encryption key with passphrase [$keyPassphrase]" -ForegroundColor Green
    $key = get-encryptionKey ($keyPassphrase) 
}

write-host " ====================================================================================================================================" -ForegroundColor $lineColor
write-Host "   FETCHING USER CREDENTIALS"  -ForegroundColor $txtcolor
write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
 
$localCreds = Get-Credential -Message "Enter your Local Credentials. ie. datacenter" ure
if(   (($localCreds.GetNetworkCredential().password) -eq "") -or (($localCreds.UserName) -eq $null)   )
{
    throw "Invalid Login info, please verify your username and password"
    exit 1
}
write-host "   - Local Admin Password Detected" -ForegroundColor Green

$DomainCreds = Get-Credential -Message "Enter your Domain credentials. ie. domain\user" 
if(   (($DomainCreds.GetNetworkCredential().password) -eq "") -or (($DomainCreds.UserName) -eq $null)   )
{
    throw "Invalid Login info, please verify your username and password"
    exit 1
}
write-host "   - Domain User Password Detected" -ForegroundColor Green
write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
write-Host "   CREATING CUSTOM CREDENTIAL OBJECT"  -ForegroundColor $txtcolor
write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
# Create Credential Object to export to CSV
$vmCredsObj = New-Object PSObject
$vmCredsObj | Add-Member -MemberType NoteProperty -Name LocalUsername -Value ($localCreds.username)
$vmCredsObj | Add-Member -MemberType NoteProperty -Name LocalPassword -Value ( ($localCreds.GetNetworkCredential().password) | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $Key )
$vmCredsObj | Add-Member -MemberType NoteProperty -Name DomainUsername -Value ($DomainCreds.username)
$vmCredsObj | Add-Member -MemberType NoteProperty -Name DomainPassword -Value ( ($DomainCreds.GetNetworkCredential().password) | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key $Key )
$vmCredsObj | Add-Member -MemberType NoteProperty -Name ModifiedDate -Value (Get-Date)

write-Host "   ENCRYPTED CREDENTIALS"  -ForegroundColor $txtcolor
write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
write-host "   - The following credentials will be saved to the CSV file" -ForegroundColor $txtcolor
write-host "   - Local Username  : " ($vmCredsObj.LocalUsername) -ForegroundColor $colorselected
write-host "   - Local Password  : " ($vmCredsObj.LocalPassword) -ForegroundColor $colorselected
write-host "   - Domain Username : " ($vmCredsObj.DomainUsername) -ForegroundColor $colorselected
write-host "   - Domain Password : " ($vmCredsObj.DomainPassword) -ForegroundColor $colorselected

write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
write-Host "   DECRYPTED CREDENTIALS"  -ForegroundColor $txtcolor
write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
# Creates temp credential objects to display unencrypted passwords
$vmLocalcreds = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist ($vmCredsObj.localUsername),( ($vmCredsObj.localPassword) | ConvertTo-SecureString -Key $key)
$vmDomaincreds  = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist ($vmCredsObj.domainUsername),( ($vmCredsObj.domainPassword) | ConvertTo-SecureString -key $key)
write-host "   - Local Username  : " ($vmLocalcreds.UserName) -ForegroundColor $colorselected
write-host "   - Local Password  : " ($vmLocalcreds.GetNetworkCredential().Password) -ForegroundColor $colorselected
write-host "   - Domain Username : " ($vmDomaincreds.UserName) -ForegroundColor $colorselected
write-host "   - Domain Password : " ($vmDomaincreds.GetNetworkCredential().Password) -ForegroundColor $colorselected

write-host " ====================================================================================================================================" -ForegroundColor $lineColor 
write-Host "   CREATING FILES "  -ForegroundColor $txtcolor
write-host " ====================================================================================================================================" -ForegroundColor $lineColor 

$vmCredsObj | Export-Csv -Path $credentialsFullName -NoTypeInformation -Force #Exports encrypted credential file
$key | Out-File -FilePath $encryptionKeyFullName -Force  #exports encryption key to decrypt file
write-host "    - Credentials Filename    : " $credentialsFullName 
write-host "    - Encryption Key Filename : " $encryptionKeyFullName