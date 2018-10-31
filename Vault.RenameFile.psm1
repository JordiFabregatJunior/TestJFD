Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$filename = "TestExcel1.xlsx"			
$NewFileName = "TestExcel2"
$PVaultFile = Get-VaultFile -Properties @{Name = $filename}
#$downloadTicket = New-Object Autodesk.Connectivity.WebServices.ByteArray
#$vault.DocumentService.UndoCheckoutFile($PVaultFile.MasterId,[ref]$downloadTicket)
#Rename-File -PVaultFile $PVaultFile -NewFileName $NewFileName
Rename-File-CheckTest -PVaultFile $PVaultFile -NewFileName $NewFileName

function GetFileAssocParams($VFile){
    $parentAssociationType, $childAssociationType = @('All','All')
    $parentRecurse, $childRecurse = $false, $false
    $includeRelatedDocuments = $false
    $includeHidden = $true

    $fileAssocs = $vault.DocumentService.GetFileAssociationsByIds($VFile.Id, $parentAssociationType, $parentRecurse, $childAssociationType, $childRecurse, $includeRelatedDocuments, $includeHidden)
    $fileAssocs = $fileAssocs[0]
    $fileAssocParams = @()
    if($fileAssocs.FileAssocs -ne $null){
	    foreach($fileAssoc in $fileAssocs.FileAssocs){
		    $fileAssocParam = New-Object Autodesk.connectivity.Webservices.FileAssocParam
		    $fileAssocParam.CldFileId = $fileAssoc.CldFile.Id
		    $fileAssocParam.ExpectedVaultPath = $fileAssoc.ExpectedVaultPath
		    $fileAssocParam.RefId = $fileAssoc.RefId
		    $fileAssocParam.Source = $fileAssoc.Source
		    $fileAssocParam.Typ = $fileAssoc.Typ
		    $fileAssocParams += $fileAssocParam
	    }
    }
    return ,$fileAssocParams
}

function Rename-File($PVaultFile,$NewFileName){
    $fileExtension = [System.IO.Path]::GetExtension($PVaultFile.Name)
    $newFileName = "$($NewFileName)" + "$($fileExtension)"
    $vFile = $vault.DocumentService.GetLatestFileByMasterId($PVaultFile.MasterId)

    if($vFile.CheckedOut){
        throw "The file $($vFile.Name) is already checked out, so it can be renamed"
    }

    $fileAssocParams = GetFileAssocParams($vFile)
    $BOM = $vault.DocumentService.GetBOMByFileId($PVaultFile.Id)
 
    $downloadTicket = New-Object Autodesk.Connectivity.WebServices.ByteArray
    $lastWrite = $vFile.ModDate
    $comment = [string].empty
    $buffer = New-Object Autodesk.Connectivity.WebServices.ByteArray

    $CheckedOutFile = $vault.DocumentService.CheckoutFile($vFile.Id, "Master", [System.Environment]::MachineName, $vFile.LocalPath, $comment, [ref] $buffer)
    try {
        if($CheckedOutFile){
            $CheckedInFile = $vault.DocumentService.CheckinUploadedFile($vFile.MasterId,"",$false,$lastWrite,$fileAssocParams,$BOM,$false,$newFileName,$vFile.FileClass,$hidden,$null)
        }
    }
    catch{
        $UndoCheckedOutFile = $vault.DocumentService.UndoCheckoutFile($vFile.MasterId,[ref]$downloadTicket)
        throw "The file $($vFile.Name) could not be checked out"
    }
}