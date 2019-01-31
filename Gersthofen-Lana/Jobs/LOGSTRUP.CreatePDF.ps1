
$hidePDF = $false
$workingDirectory = "C:\Temp\$($file._Name)"
$filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file._FullPath)
$localPDFfileLocation = "$workingDirectory\$($filenameWithoutExtension).pdf"
$vaultPDFfileLocation = $file._EntityPath +"/"+ (Split-Path -Leaf $localPDFfileLocation)
$fastOpen = $file._Extension -eq "idw" -or $file._Extension -eq "dwg" -and $file._ReleasedRevision

Write-Host "Starting job 'Create PDF as attachment' for file '$($file._Name)' ..."

if( @("idw","dwg") -notcontains $file._Extension ) {
    Write-Host "Files with extension: '$($file._Extension)' are not supported"
    return
}

$downloadedFiles = Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren:$fastOpen -ExcludeLibraryContents:$fastOpen
$file = $downloadedFiles | select -First 1
$entityClassId = $file._EntityTypeID
$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($entityClassId)
$onlyFileProperties = $vault.PropertyService.GetPropertiesByEntityIds($entityClassId, $file.Id)
forEach($Property in $onlyFileProperties){
    $propDef = $propDefs | Where { $_.Id -eq $Property.PropDefId }
    if ($propDef.IsSys -eq $false){
        $propertyName = $propDef.DispName
        [hashtable]$props += @{$propertyName = $file.$propertyName}
    }
}

$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen } 

if($openResult) {
    if($openResult.Application.Name -like 'Inventor*') {
        $configFile = "$($env:POWERJOBS_MODULESDIR)Export\PDF_2D.ini"
    } else {
        $configFile = "$($env:POWERJOBS_MODULESDIR)Export\PDF.dwg" 
    }                  
    $exportResult = Export-Document -Format 'PDF' -To $localPDFfileLocation -Options $configFile
    if($exportResult) {       
        $PDFfile = Add-VaultFile -From $localPDFfileLocation -To $vaultPDFfileLocation -FileClassification DesignVisualization -Hidden $hidePDF
        $PDFfile = Update-VaultFile -File $PDFfile._FullPath -Properties $props -Revision $file._Revision -RevisionDefinition $file._RevisionDefinition -LifecycleDefinition $PDFfile._LifeCycleDefinition -Status "Released"
        if($PDFfile){
            New-LocalFile -FromPath $localPDFfileLocation -FilePath $PDFfile.Path
        }
        $file = Update-VaultFile -File $file._FullPath -AddAttachments @($PDFfile._FullPath)
    }
    $closeResult = Close-Document
}

Clean-Up -folder $workingDirectory

if(-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.Error.Message)")
}
if(-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localPDFfileLocation! Reason: $($exportResult.Error.Message)")
}
if(-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.Error.Message))")
}
Write-Host "Completed job 'Create PDF as attachment'"


#$PDFfile = Update-VaultFile -File $PDFfile._FullPath -LifecycleDefinition "Simple Release Process" -Status "Released"