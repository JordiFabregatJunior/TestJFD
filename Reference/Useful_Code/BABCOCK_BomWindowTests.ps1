
Import-Module powerGate -Global
Import-Module powerVault -Global

$serverModulePath = 'C:\Users\1ains7227\Desktop\CO Tests'
Get-ChildItem -path $serverModulePath -Filter *.psm1 | foreach { 
	Remove-Module -Name $_.Name -Global -Force
	Import-Module -Name $_.FullName -Global -Force
}

$gatewayURL = "http://bdcbappr112:8080/powerGateServer/IFS"
Connect-ERP -Service $gatewayURL
Open-VaultConnection -Server "bdcbappr112" -Vault "COOL_ORANGE_POC" -user "coolOrange"
$bomHeaderNumber = 'MPN006602'
$bomRowNumber = 'MPN006604'
$header = Get-VaultItem -Number $bomHeaderNumber
$row = Get-VaultItem -Number $bomRowNumber

### Bom creation as Test script (NOT REVISION KEY PROPERTIES)

$bom = New-ERPObject -EntityType "BomEntity" -Properties @{
    "ParentPartNumber" = $bomHeaderNumber
}

$bom.Children = @(
    (New-ERPObject -EntityType "BomRowEntity" -Properties @{
	    "ParentPartNumber" = $bomHeaderNumber
		"ChildPartNumber" = $bomRowNumber
		"DrawingPositionNumber" = "1"
		"Quantity" = "10"
    })
)
 
$addedbom = Add-ERPObject -EntitySet "Boms" -Properties $bom
$specificBomWithChildren = Get-ERPObject -EntitySet "Boms" -Keys @{ "ParentPartNumber" = $bomHeaderNumber} -Expand "Children"

### Bom creation WITH REVISION KEY PROPERTIES

$bom.Children = @(
    (New-ERPObject -EntityType "BomRowEntity" -Properties @{
	    "ParentPartNumber" = $bomHeaderNumber
		"ChildPartNumber" = $bomRowNumber
		"ChildPartRev" = "A"
		"ParentPartRev" = "A"
		"DrawingPositionNumber" = "1"
		"Quantity" = "10"
    })
)

$addedbom = Add-ERPObject -EntitySet "Boms" -Properties $bom
$specificBomWithChildren = Get-ERPObject -EntitySet "Boms" -Keys @{ "ParentPartNumber" = $bomHeaderNumber} -Expand "Children"