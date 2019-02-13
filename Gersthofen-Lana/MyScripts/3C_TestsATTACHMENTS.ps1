
function Add-DrawingJobs($ListAttachIds){
	foreach($Extension in $ListAttachIds.Keys){
		foreach($Id in $ListAttachIds[$Extension]){
			if($Extension -eq 'pdf'){
				$3CCreatePDF = Add-VaultJob -Name "Sample.CreatePDF" -Description "Export drawing to PDF" -Parameters @{EntityClassId = "FILE"; EntityId = $Id} -Priority 10 
			} elseif($Extension -eq 'dxf') {
				$3CCreateDXF = Add-VaultJob -Name "Sample.CreateDWG" -Description "Export drawing to DXF" -Parameters @{EntityClassId = "FILE"; EntityId = $Id} -Priority 10 
			} else {
				$3CCreateDWG = Add-VaultJob -Name "Sample.CreateDXF" -Description "Export drawing to DWG" -Parameters @{EntityClassId = "FILE"; EntityId = $Id} -Priority 10 
			}
		}
	}
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

function Select-NewAttachmentsIds($files){
	$listAttachIds = @{pdf = @(); dxf = @(); dwg=@()}
	foreach($file in $files){	
		$drawCreateDate = $file._DateVersionCreated
		$attachments = Get-VaultFileAssociations -File $file._FullPath -Attachments
		foreach($attach in $attachments){
			if($attach._Extension -in @('dwg','pdf','dxf')){
				if($attach._DateVersionCreated -ge $drawCreateDate){
					$listAttachIds[$attach._Extension] += $attach.Id
				}
			}
		}
	}
	return $listAttachIds
}


Import-Module powerVault
Import-Module powerJobs
Open-VaultConnection -Server "localhost" -Vault "VaultJFD" -user "Administrator"
$filename = "ASSY-Assy1-001.iam"
$vAssembly = Get-VaultFile -Properties @{"Name" = $filename}
$file = $vault.DocumentService.GetLatestFileByMasterId($vAssembly.MasterId)
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/TESTS/3C-HOLDING")
$fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)

$vaultFileIds = Get-DrawingFileIds -fileIteration $fileIteration | Select -Unique
$allVaultFiles = $vaultFileIds  | foreach { Get-VaultFile -FileId $_ } | where { $_._Extension -in @("idw", "dwg")}
[array]$vaultFiles = $allVaultFiles | where {$_._EntityPath -ne $folder.FullName -and $_.Id -notin $vaultFilesIdsWithLinks}
$AttachIdsByExtension = Select-NewAttachmentsIds -files $vaultFiles
Add-DrawingJobs -ListAttachIds $listAttachIds

$file = $vaultFiles[1]
$listAttachIds = @{pdf = @(); dxf = @(); dwg=@()}
$drawCreateDate = $file._DateVersionCreated
$attachments = Get-VaultFileAssociations -File $file._FullPath -Attachments
foreach($attach in $attachments){
	if($attach._Extension -in @('dwg','pdf','dxf')){
		if($attach._DateVersionCreated -ge $drawCreateDate){
			$listAttachIds[$attach._Extension] += $attach.Id
		}
	}
}

