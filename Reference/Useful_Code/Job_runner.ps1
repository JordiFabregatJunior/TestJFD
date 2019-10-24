<#$measuringPerformance = @{}
Import-Module PowerVault
Open-VaultConnection -Server "localhost" -Vault "VaultJFD" -user "Administrator"
$filename = "ASSY-Assy1-001.iam"
$vfile = Get-VaultFile -Properties @{"Name" = $filename}
$file = $vault.DocumentService.GetFileById($vFile.id)
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/TESTS/SPX")
$job = Add-VaultJob -Name "" -Description "-" -Parameters @{EntityClassId = "FILE"; EntityId = $vfile.Id} -Priority 10
####________NoTouching!_________#>
$filename ='TestPDF.ipt'
$file = Get-VaultFile -Properties @{"Name" = $filename}
$file = Update-VaultFile -File $ModifiedFile._FullPath -AddAttachments @($PDFfile._FullPath)


#dEBUGGING TESTS
Import-Module 
Open-VaultConnection -Server "bdcbappr112" -Vault "COOL_ORANGE_POC" -user "COOL_ORANGE_POC"
$itemNumber = '10001'
$item = Get-VaultItem -Number $itemNumber

function LinkMaterial {
    #Debug
    $itemNumber = '10001'
    $item = Get-VaultItem -Number $itemNumber
    #Debug
	$erpMaterial = $dsWindow.FindName("MaterialListView").SelectedItem
	#$item = $global:selectedEntity 
    if ($erpMaterial) {
		$VaultEntityType = $item._EntityTypeID
		$vaultUDPstoBeUpdated = @{
			'Description (Item,CO)' = $ErpMaterial.Description
			'Quality Level ID' = $ErpMaterial.QualityLevelId	
		} 
		if($VaultEntityType -eq 'ITEM') {
			Show-Inspector ErpMaterial
			$updatedItem = Update-VaultItem -Number $item._Number -Properties $vaultUDPstoBeUpdated
			$updatedItem = Update-VaultItem -Number $item._Number -NewNumber $ErpMaterial.PartNumber
			if($updatedItem){
				Show-MessageBox -message "Item linked successfully (Old item Number:'$($item._Number)' <> New linked item Number:'$($updatedItem._Number)') "
			} else {
				Show-MessageBox -message "Error linking item :'$($item._Number)'!"
			}
		}
		[System.Windows.Forms.SendKeys]::SendWait("{F5}")
		return $updatedItem
    }
}

