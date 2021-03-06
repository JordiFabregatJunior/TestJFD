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
$filename_temp=$file.'Zeichnungs-Nr.'
$workingDirectory = "C:\Temp\$($file._Name)"
$localDXFfileLocation = "$workingDirectory\$($filename_temp).dxf"
$vaultDXFfileLocation = $file._EntityPath + "/" + "Nebendokumente" + "/" + (split-path -Leaf $localDXFfileLocation)
$fastOpen = $file._Extension -eq "idw" -or $file._Extension -eq "dwg" -and $file._ReleasedRevision
$Revision_file=$file.Revision
$kommentar="DXF zur Revision: " + $Revision_file
Add-Log "Starting job 'Create DXF as attachment' for file '$($file._Name)' ..."

if( @("idw","dwg","ipt") -notcontains $file._Extension ) {
    Add-Log "Files with extension: '$($file._Extension)' are not supported"
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
            $DXFfile = Add-VaultFile -From $localDXFfile.FullName -To ($vaultFolder+"/"+$localDXFfile.Name) -FileClassification None -Hidden $hideDXF -comment $kommentar
            #$DXFfiles += $DXFfile._FullPath
        }
        $file = Update-VaultFile -File $file._FullPath -AddAttachments $DXFfiles -comment $kommentar
        #$DXFfile=Update-VaultFile -File $DXFfile._FullPath -Status "Freigegeben"
   } 
   $closeResult = Close-Document
}

Clean-Up -folder $workingDirectory

if(-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.ErrorMessage)")
}
if(-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localDXFfileLocation! Reason: $($exportResult.ErrorMessage)")
}
if(-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.ErrorMessage))")
}
Add-Log "Completed job 'Create DXF as attachment'"