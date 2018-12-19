
function ExportFileProperties_ToExternalfile{
    param (
        [Parameter(Mandatory=$true)]
        [string]$fileName,
        [string]$fileType = "CSV",
        $destinationPath = "C:\temp\"
    )
    PowerVault\Open-VaultConnection -Vault "Demo-JF" -Server "2019-SV-12-E-jfd" -user "Jordi"
    $file = Get-VaultFile -Properties @{Name=$filename}
    $entityClassId = $file.'Entity Type ID'
    $propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($EntityClassId)
    $propertyNames = $propDefs | Where { $_.IsSys -eq $false } | Select -ExpandProperty DispName
    [hashtable]$properties = @{}
    forEach($propertyName in $propertyNames){
        [hashtable]$properties += @{$propertyName = $file.$propertyName}
    }
    $xmlOutput = "<root>`n"
    $csvData = "Property;Value`n"
    forEach($key in $properties.keys){
        $xmlOutput += "<$key>$($properties.$key)</$key>".Replace(" ","") + "`n"
        $csvdata += "$($key);$($properties.$key)"+"`n"
    }
    if($fileType -contains "csv"){
        $csvPath = "$($destinationPath)"+"$($file.Name)"+"_PropertiesList.csv"
        Set-Content -Path $csvPath -Value $csvdata
    }
    elseif($fileType -contains "xml"){
        $xmlPath = "$($destinationPath)"+"$($file.Name)"+"_PropertiesList.xml"
        $xmlOutput += "</root>" 
        $xmlOutput | Out-File $xmlPath
    }
    else { write-host "Filetype demanded not supported. Please choose one among: 'csv', 'xml'"}
}