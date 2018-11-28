function Rename_File($File,$NewFileName){
    $fileExtension = [System.IO.Path]::GetExtension($File.Name)
    $NewFileName = "$($NewFileName)" + "$($fileExtension)"

    ##___Variable definition for checking in, out and undo
    $buffer = New-Object Autodesk.Connectivity.WebServices.ByteArray
    $downloadTicket = New-Object Autodesk.Connectivity.WebServices.ByteArray
    $keepCheckedOut = $false
    $lastWrite = $File.ModDate
    $copyBom = $false
    $fileAssocs = $vault.DocumentService.GetFileAssociationsByIds($File.Id, "All", $false, "All", $false, $false, $true)
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
    $fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$File)
    $settings = New-Object Autodesk.DataManagement.Client.Framework.Vault.Settings.AcquireFilesSettings($vaultConnection)
	$settings.AddFileToAcquire($fileIteration,"Download")
	$acquiredFiles = $vaultConnection.FileManager.AcquireFiles($settings)
	$BOMfile = $acquiredFiles.FileResults[0].File
	$BOM = $vault.DocumentService.GetBOMByFileId($BOMfile.EntityIterationId)
    
    ##___Main
    $CheckedOutFile = $vault.DocumentService.CheckoutFile($File.Id, "Master", [System.Environment]::MachineName, $File.LocalPath, [string].empty, [ref] $buffer)
    try {
        if($CheckedOutFile){
            $CheckedInFile = $vault.DocumentService.CheckinUploadedFile($File.MasterId,"",$keepCheckedOut,$lastWrite,$fileAssocParams,$BOM,$false,$NewFileName,$fileIteration.FileClassification,$hidden,$null)
        }
    }
    catch {
        $UndoCheckedOutFile = $vault.DocumentService.UndoCheckoutFile($File.MasterId,[ref]$downloadTicket)
        throw "The file could not be checked out"
    }
}