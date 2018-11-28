function Rename_File($file,$newFileName,$comment){
    #$file = $vault.DocumentService.GetLatestFileByMasterId($masterId)
    $fileExtension = [System.IO.Path]::GetExtension($file.Name)
    $newFileName = "$($newFileName)" + "$($fileExtension)"

    ##___Variable definition for checking in, out and undo
    $buffer = New-Object Autodesk.Connectivity.WebServices.ByteArray
    $downloadTicket = New-Object Autodesk.Connectivity.WebServices.ByteArray
    $keepCheckedOut = $false
    $lastWrite = $file.ModDate
    $copyBom = $false
    $fileAssocs = $vault.DocumentService.GetFileAssociationsByIds(@($file.Id), "None", $false, "All", $false, $false, $true)
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
    
    ##___Main
    $CheckedOutFile = $vault.DocumentService.CheckoutFile($file.Id, "Master", [System.Environment]::MachineName, $file.LocalPath, [string].empty, [ref] $buffer)
    try {
        if($CheckedOutFile){
            $CheckedInFile = $vault.DocumentService.CheckinUploadedFile($file.MasterId,"Your comment",$keepCheckedOut,$lastWrite,$fileAssocParams,$BOM,$false,$newFileName,$fileIteration.FileClassification,$hidden,$null)
        }
    }
    catch {
        $UndoCheckedOutFile = $vault.DocumentService.UndoCheckoutFile($file.MasterId,[ref]$downloadTicket)
        throw "File $($file.Name) could not be checked out"
    }
}

Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$filename = "NewPartTestName0.idw"				
$file = Get-VaultFile -Properties @{Name = $filename}

Rename_File -masterId $file.MasterId -newFileName "NewPartTestName" -comment "Succeed"
#Rename_File -masterId $file.MasterId -newFileName "NewPartTestNameTImport-Module PowerVault"

