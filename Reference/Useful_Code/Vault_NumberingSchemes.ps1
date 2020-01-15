# Gets next avaialable number for specific numbering scheme
Import-Module PowerVault
Open-VaultConnection -Server "w10-2019-demo" -Vault "Vault" -user "Administrator"
	
$numSchms = $vault.DocumentService.GetNumberingSchemesByType("Activated")
$numSchm = $numSchms | Where-Object { $_.Name -eq "Navision" }
$vault.DocumentService.GenerateFileNumber($numSchm.SchmID,@(""))