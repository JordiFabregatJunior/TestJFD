#=============================================================================#
# PowerShell Module - for maintaining compatibility when updating             #
#                     from 18.0.6 or earlier.                                 #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

function Get-PowerJobs {
param()
    $powerJobs = powerJobs\Get-PowerJobs
	[Autodesk.Connectivity.WebServices.Job] $script:_job = $null
	$powerJobs | Add-Member -Name Job -MemberType ScriptProperty -Force -Value {
		if($global:job -eq $null) { return $null }
		if($script:_job) { return $script:_job }
        return $script:_job = @(@($vault.JobService.GetJobsByDate([int]::MaxValue,[DateTime]::MinValue)) | Where-Object {$_.Id -eq $global:job.Id})[0]
	} -SecondValue {
		$this | Add-Member -Name Job -MemberType NoteProperty -Force -Value $args[0]
	}
    return $powerJobs
}

function Add-Log {
param($message)
	Write-Host $message
}

function Open-Document {
	param(
		[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string]$localFile,
		[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
		[string]$application=$null,
		[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
		[hashtable]$options=$null
	)
	$result = powerJobs\Open-Document -LocalFile $localFile -Application $application -Options $options
	$result | Add-Member -Name ErrorMessage -MemberType NoteProperty -Force -Value ($result.Error.Message)
	return $result
}

function Export-Document {
	param(
		[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string]$to,
		[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
		[string]$format=$null,
		[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
		$options=$null,
		[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
		$document=$null,
		[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
		$onExport=$null
	)
	$result = powerJobs\Export-Document -To $to -Format $format -Options $options -Document $document -OnExport $onExport
	$result | Add-Member -Name ErrorMessage -MemberType NoteProperty -Force -Value ($result.Error.Message)
	return $result
}

function Close-Document {
	param(
		[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
		[bool]$save=$false,
		[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
		$document=$null
	)
	$result = powerJobs\Close-Document -Save $save -Document $document
	$result | Add-Member -Name ErrorMessage -MemberType NoteProperty -Force -Value ($result.Error.Message)
	return $result
}