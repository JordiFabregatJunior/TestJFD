$masterId = 2033
function Rename-VaultFile($masterId,$newName,$comment)
{
	$number = [System.io.Path]::GetFileNameWithoutExtension($newName)
    #$masterId = $file.MasterId
    $file = $vault.DocumentService.GetLatestFileByMasterId($masterId)
	$oldFileName = $file.Name
	$fileAssocs = $vault.DocumentService.GetFileAssociationsByIds(@($file.Id), "None", $false, "All", $false, $false, $true)
    Write-Host "$($fileAssocs)"
	$fileAssocs = $fileAssocs[0]
    Write-Host "$($fileAssocs)"
	$fileAssocParams = @()
	if($fileAssocs.FileAssocs -ne $null)
	{
		foreach($fileAssoc in $fileAssocs.FileAssocs)
		{
			$fileAssocParam = New-Object Autodesk.connectivity.Webservices.FileAssocParam
			$fileAssocParam.CldFileId = $fileAssoc.CldFile.Id
			$fileAssocParam.ExpectedVaultPath = $fileAssoc.ExpectedVaultPath
			$fileAssocParam.RefId = $fileAssoc.RefId
			$fileAssocParam.Source = $fileAssoc.Source
			$fileAssocParam.Typ = $fileAssoc.Typ
			$fileAssocParams += $fileAssocParam
		}
	}
    Write-Host "fileAssocParams created"
	$fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)
	Write-Host "fileIteration created"
    Show-Inspector
    $settings = New-Object Autodesk.DataManagement.Client.Framework.Vault.Settings.AcquireFilesSettings($vaultConnection)
	$settings.AddFileToAcquire($fileIteration,"Download, Checkout")
    Show-Inspector
	$acquiredFiles = $vaultConnection.FileManager.AcquireFiles($settings)
	$fi = $acquiredFiles.FileResults[0].File
	$bom = $vault.DocumentService.GetBOMByFileId($fi.EntityIterationId)
    Write-Host "bom created"
	foreach($compArray in $bom.CompArray){
		if($compArray.Id -eq 0){
			$compArray.Name = $newName #rename the bom header file name
		}
		if($compArray.XRefId -gt 0){
			$origFile = $vault.DocumentService.GetFileById($compArray.XRefId)
			$copyName = "$prefix$($origFile.Name)"
			if($Global:FileNameId.Keys -contains $copyName){
				$compArray.XRefId = $Global:FileNameId[$copyName]
			}
		}
	} 
	
	foreach
	($propArray in $bom.PropArray){
		if($propArray.Name -eq "EquivalenceValue"){
			$evProp = $propArray
		}
	} 
		foreach($compAttrArray in $bom.CompAttrArray){
		if($compAttrArray.Id -eq $evProp.id){
			$compAttrArray.Val = $number #rename the part number association
		}
	}

	foreach($propArray in $bom.PropArray){
		if($propArray.Name -eq "Part Number"){
			$evProp = $propArray
		}
	} 
		foreach($compAttrArray in $bom.CompAttrArray){
		if($compAttrArray.Id -eq $evProp.id){
			$compAttrArray.Val = $number #rename the part number association
		}
	}
	
	$checkedInFile = $vaultConnection.FileManager.CheckinFile($fileIteration,$comment,$false,$fileAssocParams,$bom,$false, $newName,$fileIteration.FileClassification,$file.Hidden,$null)
	Write-Host "file checked in and job successfully done"
}
Rename-VaultFile -masterId $masterId -newName "TestNewName3.xlsx" -comment "Success!!"
