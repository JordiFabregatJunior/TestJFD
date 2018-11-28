PowerVault\Open-VaultConnection -Vault "Demo-JF" -Server "2019-SV-12-E-jfd" -user "Jordi"
$filename = "Draw_CAX.idw"
$file = Get-VaultFile -Properties @{Name=$filename}

# $file = PrepareEnvironmentForFile "Catch Assembly.idw"
   
$txtPath = "C:\Temp\$($file.Name).txt"
   
$entityClassId = $file.'Entity Type ID'
$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($EntityClassId)
$propertyNames = $propDefs | Where { $_.IsSys -eq $false } | Select -ExpandProperty DispName
[hashtable]$properties = @{}
forEach($propertyName in $propertyNames){
    [hashtable]$properties += @{$propertyName = $file.$propertyName}
}
$output = ""
forEach($key in $properties.keys){
    $output += "{$($key)};$($properties.$key);".Replace(" ","")
}
   
$output | Out-File $txtPath
#$hashtable2 = @{One='one'; Two='two';Three='three'}