#=============================================================================#
# PowerShell script sample for coolOrange powerEvents                         #
# Triggers a DWF job when the file state is changed to Release		      	  #
#                                                                             #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

#Register-VaultEvent -EventName UpdateFileStates_Restrictions -Action 'CanTriggerDwfJob'
#Register-VaultEvent -EventName UpdateFileStates_Post -Action 'AddDwfJob'

$script:supportedDwfExtensions = @("iam", "idw", "dwg", "ipn", "ipt")

function CanTriggerDwfJob($files) {
    $supportedFiles = @($files | where { $supportedDwfExtensions -contains $_._Extension})
    foreach($file in $supportedFiles) {
        $newLifecycleState = Get-VaultLifecycleState -LifecycleDefinition $file._NewLifeCycleDefinition -State $file._NewState
        if($newLifecycleState.ReleasedState -eq $true) {

			$jobPermissions = $vault.JobService.CheckRolePermissions(@("GetJobsByDate", "AddJob")) 
			if($jobPermissions -contains $false) {
				Add-VaultRestriction -EntityName $file._Name -Message "Cannot change state of file to '$($file._NewState)' because current user requires following permissions: JobQueueRead, JobQueueAdd"
				return
			}

            $expectedJobType = "Autodesk.Vault.DWF.Create.$($file._Extension)"
            $jobForFileAlreadyExists = @(Get-VaultJobs -JobType $expectedJobType) | where {
                 (Get-VaultFile -FileId $_.ParamArray[0].Val).MasterId -eq $file.MasterId
            }
            if($jobForFileAlreadyExists) {
                Add-VaultRestriction -EntityName $file._Name -Message "Cannot change state of file to '$($file._NewState)' because a job of type '$expectedJobType' was already added to the queue."
            }
        }
    }
}

function AddDwfJob($files, $successful) {
    if(-not $successful) {
		return 
	}
    $releasedFiles = @($files | where { $supportedDwfExtensions -contains $_._Extension -and $_._ReleasedRevision -eq $true })
    foreach($file in $releasedFiles) {
        $jobType = "Autodesk.Vault.DWF.Create.$($file._Extension)"
        Write-Host "Adding job '$jobType' for released file '$($file._Name)' to queue."
        Add-VaultJob -Name $jobType -Parameters @{ "FileVersionId"=$file.Id } -Description "powerEvents: DWF-job for $($file._Name)"
   }
}

