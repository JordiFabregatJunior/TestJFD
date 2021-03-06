#=============================================================================#
# PowerShell script sample for coolOrange powerJobs                           #
# Creates a DXF file and add it to Autodesk Vault as Design Vizualization     #
#                                                                             #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

$hideDXF = $false
$workingDirectory = "C:\Temp\$($file._Name)"
$localDXFfileLocation = "$workingDirectory\$($file._Name).dxf"
$vaultDXFfileLocation = $file._EntityPath +"/"+ (split-path -Leaf $localDXFfileLocation)
$fastOpen = $file._Extension -eq "idw" -or $file._Extension -eq "dwg" -and $file._ReleasedRevision

Write-Host "Starting job 'Create DXF as attachment' for file '$($file._Name)' ..."

if( @("idw","dwg","ipt") -notcontains $file._Extension ) {
    Write-Host "Files with extension: '$($file._Extension)' are not supported"
    return
}

$downloadedFiles = Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren:$fastOpen -ExcludeLibraryContents:$fastOpen
$file = $downloadedFiles | select -First 1

$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen }
if($openResult) {
   if($file._Extension -eq "ipt") {
        $configFile = "$($env:POWERJOBS_MODULESDIR)Export\DXF_SheetMetal.ini" 
   } else {
        $configFile = "$($env:POWERJOBS_MODULESDIR)Export\DXF_2D.ini" 
   }  
   $exportResult = Export-Document -Format 'DXF' -To $localDXFfileLocation -Options $configFile 
   if($exportResult) {
        $localDXFfiles = Get-ChildItem -Path (split-path -path $localDXFfileLocation) | Where-Object { $_.Name -match '^'+[System.IO.Path]::GetFileNameWithoutExtension($localDXFfileLocation)+'.*(.dxf|.zip)$' }
        $vaultFolder = (Split-Path $vaultDXFfileLocation).Replace('\','/')
        $DXFfiles = @()
        foreach($localDXFfile in $localDXFfiles)  {
            $DXFfile = Add-VaultFile -From $localDXFfile.FullName -To ($vaultFolder+"/"+$localDXFfile.Name) -FileClassification DesignVisualization -Hidden $hideDXF
            $DXFfiles += $DXFfile._FullPath
        }
        $file = Update-VaultFile -File $file._FullPath -AddAttachments $DXFfiles
   } 
   $closeResult = Close-Document
}

Clean-Up -folder $workingDirectory

if(-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.Error.Message)")
}
if(-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localDXFfileLocation! Reason: $($exportResult.Error.Message)")
}
if(-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.Error.Message))")
}
Write-Host "Completed job 'Create DXF as attachment'"