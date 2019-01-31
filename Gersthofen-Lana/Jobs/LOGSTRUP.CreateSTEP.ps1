
$hideSTEP = $false
$workingDirectory = "C:\Temp\$($file._Name)"
$filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file._FullPath)
$localSTEPfileLocation = "$workingDirectory\$($filenameWithoutExtension).stp"
$vaultSTEPfileLocation = $file._EntityPath +"/"+ (split-path -Leaf $localSTEPfileLocation)

Write-Host "Starting job 'Create STEP as attachment' for file '$($file._Name)' ..."

if( @("iam","ipt") -notcontains $file._Extension ) {
    Write-Host "Files with extension: '$($file._Extension)' are not supported"
    return
}

$file = Get-VaultFile -File $file._FullPath -DownloadPath $workingDirectory
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

$openResult = Open-Document -LocalFile $file.LocalPath

$iLogicScriptName = "1_InvTestExternalRule_IncreaseExtrusion_FromPartNumberValue"
$RuleScope = 'External'
#$iLogicScriptName = "1_InvTestInternalRule_SAVE_XMLFile"
#$RuleScope = 'Internal'
$iLogicAddInGuid = "{3BDD8D79-2179-4B11-8A5A-257B1C0263AC}"

if($openResult) {  
    $invApp = $openResult.Application.Instance
    $invDoc = $openResult.Document.Instance

    $iLogicAddIn = Activate-AddIn -invApp $invApp -addinName "iLogic" -addinGuid $iLogicAddInGuid
    Run-iLogicScript -iLogicAddIn $iLogicAddIn -invDoc $invDoc -scriptName $iLogicScriptName -RuleScope $RuleScope
    AddUpdate-VaultFiles -LocalFileName $file.LocalPath -VaultFileName $file._FullPath
    $exportResult = Export-Document -Format 'STEP' -To $localSTEPfileLocation -Options "$($env:POWERJOBS_MODULESDIR)Export\STEP.ini"
    if($exportResult) {
        $STEPfile = Add-VaultFile -From $localSTEPfileLocation -To $vaultSTEPfileLocation -FileClassification DesignVisualization -Hidden $hideSTEP
        $STEPfile = Update-VaultFile -File $STEPfile._FullPath -Properties $props -Revision $file._Revision -RevisionDefinition $file._RevisionDefinition
        $file = Update-VaultFile -File $file._FullPath -AddAttachments @($STEPfile._FullPath)
    }
    $closeResult = Close-Document
}
#Clean-Up -folder $workingDirectory

if(-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.Error.Message)")
}
if(-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localSTEPfileLocation! Reason: $($exportResult.Error.Message)")
}
if(-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.Error.Message))")
}
Write-Host "Completed job 'Create STEP as attachment'"