function Add-NewFile ($File, $Folder){
    $vfile = Get-VaultFile -FileId $file.Id
    $workingDirectory = "C:\Temp\$($vfile._Name)"
    $localFileLocation = "$workingDirectory\$($vfile._Name)"
    $downloadedFiles = Save-VaultFile -File $vfile._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren: $true -IncludeParents: $false
    $file = $downloadedFiles | select -First 1
    Add-VaultFile -From $localFileLocation -To "$($Folder.FullName)\$($file._Name)"
    Clean-Up -folder $workingDirectory
}

function recursivelyCreateFolders($targetFolder, $sourceFolder)
{
    $dsDiag.Trace($sourceFolder.FullName)
    $sourceSubFolders = $vault.DocumentService.GetFoldersByParentId($sourceFolder.Id,$false)
    foreach ($folder in $sourceSubFolders) {
        $newTargetSubFolder = $vault.DocumentServiceExtensions.AddFolderWithCategory($folder.Name, $targetFolder.Id, $folder.IsLibrary, $folder.Cat.CatId)
        $sourceFiles = $vault.DocumentService.GetLatestFilesByFolderId($folder.Id,$false)
        foreach ($file in $sourceFiles){
            Add-NewFile -File $file -Folder $newTargetSubFolder
        }
        recursivelyCreateFolders -targetFolder $newTargetSubFolder -sourceFolder $folder
    }
}

$folderId=$vaultContext.CurrentSelectionSet[0].Id
$vaultContext.ForceRefresh = $true
$dialog = $dsCommands.GetCreateFolderDialog($folderId)

$result = $dialog.Execute()
$dsDiag.Trace($result)

if($result){

	#new folder can be found in $dialog.CurrentFolder
	$folder = $vault.DocumentService.GetFolderById($folderId)
	$path=$folder.FullName+"/"+$dialog.CurrentFolder.Name

	$selectionId = [Autodesk.Connectivity.Explorer.Extensibility.SelectionTypeId]::Folder
	$location = New-Object Autodesk.Connectivity.Explorer.Extensibility.LocationContext $selectionId, $path
	$vaultContext.GoToLocation = $location
	
	#create template folder tree
    $newFolder = $vault.DocumentService.GetFolderByPath($path)
    $template = $dialog.ViewModel.Prop["Template"].Value
    if($template -ne "")
    {
        $templateFolder = $vault.DocumentService.GetFolderByPath($template)
        recursivelyCreateFolders -sourceFolder $templateFolder -targetFolder $newFolder
        $templateFolderFiles = $vault.DocumentService.GetLatestFilesByFolderId($templateFolder.Id,$false)
        foreach ($file in $templateFolderFiles){
            Add-NewFile -File $file -Folder $newFolder
        }
    }
}