function Get-JobParam($Key,$Value) {
	$jobParam = New-Object Autodesk.Connectivity.WebServices.JobParam
	$jobParam.Name = $Key
	$jobParam.Val = $Value
	return $jobParam
}
function QueuePropSyncJob {
<#
.EXAMPLE
$vdfFile = QueuePropSyncJob -File $file
.EXAMPLE
$vdfFile = QueuePropSyncJob -File $file -QueueDWFJob
#>
param(
$File,
[int]$Priority = 10,
[switch]$QueueDWFJob
)
	[Autodesk.Connectivity.WebServices.JobParam[]] $params = @()
	$fileId = (Get-VaultFile -FileId $file.MasterId).Id
	
    if($QueueDWFJob.ToBool()) {
        $paramQueueDwfJob = Get-JobParam -Key "QueueCreateDwfJobOnCompletion" -Value "True"
    } else {
        $paramQueueDwfJob = Get-JobParam -Key "QueueCreateDwfJobOnCompletion" -Value "False"
    }

	$paramEntityId = Get-JobParam "EntityId" "$fileId"
	$paramEntityClassId = Get-JobParam "EntityClassId" "FILE"
    $paramFileId = Get-JobParam -Key "FileVersionId" -Value "$fileId"

	$params += $paramFileId
	$params += $paramQueueDwfJob
    $params += $paramEntityId
    $params += $paramEntityClassId
	return $VaultConnection.WebServiceManager.JobService.AddJob("Autodesk.Vault.SyncProperties", "property sync job", $params, $Priority)
}
function QueueUpdateRevTableJob {
<#
.EXAMPLE
$vdfFile = QueueUpdateRevTableJob -File $file
.EXAMPLE
$vdfFile = QueueUpdateRevTableJob -File $file -QueueDWFJob
#>
param(
$File,
[int]$Priority = 10,
[switch]$QueueDWFJob
)

    switch($file._Extension) {
        "dwg" { $jobname = "Autodesk.Vault.UpdateRevisionBlock.dwg" }
        "idw" { $jobname = "Autodesk.Vault.UpdateRevisionBlock.idw" }
    }
	[Autodesk.Connectivity.WebServices.JobParam[]] $params = @()
	$fileId = (Get-VaultFile -FileId $file.MasterId).Id
	
    if($QueueDWFJob.ToBool()) {
        $paramQueueDwfJob = Get-JobParam -Key "UpdateViewOption" -Value "True"
    } else {
        $paramQueueDwfJob = Get-JobParam -Key "UpdateViewOption" -Value "False"
    }

    $paramFileId = Get-JobParam -Key "FileVersionId" -Value "$fileId"
	$paramEntityId = Get-JobParam "EntityId" "$fileId"
	$paramEntityClassId = Get-JobParam "EntityClassId" "FILE"

	$params += $paramFileId
	$params += $paramQueueDwfJob
    $params += $paramEntityId
    $params += $paramEntityClassId
	return $VaultConnection.WebServiceManager.JobService.AddJob($jobname, "Update revision table", $params, $Priority)
}
