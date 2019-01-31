if(@("DXF","SAT") -contains $job.ManualExport){
    Write-Host "Starting job 'Create $($job.ManualExport) as attachment' for file '$($file._Name)' ..."
} else {
    Write-Host "Starting job 'Create DXF/SAT as attachment' for file '$($file._Name)' ..."
}

$hide = $false
$workingDirectory = "C:\Temp\$($file._Name)"
$filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file._FullPath)
$fastOpen = $file._Extension -eq "idw" -or $file._Extension -eq "dwg" -and $file._ReleasedRevision

if( @("idw","dwg","ipt") -notcontains $file._Extension) {
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
    if($job.ManualExport -ne 'DXF' -and $file._Extension -eq "ipt" ){
        $localfileLocation = "$workingDirectory\$($filenameWithoutExtension).sat"
        $vaultfileLocation = $file._EntityPath +"/"+ (split-path -Leaf $localfileLocation)
        $exportSATResult = Export-DocumentToSAT -To $localfileLocation -Application $openResult.Application
        if($exportSATResult) {       
            $SATfile = Add-VaultFile -From $localfileLocation -To $vaultfileLocation -FileClassification DesignVisualization -Hidden $hide
            $SATfile = Update-VaultFile -File $SATfile._FullPath -Properties $props -Revision $file._Revision -RevisionDefinition $file._RevisionDefinition
            if($SATfile){
                New-LocalFile -FromPath $localfileLocation -FilePath $SATfile.Path
            }
            $file = Update-VaultFile -File $file._FullPath -AddAttachments @($SATfile._FullPath)
        }
    }
    if($job.ManualExport -ne 'SAT'){
        if($file._Extension -eq "ipt") {
            if ($openResult.Document.Instance.ComponentDefinition.Type -eq [Inventor.ObjectTypeEnum]::kSheetMetalComponentDefinitionObject) {
                $DXFconfigFile = "$($env:POWERJOBS_MODULESDIR)Export\DXF_2D.ini"
                <#
                if($openResult.Document.Instance.ComponentDefinition.HasFlatPattern){
                    $DXFconfigFile = "$($env:POWERJOBS_MODULESDIR)Export\DXF_2D.ini"
                } else {
                    $DXFconfigFile = "$($env:POWERJOBS_MODULESDIR)Export\DXF_2D.ini"
                }#>
            } else {
                Add-Log "Part file is not a sheet metal part. DXF cannot be created!"
            }
        }
    }
    if($DXFconfigFile){
        $localfileLocation = "$workingDirectory\$($filenameWithoutExtension).dxf"
        $vaultfileLocation = $file._EntityPath +"/"+ (split-path -Leaf $localfileLocation)
        $exportDXFResult = Export-Document -Format 'DXF' -To $localfileLocation -Options $DXFconfigFile
        if($exportDXFResult) {
            $localDXFfiles = Get-ChildItem -Path (split-path -path $localfileLocation) | Where-Object { $_.Name -match '^'+[System.IO.Path]::GetFileNameWithoutExtension($localfileLocation)+'.*(.dxf|.zip)$' }
            $vaultFolder = (Split-Path $vaultfileLocation).Replace('\','/')
            $DXFfiles = @()
            foreach($localDXFfile in $localDXFfiles)  {
                $DXFfile = Add-VaultFile -From $localDXFfile.FullName -To ($vaultFolder+"/"+$localDXFfile.Name) -FileClassification DesignVisualization -Hidden $hide
                $DXFfile = Update-VaultFile -File $DXFfile._FullPath -Properties $props -Revision $file._Revision -RevisionDefinition $file._RevisionDefinition
                if($DXFfile){
                    New-LocalFile -FromPath $localfileLocation -FilePath $DXFfile.Path
                }
                $DXFfiles += $DXFfile._FullPath
            }
            $file = Update-VaultFile -File $file._FullPath -AddAttachments $DXFfiles
        }
    }
    $closeResult = Close-Document
}

Clean-Up -folder $workingDirectory

if(-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.Error.Message)")
}
if($SATconfigFile -and -not $exportSATResult) {
    throw("Failed to export document $($file.LocalPath) to $("$workingDirectory\$($file._Name).sat")!")
}
if($DXFconfigFile -and -not $exportDXFResult) {
    throw("Failed to export document $($file.LocalPath) to $("$workingDirectory\$($file._Name).dxf")! Reason: $($exportDXFResult.Error.Message)")
}
if(-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.Error.Message))")
}

if(@("DXF","SAT") -contains $job.ManualExport){
    Write-Host "Completed job 'Create $($job.ManualExport) as attachment'"
} else {
    Write-Host "Completed job 'Create DXF/SAT as attachment' for file '$($file._Name)' ..."
}