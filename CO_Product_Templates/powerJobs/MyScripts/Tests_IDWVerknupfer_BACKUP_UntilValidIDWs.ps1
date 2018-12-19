#it will be awesome
Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$fileID = 2420
$filename = "main.iam"			
#$PVaultFile = Get-VaultFile -Properties @{Id = $fileID}
$PVaultFile = Get-VaultFile -Properties @{Name = $filename}
$file = $vault.DocumentService.GetLatestFileByMasterId($PVaultFile.MasterId)
$fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)
$frgs = New-Object Autodesk.DataManagement.Client.Framework.Vault.Settings.FileRelationshipGatheringSettings
    $frgs.IncludeAttachments = $false
    $frgs.IncludeChildren = $true
    $frgs.IncludeRelatedDocumentation = $true
    $frgs.RecurseChildren = $true
    $frgs.IncludeParents = $true
    $frgs.RecurseParents = $false
    #$frgs.VersionGatheringOption = "Actual"
    $frgs.DateBiased = $false
    $frgs.IncludeHiddenEntities = $false
    $frgs.IncludeLibraryContents = $false
    $ids = @()
    $ids += $fileIteration.EntityIterationId
    #$dsDiag.Inspect()       
$fal = $vaultConnection.FileManager.GetFileAssociationLites([int64[]]$ids, $frgs)
$fal | Out-GridView
$allAssociatedFilesIds = @()
$IDWIds = @()
$ValidParents = @{}
foreach ($dependentFile in $fal){
    $allAssociatedFilesIds += $dependentFile.CldFileId
}
$UniqueFilesIds = $allAssociatedFilesIds | Select-Object -Unique
Foreach ($file in $fal){
    if ($file.CldFileId -in $UniqueFilesIds){
        $ValidParents[$file.CldFileId] = $file.ParFileId
    }
}
$IDWIds = $ValidParents.Values