# Debugging ==================================================================#
# Import-Module powerVault
# Import-Module powerJobs
# Open-VaultConnection -Server "vaulttest" -Vault "Designs" -User "HurniCO" -Password "1234"
# $file = Get-VaultFile -File "$/Designs/Temp/66.777.666.1.idw"
# End debugging ==============================================================#

#Region Settings
$workingDirectory = "C:\Temp\$($file._Name)"	#this is the temporary directory

$fileName = [system.io.path]::GetFileNameWithoutExtension($file.Name) 
$xmlFilename = $fileName + $file._Revision + ".xml"
$vaultPdfPath = $file._EntityPath

#$networkPdfPath = "\\fssrv02\dessins\Execution mécanique drwg\PDF\" #For Live environment
# $networkPdfPath = "\\vaultsrv16\Config_Autodesk\Partage Projet Vault\Test_Export_PDF\" #For TESTS
$networkPdfPath = "C:\co_to_ged\" #For TESTS
$networkPdfFullDirectoryPath = $networkPdfPath

$networkXmlPath = "C:\co_to_ged\" #For TESTS
$networkXmlFullDirectoryPath = $networkXmlPath
$xmlFileFullPath = Join-Path $networkXmlFullDirectoryPath $xmlFilename

$fastOpen = $false
#Endregion

Add-Log "Starting job 'Adobe Print PDF' for file '$($file._Name)' ..."

if ( @("idw", "dwg") -notcontains $file._Extension ) {
    Add-Log "Files with extension: '$($file._Extension)' are not supported : *.idw only"
    return
}

$downloadedFiles = Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren:$fastOpen -ExcludeLibraryContents:$fastOpen
$file = $downloadedFiles | select -First 1
$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen }

if ($openResult) {
	$exportedPdf = Export-AdobePdf -OpenResult $openResult
    Copy-ExportedFile -SourceFullPath $exportedPdf.FullName -CopyDirectory $networkPdfFullDirectoryPath
    ExportToXml -file $file -pdfFileName $exportedPdf.Name -destination $xmlFileFullPath
    $closeResult = Close-Document
}

Clean-Up -folder $workingDirectory
Clean-Up -folder $AdobePdfPrintDirectory

if (-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.ErrorMessage)")
}
if (-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.ErrorMessage))")
}
Add-Log "Completed job 'Adobe Print PDF'"