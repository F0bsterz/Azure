### FUNCTIONS 

Function Get-MyModule 
{ 
	Param([string]$name) 
	if(-not(Get-Module -name $name)) 
	{ 
		if(Get-Module -ListAvailable | Where-Object { $_.name -eq $name }) 
		{ 
			Import-Module -Name $name 
			$true 
		} #end if module available then import 
		else { $false } #module not available 
	} # end if not module 
	else { $true } #module already loaded 
} #end function get-MyModule 

function list2Menu ($myList = $null, $listHeader = $null, $ListName = $null, $fontColor = "white" ) 
{	
	if ($myList -eq $null) {return $myList} 
	$useName = $null
	$listCount = $myList.count
	$BreakLoop = $false
	do
	{	
		Write-Host " =============================================" -ForegroundColor $fontColor
		if ($listHeader -ne $null) {	Write-Host " $listHeader"  -ForegroundColor $fontColor }
		Write-Host " =============================================" -ForegroundColor $fontColor
		
		For ($i=0; $i -lt $listCount ; $i++ )
		{ 
			# 1= name, 2= label, 3= root
			if ($listName -ne $null) { $label = $myList[$i].($listName) }
			else { 
				$label = $myList[$i]
			}
			Write-Host " [$i] $label" -ForegroundColor $fontColor
		}
		Write-Host 

		$i-- #count decremented to show 0..N-1
		if ($i -eq 0) { $menuNumber = Read-Host " Select the $listName [0][default=0] " }
			else { $menuNumber = Read-Host " Select the $listName [0..$i][default=0] " }
		
		if ('$menuNumber' -le 0) {$menuNumber = 0 +($menuNumber) } # convert $menuNumber to negative number
		
		if (($menuNumber -ge 0) -and ($menuNumber -le $listCount)) { $BreakLoop = $true }
			#Write-Host " GOOD " -BackgroundColor Yellow -ForegroundColor Red} 
			else { Write-Host " Monkey kick! Not in range! " -BackgroundColor Yellow -ForegroundColor Red }
		
		if ($listName -ne $null) { $selectedItem = $myList[$menuNumber].($listName)}
		else {$selectedItem = $myList[$menuNumber]}

		if ($debugMode) { 
			Write-Host " DEBUG MODE: Header Info   - $listname [list2Menu]" -BackgroundColor DarkBlue -ForegroundColor Yellow 		
			Write-Host " DEBUG MODE: Item Selected - $selectedItem [list2Menu]" -BackgroundColor DarkBlue -ForegroundColor Yellow 
			#Write-Host " Debug Munkey sees : $selectedItem " -ForegroundColor RED -BackgroundColor YELLOW }
		}
	} until ($BreakLoop -eq $true)
	
	return $menuNumber;
} #end function list2Menu


### PARAMETERS
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$PublishingFileDirectory = "$scriptPath\publishingFiles"

### BEGIN
#Azure Powershell Module Check
Write-Host "1. CHECKING FOT AZURE MODULE "
$AzureCheck = get-mymodule -name "azure"

if ($AzureCheck) 
{
	Write-Host " - Azure Module is installed..." -ForegroundColor Green
}
else 
{
	Write-Host " - Azure Module is NOT installed..." -ForegroundColor Red
	Write-Host " - Importing Azure Powershell Cmdlets..." -ForegroundColor Yellow

	# Azure PS Path
	$AzPSPath="C:\Program Files (x86)\Microsoft SDKs\Windows Azure\PowerShell\Azure\"

	# PS checking to see if Azure PS installed
	If(-not(Test-Path -Path $AzPSPath))
	{
		Write-Host
	   	Write-Host "Azure PowerShell not Found, please download and install Azure PowerShell" -ForegroundColor Red
	   	Start-Sleep -s 2
	   	start "https://github.com/Azure/azure-powershell/releases"
	   	Break
	}
	
	Import-Module "C:\Program Files (x86)\Microsoft SDKs\Windows Azure\PowerShell\Azure\Azure.psd1"
	Write-Host " - Azure Module install complete..." -ForegroundColor Green
}

# clean up any existing subscriptions on the host
Write-Host "2. REMOVING CURRENT SUBSCRIPTIONS"
Get-AzureSubscription  | Remove-AzureSubscription -Force
Get-AzureSubscription -ExtendedDetails | Remove-AzureSubscription -Force

# find publishing files
Write-Host "3. FINDING AVAILABLE PUBLISHING FILES"
if (-not(Test-Path -Path $PublishingFileDirectory))
{
    write-host
    Write-Host $PublishingFileDirectory "not found" -ForegroundColor Red -BackgroundColor yellow
    new-item $PublishingFileDirectory -type directory
    Write-Host "Creating directory " $PublishingFileDirectory -ForegroundColor Yellow
}

$publishSettingsList = Get-ChildItem -Path $PublishingFileDirectory -filter *.publishsettings

if ($publishSettingsList -eq $null) 
{
    write-host " - No PublishingFiles Found in [$PublishingFileDirectory]. " -ForegroundColor RED 
    write-host " - Attempting to get publishingFile. " -ForegroundColor Yellow
    Get-AzurePublishSettingsFile
    $downloadFolder = "$env:userprofile\Downloads" 
    write-host " - Moving all Publishing files from [$downloadFolder] to [$publishingFileDirectory]" -ForegroundColor yellow
    move-item -path $downloadFolder\*.publishsettings -destination $publishingFileDirectory

    $publishSettingsList = Get-ChildItem -Path $PublishingFileDirectory -filter *.publishsettings
    #Exit
}
$selectedPublishSettingNumber = List2Menu $publishSettingsList "Available Publishing Files" "Name" "gray"
$PublishingFileFullName = $publishSettingsList[$selectedPublishSettingNumber].FullName 


Write-Host " - PUBLISHING FILES FULL NAME: " $PublishingFileFullName
$currentSub = Import-AzurePublishSettingsFile -PublishSettingsFile $PublishingFileFullName

# Select subscription if there are multiple subscriptions. Ie. EA accounts
$selectedSubName = List2Menu $currentSub "Available Subscription" "Name" "gray"
Select-AzureSubscription  -SubscriptionName ($currentSub[$selectedSubName].Name) 

# Select Default Storage Account
Write-Host "5. FINDING AVAILABLE STORAGE ACCOUNTS"
$storageAccountList = Get-AzureStorageAccount 

if ($storageAccountList -eq $null) 
{
    write-host " - No Storage Accounts Found on this Account" -ForegroundColor Yellow 
    Get-AzureSubscription -ExtendedDetails | Set-AzureSubscription 
}
else 
{
    $storageAccountNumber = list2menu $storageAccountList "Available Storage Accounts" "StorageAccountName" "Gray"
    $selectedStorageAccount = $storageAccountList[$storageAccountNumber].StorageAccountName
    Get-AzureSubscription -ExtendedDetails | Set-AzureSubscription -CurrentStorageAccountName $selectedStorageAccount
}


