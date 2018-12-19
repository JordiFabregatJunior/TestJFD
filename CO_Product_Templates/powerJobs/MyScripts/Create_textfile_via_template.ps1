PowerVault\Open-VaultConnection -Vault "Demo-JF" -Server "2019-SV-12-E-jfd" -user "Jordi"
$filename = "Draw_CAX.idw"
$file = Get-VaultFile -Properties @{Name=$filename}

$XMLfile = Get-Content "C:\temp\$($file.Name).xml"
#export xml as csv
$CSVFile = $XMLfile.Root | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Set-Content -Path "c:\temp\test.csv" -Encoding UTF8
   
$templatePath = "C:\temp\$($file.Name).xml"
$destinationPath = "C:\temp\template.html"
$destinationCSVPath = "c:\temp\test.csv"

$regex = [regex]"(?<=<)([^\/]*?)((?= \/>)|(?=>))"
$template = Get-Content -LiteralPath $templatePath
$templatePath.Transaction.ChildNodes | Export-Csv "c:\temp\test.csv" -NoTypeInformation -Delimiter:";"
$propertyMatches = $regex.Matches($template)
foreach($propertyMatch in $propertyMatches){
    $propertyName = $propertyMatch.Value
    $propertyValue = $file.$propertyName
    $template = ($template -replace $propertyMatch.Value, $propertyValue)
}
$template | Out-File $destinationPath -Append

