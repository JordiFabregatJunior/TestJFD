function Add-PDF{
    $filename = 'PART-PART-IndepPart-000.idw'
    $file = Get-VaultFile -Properties @{"Name" = $filename}

    $hidePDF = $false
    $workingDirectory = "C:\Temp\$($file._Name)"
    $filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file._FullPath)
    $localPDFfileLocation = "C:\Users\JordiFabregatJunior\Documents\WORK\PROJECTS\3C-Holding\PART-PART-IndepPart-000.pdf"
    $vaultPDFfileLocation = $file._EntityPath +"/"+ (Split-Path -Leaf $localPDFfileLocation)
    $PDFfile = Add-VaultFile -From $localPDFfileLocation -To $vaultPDFfileLocation -FileClassification DesignVisualization -Hidden $hidePDF
    $file = Update-VaultFile -File $file._FullPath -AddAttachments @($PDFfile._FullPath)
    Update-VaultFile -File $file._FullPath -AddAttachments @($PDFfile._FullPath)
}


function delete-drawingsLinks(){
    $folder = $vault.DocumentService.GetFolderByPath("$/Designs/TESTS/3C-HOLDING")
    $linksOnFolder = $vault.DocumentService.GetLinksByParentIds($Folder.Id, "FILE")
    $vault.DocumentService.DeleteLinks($linksOnFolder.Id)
}
delete-drawingsLinks
Add-Pdf

###### REAL_CODE
$global:NetworkPath = 'C:\Users\JordiFabregatJunior\Documents\WORK\PROJECTS\3C-Holding\MockedNetwork'
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
function Add-DrawingJobs($IDlistDrawsToBeUpdated, $CopyPath){
	foreach($Extension in $IDlistDrawsToBeUpdated.Keys){
		foreach($Id in $IDlistDrawsToBeUpdated[$Extension]){
			if($Extension -eq 'pdf'){
				$3CCreatePDF = Add-VaultJob -Name "Sample.CreatePDF" -Description "Export drawing to PDF + TestCPath: $($CopyPath)" -Parameters @{EntityClassId = "FILE"; EntityId = $Id; CopyPath = $CopyPath} -Priority 10 
			} elseif($Extension -eq 'dwg') {
				$3CCreateDXF = Add-VaultJob -Name "Sample.CreateDWG" -Description "Export drawing to DXF + TestCPath: $($CopyPath)" -Parameters @{EntityClassId = "FILE"; EntityId = $Id; CopyPath = $CopyPath} -Priority 10 
			} else {
				$3CCreateDWG = Add-VaultJob -Name "Sample.CreateDXF" -Description "Export drawing to DWG + TestCPath: $($CopyPath)" -Parameters @{EntityClassId = "FILE"; EntityId = $Id; CopyPath = $CopyPath} -Priority 10 
			}
		}
	}
}

function New-LocalFiles {
    param (
        $Files,
		$CopyPath,
		$Custom = $false
    )
	Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
	$attachments = Get-VaultFileAssociations -File $file._FullPath -Attachments
	foreach($attach in $attachments){
		if($Custom){
			$destinationFile = Join-Path $CopyPath.Substring(2) $attach.Name
			$downloadedFile = Save-VaultFile -File $attach._FullPath -DownloadDirectory $destinationFile
		} else {
			$NetPathSctructure = Join-Path $global:NetworkPath $CopyPath.Substring(2)
			$destinationFile = Join-Path $NetPathSctructure $attach.Name
			if(-not (Test-Path $NetPathSctructure))
			{
				New-Item -Path $NetPathSctructure -ItemType Directory -Force | Out-Null
			}
			$downloadedFile= Save-VaultFile -File $attach._FullPath -DownloadDirectory $destinationFile
		}
    }
}

function Invoke-ButtonStartExport($Window, $Folder, $IDlistDrawsToBeUpdated, $CopyPath, $Custom) {
	if($Window.FindName("BtnTriggerJobs").content -eq 'Export'){
		$selectedIDWFiles = @(($Window.FindName("FileView").ItemsSource) | where { $_.TriggerJob })
		New-LocalFiles -Files $selectedIDWFiles -CopyPath $global:CopyPath -Custom $Custom
		foreach ($IDWFile in $SelectedIDWFiles){
			$vault.DocumentService.AddLink($Folder.Id,"FILE",$IDWFile.Id,"")
		}
		[System.Windows.Forms.MessageBox]::Show("$($selectedIDWFiles.Count) files have been successfully exported!`n", "IDW / DWG Export - Success", "Ok", "Information") | Out-Null
	} else {
		Add-DrawingJobs -IDlistDrawsToBeUpdated $global:IDlistDrawsToBeUpdated
	}
	$Window.Close()
}

