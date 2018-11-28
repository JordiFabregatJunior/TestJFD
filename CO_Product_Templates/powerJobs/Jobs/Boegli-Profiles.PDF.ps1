# Debugging ==================================================================#
# Import-Module powerVault
# Import-Module powerJobs
# Open-VaultConnection -Server "vaulttest" -Vault "Designs" -User "HurniCO" -Password "1234"
# $file = Get-VaultFile -File "$/Designs/Temp/66.777.666.1.idw"
# End debugging ==============================================================#

#Region Settings
$exportPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\Boegli"
$workingDirectory = "C:\temp\$($file._Name.TrimStart(''))"	#this is the temporary directory
$fastOpen = $false
$fileNameWithoutExtension = [system.io.path]::GetFileNameWithoutExtension($file._Name)
#Endregion

Write-Host "Starting job 'Boegli-Profiles.PDF' for file '$($file._Name)' ..."

if( @("ipt","iam") -notcontains $file._Extension ) {
    Add-Log "File with extension: '$($file._Extension)' is not supported : *.ipt or *.iam only"
    return
}
$drawingForTriggeredFile = (Get-VaultWhereUsedFiles -File $file._FullPath) | where { $_._Name.StartsWith($fileNameWithoutExtension) -and $_._Name.EndsWith(".idw") } | select -First 1
if(-not $drawingForTriggeredFile) {
	throw "Failed to find Drawing (idw): It looked for '$($fileNameWithoutExtension).idw' in the 'Where Used' associations  for '$($file._FullPath)'"
}
Add-Log "Found IDW file: $($drawingForTriggeredFile._FullPath)"

$downloadedFiles = Save-VaultFile -File $drawingForTriggeredFile._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren:$fastOpen -ExcludeLibraryContents:$fastOpen
$drawingForTriggeredFile = $downloadedFiles | select -First 1
$openResult = Open-Document -LocalFile $drawingForTriggeredFile.LocalPath -Options @{ FastOpen = $fastOpen }
if ($openResult) {
	$exportedPdf = Export-AdobePdf -OpenResult $openResult -Profile
	Copy-Item -Path $exportedPdf.FullName -Destination "$exportPath\$($exportedPdf.Name)" -Force

	$createdXml = New-ProfileXml -Directory $exportPath -File $file
    $closeResult = Close-Document
}
Clean-Up -folder $workingDirectory
Clean-Up -folder (Split-Path $exportedPdf.FullName)

if (-not $openResult) {
    throw("Failed to open document $($drawingForTriggeredFile.LocalPath)! Reason: $($openResult.ErrorMessage)")
}
if (-not $closeResult) {
    throw("Failed to close document $($drawingForTriggeredFile.LocalPath)! Reason: $($closeResult.ErrorMessage))")
}

Add-Log "Completed job 'Boegli-Profiles.PDF' for file '$($file._Name)' ..."