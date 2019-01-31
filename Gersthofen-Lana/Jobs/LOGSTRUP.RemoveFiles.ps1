$NetworkPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\Logstrup\MockedNetwork"

function Remove-LocalFiles {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$FileNameWithExtension,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$NetworkPath
    )
    $fileLocalPaths = Get-ChildItem -Path $NetworkPath -File -Recurse -Name $FileNameWithExtension
    foreach($filePath in $fileLocalPaths){
        $localFilePath = Join-Path $NetworkPath $filePath
        if($localFilePath -ne $NetworkPath -and (Test-Path $localFilePath)){ 
            Remove-Item -Path $localFilePath -Force
            if(-not(Test-Path $localFilePath)){
                Write-Host "Removed local attachment from $($localFilePath)!"
                if([string]::IsNullOrEmpty($result)){
                    $result = $true
                }
            } else {
                $result = $false
            }
        }
    }
}

try {
    Import-Module powerVault
    $folder = $vault.DocumentService.GetFoldersByFileMasterId($file.MasterId)
    $fileAssoc = Get-VaultFileAssociations -File $file._FullPath -Attachments
    if($fileAssoc.count -eq 0){
        Write-Host "No attached files to remove for $($file._Name)!"
        return
    }
    foreach ($attach in $fileAssoc){
        if($file._Extension -eq "idw" -and $attach._Extension -eq "pdf"){
            $vault.DocumentService.DeleteFileFromFolderUnconditional($attach.MasterId,$folder.Id)
        }
        elseif($file._Extension -eq "ipt" -and $attach._Extension -in @("sat","dxf")){
            $vault.DocumentService.DeleteFileFromFolderUnconditional($attach.MasterId,$folder.Id)
        }
        $RemovedFile = $vault.DocumentService.FindFilesByIds($attach.Id) | select -First 1
        if($RemovedFile.Id -eq -1 -or $RemovedFile.Count -eq 0){
            $VaultRemoved = $true
            Write-Host "Removed vault attachment $($attach._Name) for file $($file._Name)!"
        }
        $LocallyRemoved = Remove-LocalFiles -FileNameWithExtension $attach._Name -NetworkPath $NetworkPath
    }
}
catch{
    if(-not($VaultRemoved) -and $LocallyRemoved) {
        Write-Host "Vault attachments for $($file._Name) could not be removed. Ensure you have enough permissions with your administrator"        
    } elseif (($VaultRemoved) -and -not($LocallyRemoved)) {
        Write-Host "Local attachments for $($file._Name) could not be removed from $($NetworkPath)!"
    } else {
        Write-Host "Attachments of $($file._Name) couldn't be removed."
    }
}