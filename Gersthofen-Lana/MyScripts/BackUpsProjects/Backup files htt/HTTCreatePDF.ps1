#=============================================================================#
# PowerShell script sample for coolOrange powerJobs                           #
# Creates a PDF file and add it to Autodesk Vault as Design Vizualization     #
#                                                                             #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

function GetAutoCADOnExport {

param(
[switch]$ExcludeModel,
[switch]$ExcludeLayouts
)

     if($ExcludeModel -and $ExcludeLayouts) {
          $onExport = {
               param($export)
               $sheets = $export.DsdFile.Sheets
               $sheets | % { $sheets.Remove($_) }
          }
     }
     elseif($ExcludeModel) {
          $onExport = {
               param($export)
               $sheets = $export.DsdFile.Sheets
               $sheetsToRemove = $sheets | Where { $_.Layout -eq "Model" }
               $sheetsToRemove | % { $sheets.Remove($_) }
          }
     }
     elseif($ExcludeLayouts) {
          $onExport = {
               param($export)
               $sheets = $export.DsdFile.Sheets
               $sheetsToRemove = $sheets | Where { $_.Layout -ne "Model" }
               $sheetsToRemove | % { $sheets.Remove($_) }
          }
     }

return $onExport
} 




$hidePDF = $false
$filename_temp=$file.'Zeichnungs-Nr.'
$filename_temp=$filename_temp.replace("/","_")
$filename_temp=$filename_temp.replace("\","_")
$workingDirectory = "C:\Temp\$($file._Name)"


$localPDFfileLocation = "$workingDirectory\$($filename_temp).pdf"
$vaultPDFfileLocation = $file._EntityPath + "/" + "Nebendokumente" + "/" + (Split-Path -Leaf $localPDFfileLocation)
$fastopen = $false
$fastOpen = $file._Extension -eq "idw" -and $file._ReleasedRevision

$Revision_file=$file.Revision
$kommentar="PDF zur Revision: " + $Revision_file
#Show-Inspector
Add-Log "Starting job 'Create PDF as attachment' for file '$($filename_temp)'  '$($kommentar)'..."
$Titel_file=$file._Title + "- Revision " + $file.Revision
#Show-Inspector

if( @("idw","dwg") -notcontains $file._Extension ) {
    Add-Log "Files with extension: '$($file._Extension)' are not supported"
    return
}

$downloadedFiles = Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren:$fastOpen -ExcludeLibraryContents:$fastOpen
$file = $downloadedFiles | select -First 1
$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen } 

if($openResult) {
    if($openResult.Application.Name -eq 'Inventor') {
        $configFile = "$($env:POWERJOBS_MODULESDIR)Export\PDF_2D.ini"
        $onExport = $null
        #Show-Inspector
        $exportResult = Export-Document -Format 'PDF' -To $localPDFfileLocation -Options $configFile
        
    } else {
        $ExcludeAcadLayouts = $true
        $ExcludeAcadModel = $false
        $configFile = "$($env:POWERJOBS_MODULESDIR)Export\PDF.dwg"
	#$onExport = GetAutoCADOnExport -ExcludeModel:$ExcludeAcadModel -ExcludeLayouts:$ExcludeAcadLayouts
	#Show-Inspector
        $exportResult = Export-Document -Format 'PDF' -To $localPDFfileLocation -Options $configFile #-onExport:$onExport
    }                  
    
    if($exportResult) {       
        $PDFfile = Add-VaultFile -From $localPDFfileLocation -To $vaultPDFfileLocation -FileClassification None -Hidden $hidePDF -comment $kommentar
        $file = Update-VaultFile -File $file._FullPath -AddAttachments @($PDFfile._FullPath) -Comment $kommentar
        $PDFfile=Update-VaultFile -File $PDFfile._FullPath -Properties @{"_Title"=$Titel_file} -Comment $kommentar -Status "Freigegeben"
    }
    $closeResult = Close-Document
}

Clean-Up -folder $workingDirectory

if(-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.ErrorMessage)")
}
if(-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localPDFfileLocation! Reason: $($exportResult.ErrorMessage)")
}
if(-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.ErrorMessage))")
}
Add-Log "Completed job 'Create PDF as attachment'"