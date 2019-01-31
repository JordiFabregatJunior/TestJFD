Import-Module powerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
#$folder = $vault.DocumentService.GetFolderByPath("$/Designs/Inventor/Test-Related-IDW")






<###Recurse IDWs
$file = $vault.DocumentService.GetLatestFileByMasterId(2402)
$filename = "Main.iam"
$vAssembly = Get-VaultFile -FileId $file.Id
$folder = $vault.DocumentService.GetFolderByPath($vAssembly._EntityPath)
$fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)


$frgs = New-Object Autodesk.DataManagement.Client.Framework.Vault.Settings.FileRelationshipGatheringSettings
	$frgs.IncludeAttachments = $false
	$frgs.IncludeChildren = $true
	$frgs.IncludeRelatedDocumentation = $true
	$frgs.RecurseChildren = $true
	$frgs.IncludeParents = $true
	$frgs.RecurseParents = $false
	$frgs.DateBiased = $false
	$frgs.IncludeHiddenEntities = $false
	$frgs.IncludeLibraryContents = $false
	$ids = @()
	$ids += $fileIteration.EntityIterationId     
$fal = $vaultConnection.FileManager.GetFileAssociationLites([int64[]]$ids, $frgs)

$CSV = @()
foreach($assoc in $fal){
    $Parent = $vault.DocumentService.GetFileById($assoc.ParFileId)
    $Child = $vault.DocumentService.GetFileById($assoc.CldFileId)
    $CSV += [PSCustomObject]@{
        'ParentId' = $assoc.ParFileId; 
        'ParentName' = $Parent.Name; 
        'ChildId' = $assoc.CldFileId;
        'ChildName' = $Child.Name;
        'ExpectedVaultPath' = $assoc.ExpectedVaultPath;
        'RefId' = $assoc.RefId
    }
}
$logsPath = 'C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\3C_Holding\FileAssoc.csv'
$CSV | Export-Csv -Path $logsPath -Delimiter ';' -NoTypeInformation -ErrorAction SilentlyContinue
explorer.exe $logsPath

$allAssociatedFilesIds = @()
$IDWIds = @()
$ValidParents = @{}

###___New
$parentFileIds = @()
foreach ($parentFile in $fal){
	$parentFileIds += $parentFile.ParFileId
}
$UniqueParentIds = $parentFileIds | Select-Object -Unique
$candidateFile = $vault.DocumentService.GetFileById($UniqueParentIds[0])

$IDWIDs = @()
foreach($parentId in $UniqueParentIds){
    $candidateFile = $vault.DocumentService.GetFileById($parentId)
    $parentExtension = [System.IO.Path]::GetExtension("$($candidateFile.Name)")
    if($parentExtension -eq '.idw'){
        $IDWIDs += $parentId
    }
}
$IDWIDs

foreach($idwID in $IDWIDs){
    $filetobeincluded = $vault.DocumentService.GetFileById($idwID)
    Write-Host $filetobeincluded.Name
}

###___End


foreach ($dependentFile in $fal){
	$allAssociatedFilesIds += $dependentFile.CldFileId
}
$UniqueFilesIds = $allAssociatedFilesIds | Select-Object -Unique
foreach($fileId in $UniqueFilesIds){
    $filetobeincluded = $vault.DocumentService.GetFileById($fileId)
    Write-Host $filetobeincluded.Name
}
Foreach ($file in $fal){
	if ($file.CldFileId -in $UniqueFilesIds){
		$ValidParents[$file.CldFileId] = $file.ParFileId
	}
}
$IDWIds =  $ValidParents.Values
foreach($fileId in $IDWIds){
    $filetobeincluded = $vault.DocumentService.GetFileById($fileId)
    Write-Host $filetobeincluded.Name
}



$vaultFileIds = Get-DrawingFileIds -fileIteration $fileIteration | Select -Unique
###___End RECURSE IDWs#>