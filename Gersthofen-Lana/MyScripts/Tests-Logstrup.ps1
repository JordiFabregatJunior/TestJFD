
$filename = "Draw-0012.idw"	
$filename = "Draw-0010.pdf"
$filename = "PART-NOT-0000.ipt"					
$vfile = Get-VaultFile -Properties @{Name = $filename}
$file = $vault.DocumentService.GetFileById($vFile.id)
$workingDirectory = "C:\Temp\$($file._Name)"
$filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($vfile._FullPath)
$localPDFfileLocation = "$workingDirectory\$($filenameWithoutExtension).pdf"
$vaultPDFfileLocation = $vfile._EntityPath +"/"+ (Split-Path -Leaf $localPDFfileLocation)
$fileAssoc = Get-VaultFileAssociations -File $vfile._FullPath -Attachments
Update-VaultFile -File $vfile._FullPath -LifecycleDefinition "Simple Release Process" -Status "Work in Progress"




$files = $vault.DocumentService.GetFilesByMasterId($vfile.MasterId)
foreach ($file in $file){
    Write-Host "$($file.Id)"
}
$onlyFileProperties = $vault.PropertyService.GetPropertiesByEntityIds('FILE', $vfile.Id)
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/Inventor/Test-Related-IDW")					
$entityClassId = $vfile._EntityTypeID
$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($EntityClassId)
$propertyNames = $propDefs | Where { $_.IsSys -eq $false } | Select -ExpandProperty DispName
[hashtable]$props = @{}
forEach($propertyName in $propertyNames){
    $props += @{$propertyName = $file.$propertyName}
}

$entityClassId = $vfile._EntityTypeID
$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($EntityClassId)
$onlyFileProperties = $vault.PropertyService.GetPropertiesByEntityIds('FILE', $vfile.Id)
[hashtable]$props = @{}
forEach($Property in $onlyFileProperties){
    $propDef = $propDefs | Where { $_.Id -eq $Property.PropDefId }
    if ($propDef.IsSys -eq $false){
        $propertyName = $propDef.DispName
        $props += @{$propertyName = $vfile.$propertyName}
    }
}
$props.GetEnumerator() | Sort -Property Name


$wd = new-object -comobject word.application
$Inv = new-object -comobject inventor.application
$filename = "PART-NOT-0000"
$Inv.documents.open($filename)


$LocallyRemoved = $true
$VaultRemoved = $false

$LocallyRemoved = $false
$VaultRemoved = $true
    
$NetworkPath = "C:\Temp\Test"
$FileNameWithExtension = "Neues Textdokument.txt"
$destinationFile = Join-Path $NetworkPath $FileNameWithExtension
if(Test-Path $DestinationFile) {
    Write-host "In"
    if($destinationFile -ne $NetworkPath){ 
        Write-host "In2" 
        Remove-Item -Path $destinationFile -Force
    }
}
$filename = "PART-YES-0014.ipt.sat"
$filename = "PART-YES-0013.ipt"	
$vfile = Get-VaultFile -Properties @{Name = $filename}
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/Logstrup-TESTS")
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/Folder-Tests/Testdown2")

$removed = Remove-Item -Path $destinationFile -Force
$vault.DocumentService.DeleteFileFromFolderUnconditional($vfile.MasterId,$folder.Id)
$RemovedFile = $vault.DocumentService.FindFilesByIds($vfile.Id) | select -First 1
if($RemovedFile.Id -eq -1 -or $RemovedFile.Count -eq 0){
    Write-Host "Removed"
}


if($LocallyRemoved -and -not ($VaultRemoved)){
    write-host "Failed to remove attached vault files for $($file._Name)!"
} elseif($VaultRemoved -and -not ($LocallyRemoved)) {
    write-host "Failed to remove attached files in local network for $($file._Name)!"
} else {
    write-host "The attachments of $($file._Name) couldn't be removed. Ensure that you have enough permissions with your administrator"
}
#

function Select-File ($Extension){
    $filename = "Copy of PART-BOX-0003.$($Extension)"
    $folder = $vault.DocumentService.GetFolderByPath("$/Designs/Logstrup-TESTS")	
    $files = $vault.DocumentService.GetLatestFilesByFolderId($folder.Id,$false)
    foreach ($file in $files){
        if ($file.Name -eq $filename){
            $vfile = Get-VaultFile -FileId $file.Id
            return $vfile
        }
    }
}

$NetworkPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\Logstrup\MockedNetwork"

function Remove-LocalFile {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$FileNameWithExtension
    )
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    $destinationFile = Join-Path $NetworkPath $FileNameWithExtension
    if(Test-Path $DestinationFile) { 
        $LocallyRemoved = Remove-Item -Path $destinationFile -Force
        Show-Inspector
        if(-not $LocallyRemoved){
            write-host "Failed to remove attached local file in $($destinationFile)!"
        } else {
            write-host "Successfully removed attached local file $($FileNameWithExtensionin) in $($NetworkPath)!"
        }
    }
}
$file = Select-File -Extension "idw"

#$fileMasterId= $vaultContext.CurrentSelectionSet | select -First 1 -ExpandProperty "Id"
#$folderId = $vaultContext.NavSelectionSet | select -First 1 -ExpandProperty "Id"
#$vaultContext.ForceRefresh = $true
#$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
$folder = $vault.DocumentService.GetFoldersByFileMasterId($file.MasterId)
$fileAssoc = Get-VaultFileAssociations -File $file._FullPath -Attachments
foreach ($attach in $fileAssoc){
    if($file._Extension -eq "idw" -and $attach._Extension -eq "pdf"){
        $VaultRemoved = $vault.DocumentService.DeleteFileFromFolderUnconditional($attach.MasterId,$folder.Id)
    }
    elseif($file._Extension -eq "ipt" -and $attach._Extension -in @("sat","dxf")){
        $VaultRemoved = $vault.DocumentService.DeleteFileFromFolderUnconditional($attach.MasterId,$folder.Id)
    }
    Remove-LocalFile -FileNameWithExtension $attach._Name
}
write-host "Successfully removed attached files for $($file._Name)!"


Remove-Item -Path $destinationFile -Force