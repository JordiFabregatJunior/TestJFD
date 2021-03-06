#==============================================================================#
# PowerShell Module - General stuff which is required very often.	       #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                       #
#                                                                              #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER    #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES  #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.   #
#==============================================================================#

$global:powerEvents_ReloadPsScripts = $true

$global:processName = (Get-Process -Id $pid).ProcessName


function Get-VaultLifecycleState {
    param(
        [string]$lifecycleDefinition,
        [string]$state
    )

    $lifecycles = $vault.LifeCycleService.GetAllLifeCycleDefinitions()
	$lifecycle = $lifecycles | where {$_.DispName -eq $lifecycleDefinition} | select -First 1
    $lifecycle.StateArray | where {$_.DispName -eq $state} | select -First 1
}

function Get-VaultActivity {
    param(
        $changeOrder,
        [string]$activity
    )
    $changeOrderGroup = $vault.ChangeOrderService.GetChangeOrderGroupByChangeOrderId($changeOrder.Id)
    $workflowInfo = $vault.ChangeOrderService.GetWorkflowInfo($changeOrderGroup.Workflow.Id)
	$workflowInfo.ActivityArray | where {$_.DispName -eq $activity} | select -First 1
}

function Get-VaultJobs {
    param( [string]$jobType )
    @(($vault.JobService.GetJobsByDate([int]::MaxValue, [DateTime]::MinValue)) | where { $_.Typ -eq $jobType })
}