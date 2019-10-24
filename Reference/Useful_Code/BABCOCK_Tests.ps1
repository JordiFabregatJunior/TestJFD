Import-Module powerGate
Import-Module powerVault -Global
Import-Module PowerVault
Open-VaultConnection -Server "localhost" -Vault "VaultJFD" -user "Administrator"

Get-ChildItem -path ($env:ProgramData+'\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules') -Filter *.psm1 | foreach { 
    Remove-Module -Name $_.Name -Global -Force
}
Get-ChildItem -path ($env:ProgramData+'\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules') -Filter *.psm1 | foreach { 
    Import-Module -Name $_.FullName -Global -Force
}
connect-erp -Service "http://desktop-qj7qt7h:8080/powerGateServer/IFS"
Import-Module 'C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules\Vault.Communication.psm1'
$item = Get-VaultItem -Number '100002'

Connect-ToErpServer
$erpMaterial = Get-ERPObject -EntitySet $global:itemEntitySet -Key (Get-ErpKey -VaultEntity $item -Type Item)

$erpMaterial = New-Object PSObject @{
    PartNumber = 10005
    Description = "TestDescription"
    UnitCode = "M"
}
$updatedItem = Update-VaultEntity -VaultEntity $item -ErpMaterial $erpMaterial