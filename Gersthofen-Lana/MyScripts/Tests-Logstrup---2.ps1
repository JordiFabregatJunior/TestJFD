###____Debugging
Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$NetworkPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\Logstrup\MockedNetwork\"
$FromPath = 'C:\Temp\Logstrup_Tests\PART-Part-000.sat'
$FileNameWithExtension = "PART-Part-000.sat"	
$vfile = Get-VaultFile -Properties @{Name = $FileNameWithExtension}
$vaultFilePath = $vfile.Path

New-LocalFile -FromPath $FromPath -FilePath $vfile.Path
Remove-LocalFile -FileNameWithExtension $FileNameWithExtension -NetworkPath $NetworkPath

$files.GetType()

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
            }
        }
    }
}


function New-LocalFile {
    param (
        $FromPath,
        $FilePath 
    )
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($FromPath)
    $fileExtension = [System.IO.Path]::GetExtension($FromPath)
    $filename = $filename + $fileExtension
    $NetPathSctructure = Join-Path $NetworkPath $FilePath.Substring(2)
    $destinationFile = Join-Path $NetPathSctructure $filename
    if(-not (Test-Path $NetPathSctructure))
    {
        New-Item -Path $NetPathSctructure -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $FromPath -Destination $destinationFile
}


<###TESTS IN REAL MACHINE

$NetworkPath = "\\cadserverv\FileOutput"

Import-Module PowerVault
Open-VaultConnection -Server "localhost" -Vault "Logstrup" -user "Administrator"
$FileNameWithExtension = "COSimplePart.sat"
$vfile = Get-VaultFile -Properties @{Name = $FileNameWithExtension}
$vaultFilePath = $vfile.Path

New-LocalFile -FromPath $FromPath -FilePath $vfile.Path
Remove-LocalFiles -FileNameWithExtension $FileNameWithExtension -NetworkPath $NetworkPath
COSimplePart.sat

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

###>




<####OTHER TESTS			
Update-VaultFile -File $vfile._FullPath -LifecycleDefinition $vfile._LifeCycleDefinition -Status "Released"
$filename = "Draw-0013.pdf"
$PDF = Get-VaultFile -Properties @{Name = $filename}	
$PDF = Update-VaultFile -File $vfile._FullPath -LifecycleDefinition $PDF._LifeCycleDefinition -Status "Released"
$PDF = Update-VaultFile -File $vfile._FullPath -LifecycleDefinition "Simple Release Process" -Status "Work in Progress"
$PDF._State
$fileAssoc = Get-VaultFileAssociations -File $vfile._FullPath -Attachments
foreach($file in $fileAssoc){
    Write-host "Filename: $($file._FullName)"
}


$file = $vault.DocumentService.GetFileById($vFile.id)
$workingDirectory = "C:\Temp\$($file._Name)"
$filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($vfile._FullPath)
$localPDFfileLocation = "$workingDirectory\$($filenameWithoutExtension).pdf"
$vaultPDFfileLocation = $vfile._EntityPath +"/"+ (Split-Path -Leaf $localPDFfileLocation)
$fileAssoc = Get-VaultFileAssociations -File $vfile._FullPath -Attachments





$files = $vault.DocumentService.GetFilesByMasterId($vfile.MasterId)

###____Debugging

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
            New-LocalFile -FromPath $localPDFfileLocation
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


#$PDFfile = Update-VaultFile -File $PDFfile._FullPath -LifecycleDefinition "Simple Release Process" -Status "Released"#>