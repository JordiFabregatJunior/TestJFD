$NetworkPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\Logstrup\MockedNetwork\"

function Remove-LocalFile {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$FileNameWithExtension
    )
    #Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    $destinationFile = Join-Path $NetworkPath $FileNameWithExtension
    if(Test-Path $DestinationFile) { 
        Remove-Item -Path $destinationFile -Force
    }
}

try {
    Import-Module powerVault
    Import-Module LOGSTRUP.Functions
    $fileMasterId= $vaultContext.CurrentSelectionSet | select -First 1 -ExpandProperty "Id"
    $folderId = $vaultContext.NavSelectionSet | select -First 1 -ExpandProperty "Id"
    $vaultContext.ForceRefresh = $true
    $file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
    $vfile = Get-VaultFile -FileId $file.Id
    $fileAssoc = Get-VaultFileAssociations -File $vfile._FullPath -Attachments
    foreach ($attach in $fileAssoc){
        if($vfile._Extension -in @("idw","dwg") -and $attach._Extension -in @("pdf","dxf")){
            $PDFfile = Update-VaultFile -File $attach._FullPath -LifecycleDefinition "Simple Release Process" -Status "Work in Progress"
            $Removed = $vault.DocumentService.DeleteFileFromFolderUnconditional($attach.MasterId,$folderId)
        }
        elseif($vfile._Extension -eq "ipt" -and $attach._Extension -in @("sat","dxf")){
            $Removed = $vault.DocumentService.DeleteFileFromFolderUnconditional($attach.MasterId,$folderId)
        }
        Remove-LocalFile -FileNameWithExtension $attach._Name
    }
}
catch{
    [System.Windows.Forms.MessageBox]::Show("The attachments of $($vfile.Name) couldn't be removed. Ensure that you have enough permissions with your administrator", "Attachment Removal - Error", "Ok", "Information") | Out-Null
}