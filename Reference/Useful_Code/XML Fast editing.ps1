<#$tempPath = 'C:\Temp\TestPDFMetadata.txt'
"sOMETHING`nSoemthign2" | Out-File -FilePath $tempPath
explorer.exe $tempPath
#>


function Get-OneLineFormattedXMLContent ($XMLSourcePath, $TextExportPath = 'C:\Temp\xmlOuter.txt') {
    [xml]$XmlDocument = Get-Content -Path $XMLSourcePath
    return $XmlDocument.OuterXml | Out-File -FilePath $TextExportPath
}


$XMLSourcePath = 'C:\Users\JordiFabregatJunior\Documents\WORK\PROJECTS\CONTI-MACHINERY\CONTI-MACHINERY\Documents\Traffic Analysis\Quick_Formatting_tests.xml'
$TextExportPath = 'C:\Temp\xmlOuter.txt'
Get-OneLineFormattedXMLContent -XMLSourcePath $XMLSourcePath -TextExportPath $TextExportPath
explorer.exe $TextExportPath