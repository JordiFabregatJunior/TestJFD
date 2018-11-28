
function AddXmlElement($xml, $name, $value)
{
    $elem = $xml.CreateElement($name)
    $elem.InnerText = $value
    $xml.DocumentElement.AppendChild($elem)
}

function GetReplaceItemNumber($file)
{
    $replaceItemNumber = ""
    try {
        $currentRev = $file.Revision
        $currentVersionNumber = $file._VersionNumber

        # iterate thru previous file versions until we find another a file with previous revision
        $versionNumber = $file._VersionNumber
        do {
            --$versionNumber
            $vaultFile = $vault.DocumentService.GetFileByVersion($file.MasterId, $versionNumber)
        } while ($versionNumber -gt 1 -and $vaultFile.FileRev.Label -eq $currentRev)

        if ($vaultFile) {
            $previousFile = Get-VaultFile -FileId $vaultFile.Id
            $replaceItemNumber = $previousFile.'Num ERP'
        }
    }
    Catch {
        Add-Log "Error in GetReplaceItemNumber()"
    }
    return $replaceItemNumber
}

function ExportToXml($file,$pdfFileName,$destination)
{
    [xml]$xml = "<Data/>"

    (AddXmlElement -xml $xml -name "destination" -value "Nav_Item") | Out-Null
    (AddXmlElement -xml $xml -name "pdf_file_name" -value $pdfFileName) | Out-Null
    (AddXmlElement -xml $xml -name "item_number" -value $file.'Num ERP') | Out-Null
    $replaceItemNumber = GetReplaceItemNumber -file $file
    (AddXmlElement -xml $xml -name "replace_item_number" -value $replaceItemNumber) | Out-Null

    $xml.Save($destination)
}
function Join-VaultPath {
param($Path0, $Path1)
	if(-not $Path1) { return $Path0 }
	if(-not $Path0) { return $Path1 }
	
	$is0Slash = $Path0.EndsWith("/")
	$is1Slash = $Path1.StartsWith("/")
	if($is0Slash -and $is1Slash) {
		$Path1 = $Path1.Substring(1)
	}
	if(-not ($is0Slash -or $is1Slash)) {
		$Path0 += "/"
	}
	return ($Path0 + $Path1)
}
function Copy-ExportedFile {
param(
[string]$SourceFullPath,
[System.IO.DirectoryInfo]$CopyDirectory
)
	if( (Test-Path $CopyDirectory) -eq $false ) {
		$null = New-Item -ItemType Directory -Path ($CopyDirectory)
		if( (Test-Path $CopyDirectory) -eq $false ) {
			throw "Could not create directory $($TargetDirectory.FullName)"
		}
	}
	
	$CopyFullPath = Join-Path $CopyDirectory ( [System.IO.Path]::GetFileName($SourceFullPath) )
	$null = Copy-Item $SourceFullPath $CopyFullPath -Force
	if( (Test-Path $CopyFullPath) -eq $false ) {
		throw "Could not copy $($SourceFullPath.FullName) to $($TargetFullPath)"
	}
}
function GetApplication($File) {
	if($File._Provider -eq "AutoCAD") {
		return $powerJobs.Applications.'DWG TrueView'
	}
	if($File._Provider -eq "Inventor" -or $File._Provider -eq "Inventor DWG") {
		return $powerJobs.Applications.Inventor
	}
}

function Get-PdfFileName($File, [switch]$Profile = $false) {	
	if($Profile) {
		$categoryShortcut = (Get-ProfilesStaticMapping -Category $file._CategoryName)["CAT"]
		return "$($categoryShortcut)_$($File.'N° de pièce')$($File._Revision).pdf"
	}
	$fileName = [system.io.path]::GetFileNameWithoutExtension($file.Name) 
	return $fileName + $file._Revision + ".pdf"
}

function Export-AdobePdf($OpenResult, [switch]$Profile = $false) {
    
    Add-Log "Starting export"
	$AdobePdfPrintDirectory = "C:\TEMP\AdobePdfPrints"
	$pdfFilename = Get-PdfFileName -File $file -Profile:$profile
	$localPdfFullPath = Join-Path $AdobePdfPrintDirectory $pdfFilename

	if(Test-Path $AdobePdfPrintDirectory) {
		Remove-Item -Path $AdobePdfPrintDirectory -Force -Recurse
    }
	$null = New-Item -Path $AdobePdfPrintDirectory -ItemType directory
	$Application = $openResult.Application.Instance
	$Document = $openResult.Document.Instance
	
	$printManager = $Document.PrintManager
    $printManager.Printer = "Adobe PDF"
    Add-Log "Using printer '$($printManager.Printer)' for export"
	$printManager.ScaleMode = [Inventor.PrintScaleModeEnum]::kPrintBestFitScale
	$printManager.PrintRange = [Inventor.PrintRangeEnum]::kPrintAllSheets
	$printManager.AllColorsAsBlack = $false
	$printManager.Orientation = [Inventor.PrintOrientationEnum]::kDefaultOrientation
	$printManager.SubmitPrint()
    
    Add-Log "Print submitted waiting for result.."
	Start-Sleep -Seconds 10
	$localPdf = Get-ChildItem -Path $AdobePdfPrintDirectory
	Rename-Item $localPdf.FullName $localPdfFullPath
	Get-Item $localPdfFullPath
}

function Get-VaultWhereUsedFiles($File) {
    $rootFile = Get-VaultFile -File $File
    $assocs = $vault.DocumentService.GetLatestFileAssociationsByMasterIds(@($rootFile.MasterId), "All", $false, "None", $false, $false, $false, $false)
    $assocs | select -First 1 -ExpandProperty "FileAssocs" | foreach {
        Get-VaultFile -FileId $_.ParFile.Id
    }
}