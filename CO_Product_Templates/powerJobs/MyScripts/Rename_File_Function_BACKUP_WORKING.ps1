function Rename-VaultFile($masterId,$NewFileName,$comment){
    $file = $vault.DocumentService.GetLatestFileByMasterId($masterId)
    $fileExtension = [System.IO.Path]::GetExtension($file.Name)
    $NewFileName = "$($NewFileName)" + "$($fileExtension)"

    #Variables for checking out
    $buffer = New-Object Autodesk.Connectivity.WebServices.ByteArray

    #Variables for undo checking out
    #$downloadTicket = $vault.DocumentService.GetDownloadTicketsByMasterIds($file.MasterId)
    $downloadTicket = New-Object Autodesk.Connectivity.WebServices.ByteArray

    #__Variables to check in
    $keepCheckedOut = $false
    $lastWrite = $file.ModDate
    $copyBom = $false #later defined the BOM
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
    #Creating a fileiteration object for the FileClassification and BOM
    $fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)
    $settings = New-Object Autodesk.DataManagement.Client.Framework.Vault.Settings.AcquireFilesSettings($vaultConnection)
	$settings.AddFileToAcquire($fileIteration,"Download")
	$acquiredFiles = $vaultConnection.FileManager.AcquireFiles($settings)
	$fi = $acquiredFiles.FileResults[0].File
	$bom = $vault.DocumentService.GetBOMByFileId($fi.EntityIterationId)
    Write-Host "bom created"
    
    #__Main
    $CheckedOutFile = $vault.DocumentService.CheckoutFile($file.Id, "Master", [System.Environment]::MachineName, $file.LocalPath, [string].empty, [ref] $buffer)
    Write-Host "Checked out the file"
    Show-Inspector
    if($CheckedOutFile){
        Write-Host "Preparing to check in while rename with $($NewFileName) name"
        $CheckedInFile = $vault.DocumentService.CheckinUploadedFile($file.MasterId,"Your comment",$keepCheckedOut,$lastWrite,$fileAssocParams,$bom,$false,$NewFileName,$fileIteration.FileClassification,$hidden,$null)
    }
    else{
        $UndoCheckedOutFile = $vault.DocumentService.UndoCheckoutFile($file.MasterId,[ref]$downloadTicket)
        Write-host "File $($file.Name) could not be checked out"
    }
}
Rename-VaultFile -masterId $file.MasterId -NewFileName "PARTTestName0" -comment "Success!!"