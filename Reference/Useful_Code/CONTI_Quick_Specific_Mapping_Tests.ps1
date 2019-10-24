function Get-ColourCodeValue ($VaultEntity){

	# Vault Farbkennzeichen ([17 Colourcode]) mit SAP Farbkennzeichen (MARA-EXTWG). Be-rücksichtigung der definierten Regel in der Mapping Definition.
	
	$colourcode = $VaultEntity.'17 Colourcode'
	$colourcode = ($colourcode -replace "# no colour", '') -replace "#", ''
	$colourcode = $colourcode -split ' ' | Select -First 1
	if(-not([string]::IsNullOrEmpty($colourcode))){
		return  "CM:$($colourcode.Trim())"
	}
}
$VaultEntity = New-Object PSObject -Property @{
    '17 Colourcode' = '# no colour'
}

Get-ColourCodeValue -VaultEntity $VaultEntity