#=============================================================================#
# PowerShell Script - Gets called for each powerJobs job                      #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

$ErrorActionPreference = "Stop"
$global:IAmRunningInJobProcessor = (get-process -id $pid).Name -eq 'Connectivity.JobProcessor.Delegate.Host'
$global:powerJobs = Get-PowerJobs

if($IAmRunningInJobProcessor) {
	Open-VaultConnection
    switch($job.EntityClassId) {
        "File" { 
            $fileWithCorrectVersion = (Get-VaultFile -FileId $job.EntityId)
		    $global:file = Get-VaultFile -FileId $fileWithCorrectVersion.MasterId 
        }
        "FLDR" {
            $fldr = $vault.DocumentService.GetFolderById($job.EntityId)
            $global:folder = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.Folder($vaultConnection, $fldr)
        }
        "CUSTENT" {
            $custEnt = $vault.CustomEntityService.GetCustomEntitiesByIds(@($job.EntityId)) | select -First 1
            $global:customObject = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.CustomObject($vaultConnection, $custEnt)
        }
        "ITEM" {
            $global:item = Get-VaultItem -ItemId $job.EntityId
        }
    }
    if($job.ChangeOrderId) {
        $changeOrdr = $vault.ChangeOrderService.GetChangeOrdersByIds(@($job.ChangeOrderId)) | select -First 1
        $global:changeOrder = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.ChangeOrder($vaultConnection, $changeOrdr)
    }
} 
else {
    Write-Host "Job is running in powerShell IDE"
}