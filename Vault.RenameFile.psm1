function Rename-File($vFile,$NewFileName){
    $fileExtension = [System.IO.Path]::GetExtension($File.Name)
	$newFileName = "$($NewFileName)" + "$($fileExtension)"
	$vaultfiles = $vault.DocumentService.GetFilesByMasterId($vFile.MasterId)
    $latestFileVersion = $vaultfiles.Length-1
    $file = $vaultfiles[$latestFileVersion]

    $fileAssocs = $vault.DocumentService.GetFileAssociationsByIds($file.Id, "All", $false, "All", $false, $false, $true)
	$fileAssocs = $fileAssocs[0]
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
    $fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)
    $settings = New-Object Autodesk.DataManagement.Client.Framework.Vault.Settings.AcquireFilesSettings($vaultConnection)
	$settings.AddFileToAcquire($fileIteration,"Download")
	$acquiredFiles = $vaultConnection.FileManager.AcquireFiles($settings)
	$BOMfile = $acquiredFiles.FileResults[0].File
	$BOM = $vault.DocumentService.GetBOMByFileId($BOMfile.EntityIterationId)
    
    $buffer = New-Object Autodesk.Connectivity.WebServices.ByteArray
    $downloadTicket = New-Object Autodesk.Connectivity.WebServices.ByteArray
    $lastWrite = $file.ModDate

    $CheckedOutFile = $vault.DocumentService.CheckoutFile($file.Id, "Master", [System.Environment]::MachineName, $file.LocalPath, [string].empty, [ref] $buffer)
    try {
        if($CheckedOutFile){
            $CheckedInFile = $vault.DocumentService.CheckinUploadedFile($file.MasterId,"",$false,$lastWrite,$fileAssocParams,$BOM,$false,$newFileName,$fileIteration.FileClassification,$hidden,$null)
        }
    }
    catch {
        $UndoCheckedOutFile = $vault.DocumentService.UndoCheckoutFile($file.MasterId,[ref]$downloadTicket)
        throw "The file could not be checked out"
    }
}