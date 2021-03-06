#=============================================================================#
# PowerShell Module - Vault Helper for coolOrange powerJobs for Vault 2016    #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

function Clean-Up {
param(
	[string]$folder = $null,
	$files = @()
)
    function Remove-EmptyFolders($folder) {
        $folders = @($folder, (Get-ChildItem $folder -Recurse))
        $folders =  @($folders | Where {$_.PSIsContainer -and @(Get-ChildItem -LiteralPath $_.Fullname -Recurse | Where { -not $_.PSIsContainer }).Count -eq 0 })
        Remove-Items $folders      
    }    
    function Remove-Items($items) {
        $items | foreach { 	Remove-Item -Path $_.FullName -Force -Recurse -confirm:$false -ErrorAction SilentlyContinue }
    }
    
    $files =@($files | foreach { 
        if($_.GetType() -eq [string]) { Get-Item $_ -ErrorAction SilentlyContinue }
        elseif($_.GetType() -eq [System.IO.FileInfo]) { $_ }
        else {Get-Item $_.LocalPath -ErrorAction SilentlyContinue}    
    })
    
    if(-not $files -and $folder) {
        $files = Get-ChildItem $folder -Recurse
    }
    
    Remove-Items $files
     
     if( -not $folder -and $files.Count -gt 0 ) {
        $folder =$files[0]
         while( $true ) {          
            if(-not ($folder = Split-Path $folder)) {
                 throw('No folder found')
            }
            
            if(($files | where { (Split-Path $_).StartsWith($folder) }).Count -eq $files.Count) {
                break;
            }
         }
     }	
     Remove-EmptyFolders (Get-Item $folder)
}