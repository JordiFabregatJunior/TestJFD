### Document tests moking workflow:

Get-ChildItem -path ($env:ProgramData+'\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules') -Filter Vault.*.psm1 | foreach { 
    Remove-Module -Name $_.FullName -Global -Force
}	

Import-Module powerGate -Global
Import-Module powerVault -Global
Import-Module 'C:\ProgramData\coolOrange\powerEvents\Modules\SAP.Release.Helpers.psm1'
Import-Module "$($env:ProgramFiles)\coolorange\Modules\powerGate\powerGate_Connections.psm1"
Get-ChildItem -path ($env:ProgramData+'\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules') -Filter Vault.*.psm1 | foreach { Import-Module -Name $_.FullName -Global -Force}	
Connect-ToErpServer
Open-VaultConnection -Server "hscmas08" -Vault "CM-01" -user "coolOrangeAdmin " -Password "12345"

### DATA INITIALIZATION

$global:itemEntitySet = "Materials"
$global:itemEntityType = "MaterialEntity"
$global:itemErpKey = "Number"
$global:bomEntitySet = "Boms"
$global:bomEntityType = "BomEntity"
$global:bomRowEntityType = "BomRowEntity"
$global:bomErpKey = "ParentNumber"
$global:itemNumberPropName = "01 SAP-No."
$global:bomNumberPropName = "01 SAP-No."
$global:filePartNumberPropName = "01 SAP-No."
$global:documentEntitySet = "Documents"
$global:documentEntityType = "DocumentEntity"
$global:pgStandardKeyProps = @{
	"ITEMNumber" = '01 SAP-No.'
	"ITEMDescription" = '02 Short Desc. German'
	"ITEMUnitOfMeasure" = '15 Order Unit'
}

# Create drawing
# Release drawing and see pdf in Vault

# Manually create Drawing:
$item = Get-VaultItem -Number 'M-000200'
$addedDoc = Invoke-DocumentTransferProcedure -Item $item
if($addedDoc){
    $dockeys = @{ "DocumentNumber" = $addedDoc.DocumentNumber.toUpper(); "DocumentType" = $addedDoc.DocumentType } # SAP sets DocumentNumber always to UPPER CASE on creation. Get should always look with UPPER!
    $erpDocument = Get-ERPObject -EntitySet $global:documentEntitySet -Keys $docKeys -Expand "Materials" 
}

# Release Item in Vault => Within worflow update props:

$item = Get-VaultItem -Number 'M-000200'
$itemAssocs = Get-VaultItemAssociations -Number $item._Number
$PDFFile = $itemAssocs | where { $_._Extension -eq 'pdf' -and $_.'33 Category Name' -eq 'Design Representation'} | Select -First 1
$documentNumber = Get-DocumentNumber -VaultEntity $PDFfile
$documentType = Get-DocumentType -VaultEntity $PDFfile
$dockeys = @{ "DocumentNumber" = $documentNumber.toUpper(); "DocumentType" = $documentType } # SAP sets DocumentNumber always to UPPER CASE on creation. Get should always look with UPPER!
$erpDocument = Get-ERPObject -EntitySet $global:documentEntitySet -Keys $docKeys -Expand "Materials"  