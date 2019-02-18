function Get-LinksInFolder ($Folder) {
	$linksOnFolder = $vault.DocumentService.GetLinksByParentIds($Folder.Id, "FILE")
	[array]$vaultFilesIdsWithLinks= @()
	foreach ($link in $linksOnFolder){
		if ($link.ToEntId -in $vaultFileIds){
			$vaultFilesIdsWithLinks += $link.ToEntId
		}
	}
	Return $vaultFilesIdsWithLinks
}

function Set-FilesInGui($Window, $Enable = $false) {
	$allFiles = $Window.FindName("FileView").ItemsSource
	$Window.FindName("FileView").ItemsSource = $null
	$allFiles | foreach { $_.TriggerJob = $Enable }
	$Window.FindName("FileView").ItemsSource = $allFiles
}

function Invoke-ButtonStartExport($Window, $Folder) {
	$selectedIDWFiles = @(($Window.FindName("FileView").ItemsSource) | where { $_.TriggerJob })
	foreach ($IDWFile in $SelectedIDWFiles){
		$vault.DocumentService.AddLink($Folder.Id,"FILE",$IDWFile.Id,"")
	}
	[System.Windows.Forms.MessageBox]::Show("$($selectedIDWFiles.Count) files have been successfully exported!`n", "IDW / DWG Export - Success", "Ok", "Information") | Out-Null
	$Window.Close()
}

function Set-ButtonEvents($Window, $Folder) {
	$global:window = $Window
	$global:Folder = $Folder
	$Window.FindName("BtnTriggerJobs").add_Click({
		Invoke-ButtonStartExport -Window $global:window -Folder $global:Folder
	})
	$global:Window.FindName("BtnCancel").add_Click({
		$global:Window.Close()
	})
	$Window.FindName("BtnSelectAll").add_PreviewMouseLeftButtonDown({
		Set-FilesInGui -Window $global:Window -Enable $true
	})
	$Window.FindName("BtnUnselectAll").add_PreviewMouseLeftButtonDown({
		Set-FilesInGui -Window $global:Window -Enable $false
	})
}

function Get-DrawingFileIds ($fileIteration){
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

	#IDWs/DWG are always parents => Extract unique idw/dwg IDs:
	$parentFileIds = @()
	foreach ($assocLite in $fal){
		$parentFileIds += $assocLite.ParFileId
	}
	$UniqueParentIds = $parentFileIds | Select-Object -Unique
	#Extract only idws/dwgs (exclude ipn and others) + return array with them:
	$IDWIDs = @()
	foreach($parentId in $UniqueParentIds){
		$candidateFile = $vault.DocumentService.GetFileById($parentId)
		$parentExtension = [System.IO.Path]::GetExtension("$($candidateFile.Name)")
		if($parentExtension -in @(".idw", ".dwg")){
			$IDWIDs += $parentId
		}
	}
	return $IDWIDs
}

try {	
	Import-Module powerVault
    ###Debug
    <#Open-VaultConnection -Server "" -Vault "" -user "Administrator"
    $filename = "ASSY-Assy1-001.iam"
    $vAssembly = Get-VaultFile -Properties @{"Name" = $filename}
    $file = $vault.DocumentService.GetLatestFileByMasterId($vAssembly.MasterId)
    $folder = $vault.DocumentService.GetFolderByPath("$/Designs/TESTS/3C-HOLDING")#>
	$fileMasterId= $vaultContext.CurrentSelectionSet | select -First 1 -ExpandProperty "Id"
	$fileSelectedFolderId = $vaultContext.NavSelectionSet | select -First 1 -ExpandProperty "Id"
	$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
	$vAssembly = Get-VaultFile -FileId $file.Id
	if (-not ($vAssembly._Extension -eq 'iam')){
		[System.Windows.Forms.MessageBox]::Show("The file $($vAssembly.Name) is not an assembly.", "IDW / DWG Export - Error", "Ok", "Information") | Out-Null
		Break
	}
	$folder = $vault.DocumentService.GetFolderById($fileSelectedFolderId)
	$fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)
	[xml]$xamlContent = Get-Content "C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\Vault.Custom\addinVault\Menus\IDWFileSelectionDialog.xaml"
	$plotSelectionWindow = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader -ArgumentList @($xamlContent)))

	$vaultFileIds = Get-DrawingFileIds -fileIteration $fileIteration | Select -Unique
	$allVaultFiles = $vaultFileIds  | foreach { Get-VaultFile -FileId $_ } | where { $_._Extension -in @("idw", "dwg")}
    $vaultFilesIdsWithLinks = Get-LinksInFolder -Folder $folder
	[array]$vaultFiles = $allVaultFiles | where {$_._EntityPath -ne $folder.FullName -and $_.Id -notin $vaultFilesIdsWithLinks}
	$CountCheckouts = 0
	foreach($vaultFile in $vaultFiles){
		if($vaultFile.IsCheckedOut -eq $false){
			Add-Member -InputObject $vaultFile -Name "IsCheckedOut" -Value $true -MemberType NoteProperty 
			Add-Member -InputObject $vaultFile -Name "TriggerJob" -Value $true -MemberType NoteProperty 
		} else {
			Add-Member -InputObject $vaultFile -Name "IsCheckedOut" -Value $false -MemberType NoteProperty
			Add-Member -InputObject $vaultFile -Name "TriggerJob" -Value $false -MemberType NoteProperty
			$CountCheckouts += 1
		}
	}
	$plotSelectionWindow.FindName("FileView").ItemsSource = @($vaultFiles)
	$plotSelectionWindow.FindName("TxtSelectedAssembly").Text = $vAssembly.Name
	$plotSelectionWindow.FindName("TxtSelectedAssemblyPath").Text = $vAssembly._FullPath
	$plotSelectionWindow.FindName("TxtValidDrawingFiles").Content = @($vaultFiles).Count
	$plotSelectionWindow.FindName("TxtDrawingsAlreadyInFolder").Content = @($allVaultFiles).Count - @($vaultFiles).Count
	$plotSelectionWindow.FindName("TxtCheckOutDrawings").Content = $CountCheckouts
	Set-ButtonEvents -Window $plotSelectionWindow -Folder $folder
	$plotSelectionWindow.ShowDialog() | Out-Null
} catch {
	[System.Windows.Forms.MessageBox]::Show("Error message: '$($_.Exception.Message)'`n`n`nSTACKTRACE:`n$($_.InvocationInfo.PositionMessage)`n`n$($_.ScriptStacktrace)", "IDW / DWG Export - Error", "Ok", "Error") | Out-Null
}