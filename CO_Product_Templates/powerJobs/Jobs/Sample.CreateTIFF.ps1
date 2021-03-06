#=============================================================================#
# PowerShell script sample for coolOrange powerJobs                           #
# Creates a TIFF file and add it to Autodesk Vault as Design Vizualization    #
#                                                                             #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

$hideTIFF = $false
$workingDirectory = "C:\Temp\$($file._Name)"
$localTIFFfileLocation = "$workingDirectory\$($file._Name).tiff"
$vaultTIFFfileLocation = $file._EntityPath +"/"+ (split-path -Leaf $localTIFFfileLocation)
$fastOpen = $file._Extension -eq "idw" -or $file._Extension -eq "dwg" -and $file._ReleasedRevision

Write-Host "Starting job 'Create TIFF as attachment' for file '$($file._Name)' ..."

if( @("idw","dwg","iam","ipt","ipn") -notcontains $file._Extension ) {
    Write-Host "Files with extension: '$($file._Extension)' are not supported"
    return
}

$downloadedFiles = Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren:$fastOpen -ExcludeLibraryContents:$fastOpen
$file = $downloadedFiles | select -First 1
$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen }

if($openResult) {
    $exportResult = Export-Document -Format 'TIFF' -To $localTIFFfileLocation
    if($exportResult) {
        $TIFFfile = Add-VaultFile -From $localTIFFfileLocation -To $vaultTIFFfileLocation -FileClassification DesignVisualization -Hidden $hideTIFF
        $file = Update-VaultFile -File $file._FullPath -AddAttachments @($TIFFfile._FullPath)
    } 
    $closeResult = Close-Document
}
Clean-Up -folder $workingDirectory

if(-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.Error.Message)")
}
if(-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localTIFFfileLocation! Reason: $($exportResult.Error.Message)")
}
if(-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.Error.Message))")
}
Write-Host "Completed job 'Create TIFF as attachment'"