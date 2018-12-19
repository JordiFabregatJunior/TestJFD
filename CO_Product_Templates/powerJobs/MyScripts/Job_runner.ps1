<#Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$filename = "Main.iam"
$file = Get-VaultFile -Properties @{"Name" = $filename}
$job = Add-VaultJob -Name "" -Description "-" -Parameters @{EntityClassId = "FILE"; EntityId = $vfile.Id} -Priority 10
####________NoTouching!_________#>

$filename = "Main.iam"

$filename = "TestDraw0.idw"			
$NewFileName = "TestDraw"
$vFile = Get-VaultFile -Properties @{Name = $filename}

$Number = "100002"
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/Inventor/Test-Related-IDW")
$sourceFiles = $vault.DocumentService.GetLatestFilesByFolderId($folder.Id,$false)
$file = Add-VaultFile -From "$/Designs/Folder-Tests" -To "$/PowerVaultTestFiles/pV_7.test"