Function Select-FolderDialog {
    param(
        [string]$Description="Select Folder",
        [string]$RootFolder="Desktop"
    )

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null     
    $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
    $objForm.Rootfolder = $RootFolder
    $objForm.Description = $Description
    $Show = $objForm.ShowDialog()
    If ($Show -eq "OK") {
        Return $objForm.SelectedPath
    } else {
        Write-Error "Operation cancelled by user."
    }
}

function Set-ButtonEvents($Window, $Folder, $IDlistDrawsToBeUpdated) {
	$global:window = $Window
	$global:Folder = $Folder
    $global:IDlistDrawsToBeUpdated = $IDlistDrawsToBeUpdated
	$Window.FindName("BtnTriggerJobs").add_Click({
		if([string]::IsNullOrEmpty($global:SelectedPath)){
			$global:SelectedPath = $Window.FindName("TxtAllAttachStatus").Text
			$global:Custom = $false
		} else {
			$global:Custom = $true
		}
		Invoke-ButtonStartExport -Window $global:window -Folder $global:Folder -IDlistDrawsToBeUpdated $global:IDlistDrawsToBeUpdated -CopyPath $global:SelectedPath -Custom $global:Custom 
	})
	$global:Window.FindName("BtnCancel").add_Click({
		$global:Window.Close()
	})
	$global:Window.FindName("BtnModifyCopyPath").add_Click({
		$global:SelectedPath = Select-FolderDialog 
		$Window.FindName("TxtCopyPath").Text = $global:SelectedPath
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

function Select-NewAttachments($Files, $Window, $CopyPath){
    $AttachUpdateComment = 'Update Needed'
	$IDlistDrawsToBeUpdated = @{pdf = @(); dxf = @(); dwg=@()}
	$updateNeeded = $false
	foreach($file in $Files){	
		$drawCreateDate = $file._DateVersionCreated
		$attachments = Get-VaultFileAssociations -File $file._FullPath -Attachments
		foreach($attach in $attachments){
			if($attach._Extension -in @('dwg','pdf','dxf')){
				if($attach._DateVersionCreated -lt $drawCreateDate){
					$IDlistDrawsToBeUpdated[$attach._Extension] += $file.Id
					Add-Member -InputObject $file -Name "NeedsAttachUpdate" -Value $true -MemberType NoteProperty
					Add-Member -InputObject $file -Name "AttachUpdateComment" -Value $AttachUpdateComment -MemberType NoteProperty
					$Window.FindName("BtnTriggerJobs").Content = 'Update Attachments'
					$Window.FindName("LblAllAttachStatus").Content = 'Attachment Copy Path'
					$Window.FindName("TxtAllAttachStatus").Text = $CopyPath
					#$Window.FindName("BtnTriggerJobs").IsEnabled = $False
					$updateNeeded = $true
				}
			}
		}
	}
	if(-not($updateNeeded)){
		$Window.FindName("BtnModifyCopyPath").IsEnabled = 'True'
		$Window.FindName("BtnModifyCopyPath").Visibility = 'Visible'
	}
	return $IDlistDrawsToBeUpdated
}

try {	
	Import-Module powerVault
    ###Debug
    Open-VaultConnection -Server "localhost" -Vault "VaultJFD" -user "Administrator"
    <#$filename = "ASSY-Assy1-001.iam"
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
	$CopyPath = (Split-path -Parent $vAssembly._EntityPath).Replace('\','/')
	$IDlistDrawsToBeUpdated = Select-NewAttachments -files $vaultFiles -Window $plotSelectionWindow -CopyPath $CopyPath
	$CountCheckouts = 0
	foreach($vaultFile in $vaultFiles){
		if($vaultFile.IsCheckedOut -eq $false){
			Add-Member -InputObject $vaultFile -Name "TriggerJob" -Value $true -MemberType NoteProperty 
		} else {
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
	Set-ButtonEvents -Window $plotSelectionWindow -Folder $folder -IDlistDrawsToBeUpdated $IDlistDrawsToBeUpdated
	$plotSelectionWindow.ShowDialog() | Out-Null

} catch {
	[System.Windows.Forms.MessageBox]::Show("Error message: '$($_.Exception.Message)'`n`n`nSTACKTRACE:`n$($_.InvocationInfo.PositionMessage)`n`n$($_.ScriptStacktrace)", "IDW / DWG Export - Error", "Ok", "Error") | Out-Null
}