#=============================================================================#
# PowerShell script sample for coolOrange powerJobs                           #
# Creates a PNG file and add it to Autodesk Vault as Design Vizualization     #
#                                                                             #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

$hidePNG = $false
$workingDirectory = "C:\Temp\$($file._Name)"
$localPNGfileLocation = "$workingDirectory\$($file._Name).png"
$vaultPNGfileLocation = $file._EntityPath +"/"+ (split-path -Leaf $localPNGfileLocation)
$fastOpen = $file._Extension -eq "idw" -or $file._Extension -eq "dwg" -and $file._ReleasedRevision

Write-Host "Starting job 'Create PNG as attachment' for file '$($file._Name)' ..."

if( @("idw","dwg","iam","ipt","png") -notcontains $file._Extension ) {
    Write-Host "Files with extension: '$($file._Extension)' are not supported"
    return
}

$downloadedFiles = Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren:$fastOpen -ExcludeLibraryContents:$fastOpen
$file = $downloadedFiles | select -First 1

$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen } 
if($openResult) {
    $exportResult = Export-Document -Format 'PNG' -To $localPNGfileLocation
    if($exportResult) {
        $PNGfile = Add-VaultFile -From $localPNGfileLocation -To $vaultPNGfileLocation -FileClassification DesignVisualization -Hidden $hidePNG
        $file = Update-VaultFile -File $file._FullPath -AddAttachments @($PNGfile._FullPath)
    }
    $closeResult = Close-Document
} 
Clean-Up -folder $workingDirectory

if(-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.Error.Message)")
}
if(-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localPNGfileLocation! Reason: $($exportResult.Error.Message)")
}
if(-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.Error.Message))")
}
Write-Host "Completed job 'Create PNG as attachment'"