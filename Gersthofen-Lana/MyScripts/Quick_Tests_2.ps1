Import-Module PowerVault
Import-Module PowerJobs
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$filename = "PART-NOT-0000.ipt"
$file = Get-VaultFile -Properties @{"Name" = $filename}

###___ExportingToSAT_throughInventor
$InvApp = $openResult.Application.Instance
$InvApp.ApplicationAddIns.Count
$SATAddin = $InvApp.ApplicationAddIns | Where-Object { $_.ClassIdString -eq "{89162634-02B6-11D5-8E80-0010B541CD80}"}
$SourceObject = $openResult.Application.Instance.ActiveDocument
$Context = $InvApp.TransientObjects.CreateTranslationContext()
$Context.Type = 13059
$Options = $InvApp.TransientObjects.CreateNameValueMap()
$oData = $InvApp.TransientObjects.CreateDataMedium()
$oData.MediumType = 56577 #kFileNameMedium. Using file name as the type of medium data. By default  kDataObjectMedium 56578 Using DataObject as the type of medium data. 
$oData.FileName = "C:\Temp\Test2.sat"  
$SAT = $SATAddin.SaveCopyAs($SourceObject, $Context, $Options, $oData)

class ExportResult {
    [bool] $Result
    [string] $Message

    ExportResult($result, $message) {
        $this.Result = $result
        $this.Message = $message
    }
}
$result = [ExportResult]::new($true, $null)


if($SAT){
    return $true
} else {
    return $result
}

if($InvApp.Caption -like "*Inventor*"){
    Write-Host "It is inside"
}
###___ExportingToSAT_throughInventor

$filenameWithExtension = [System.IO.Path]::GetFileNameWithOutExtension($InvApp.ActiveDocument.FullFileName)
$hideSAT = $false
$workingDirectory = "C:\Temp\$($file._Name)"
$localSATfileLocation = "$workingDirectory\$($file._Name).sat"
$vaultSATfileLocation = $file._EntityPath +"/"+ (split-path -Leaf $localSATfileLocation)
$fastOpen = $file._Extension -eq "idw" -or $file._Extension -eq "dwg" -and $file._ReleasedRevision

if( @("idw","dwg","ipt"; "iam") -notcontains $file._Extension ) {
    Write-Host "Files with extension: '$($file._Extension)' are not supported"
    return
}

$downloadedFiles = Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren:$fastOpen -ExcludeLibraryContents:$fastOpen
$file = $downloadedFiles | select -First 1
$entityClassId = $file.'Entity Type ID'
$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($EntityClassId)
$propertyNames = $propDefs | Where { $_.IsSys -eq $false } | Select -ExpandProperty DispName
$props = @{}
forEach($propertyName in $propertyNames){
    $props += @{$propertyName = $file.$propertyName}
}


$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen }
Show-Inspector
$OpenResult.Applicationrun("CreateSAT")
if($openResult) {
    $SATconfigFile = "$($env:POWERJOBS_MODULESDIR)Export\SAT.ini"
}
$exportResult = Export-Document -To $localSATfileLocation -Options $SATconfigFile
if($exportResult) {       
    $SATfile = Add-VaultFile -From $localSATfileLocation -To $vaultSATfileLocation -FileClassification DesignVisualization -Hidden $hideSAT
    $SATfile = Update-VaultFile -File $SATfile._FullPath -Properties $props -Revision $file._Revision -RevisionDefinition $file._RevisionDefinition
    if($PDFfile){
        New-LocalFile -FromPath $localSATfileLocation
    }
    $file = Update-VaultFile -File $file._FullPath -AddAttachments @($SATfile._FullPath)
}
$closeResult = Close-Document

Clean-Up -folder $workingDirectory

if(-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.Error.Message)")
}
if(-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localSATfileLocation! Reason: $($exportResult.Error.Message)")
}
if(-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.Error.Message))")
}
Write-Host "Completed job 'Create DXF as attachment'"