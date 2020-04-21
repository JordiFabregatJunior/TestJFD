function Get-OneLineFormattedXMLContent ($XMLSourcePath, $TextExportPath = 'C:\Temp\xmlOuter.txt') {
    [xml]$XmlDocument = Get-Content -Path $XMLSourcePath
    $XmlDocument.OuterXml | Out-File -FilePath $TextExportPath
    return $XmlDocument.OuterXml
}
$XMLSourcePath = '\\Mac\Home\Documents\WORK\PROJECTS\CONTI-MACHINERY\Documents\ProgressBar.xml'
#$XMLSourcePath = '\\Mac\Home\Documents\WORK\PROJECTS\CONTI-MACHINERY\Documents\Traffic Analysis\Materials - Not exposed Fields Tests - Added Test Fields.xml'
$TextExportPath = 'C:\Temp\xmlOuter.txt'
$xmlOneLined = Get-OneLineFormattedXMLContent -XMLSourcePath $XMLSourcePath -TextExportPath $TextExportPath
#explorer.exe $TextExportPath 
