#Find Me Info
$azureSubscription = Get-AzureSubscription -ExtendedDetails 
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$timeStamp =  get-date -f yyyy-MM-dd_HH-MM-ss
$filePath = $scriptPath+"\Assessments\"+($azureSubscription.subscriptionName)+"\"+$timeStamp


#Output Folder
if (Test-Path $filePath) { 
    write-host "Output folder Exists: $filePath" -ForegroundColor Yellow
    
    } 
else { 
    write-host "Creating output folder: $filePath" -ForegroundColor Green 
    $createDirectory = new-item -Path $filePath -ItemType directory 
} 

write-host "1. Finding Account Details."  -ForegroundColor Cyan

# Subscription Info
$azureSubscription  | select SubscriptionID, SubscriptionName, AccountAdminLiveEmailId, ServiceAdminLiveEmailId, Accounts | export-csv -Path $filePath\subscriptioninfoBrief.csv -NoTypeInformation 
$azureSubscription | export-csv -Path $filePath\subscriptioninfoDetailed.csv

write-host "2. Finding Network Config."  -ForegroundColor Cyan

# Inventory of Affinity Groups in Selected Subscription 
Get-AzureAffinityGroup | select Name, Label, Description, Location | export-csv -Path $filePath\AffinityGroupsBrief.csv -NoTypeInformation 

# Azure VNET Config
$AzureVnetConfig = Get-AzureVNetConfig -ExportToFile $filePath\VnetConfig.XML
 
write-host "3. Finding Storage Details."  -ForegroundColor Cyan

# Azure Storage Accounts attached to subscription
Get-AzureStorageAccount | select StorageAccountName, Location, AffinityGroup, AccountType | export-csv $filePath\StorageAccount.csv -NoTypeInformation 

$DiskInfo = Get-AzureDisk

# Total Number of VHDs per Storage Account
$DiskInfo | Where-Object { $_.AttachedTo } | Group-Object {$_.Medialink.Host.Split('.')[0]} -NoElement | select Count, Name | export-csv -Path $filePath\VHDCount-byStorageAcct.csv -NoTypeInformation 

# Total Number of VHDs not attached to any VMs per Storage Account 
$DiskInfo | Where-Object {$_.AttachedTo -eq $null} | Group-Object {$_.Medialink.Host.Split('.')[0]} -NoElement | select Count, Name | export-csv -Path $filePath\VHDCount-NotAttached-byStorageAcct.csv -NoTypeInformation 

# Inventory of Disks that are attached to something
$DiskInfo | Where {$_.AttachedTo -ne $null} | select {$_.AttachedTo.RoleName}, {$_.AttachedTo.HostedServiceName}, OS, DisksizeinGB, Location, AffinityGroup, DiskName, MediaLink, SourceImageName  | export-csv $filePath\DataDisksBrief.csv -NoTypeInformation 
$DiskInfo | Where {$_.AttachedTo -ne $null} | export-csv $filePath\DataDisksDetailed.csv -NoTypeInformation 

# Inventory of Disks that are NOT attached to anything
$DiskInfo | Where {$_.AttachedTo -eq $null} | export-csv $filePath\UnattachedDataDisks.csv -NoTypeInformation 

write-host "4. Finding AzureVM Details."  -ForegroundColor Cyan

# Brief Inventory of all VMs in a subscription
get-azurevm | select name, hostname, servicename, ipaddress, PublicIpAddress, instancesize, InstanceFaultDomain, InstanceStatus, Status  | export-csv -path $filePath\AzureVMs.csv -NoTypeInformation 

write-host "5. Finding AzureWebsites Details."  -ForegroundColor Cyan

# Inventory of all Azure Websites in a subscription
$azureWebsiteList = get-azurewebsite
foreach ($azureWebsite in $azureWebsiteList) {
    get-azurewebsite -name ($azureWebsite.name)  | Export-csv -Path $filePath\AzureWebsites.csv -Append -NoTypeInformation 
}

write-host "5. Finding Azure SQL Details."  -ForegroundColor Cyan
$azureSQLServerList = Get-AzureSqlDatabaseServer 

$azureSQLServerList | Export-csv -Path $filePath\AzureSQLServers.csv -Append -NoTypeInformation 

foreach ($azureSQLServer in $azureSQLServerList) {
    $fileName = "SQLServer-"+($azureSQLServer.ServerName)+"-Databases.csv"
    Get-AzureSqlDatabase -ServerName ($azureSQLServer.ServerName)  | Export-csv -Path $filePath\$fileName -Append -NoTypeInformation 
}

