#==============================================================================#
# PowerShell Module - Application helper for coolOrange powerJobs applications #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                       #
#                                                                              #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER    #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES  #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.   #
#=============================================================================#


function Register-Application {
    param( [Type] $applicationType )
    $powerJobs = Get-PowerJobs
    $applicationTypes = $powerJobs.Applications.Values | foreach {$_.GetType()}
	if($applicationTypes  -notcontains $applicationType) {
        $application = New-Object -TypeName $applicationType.FullName       
		$powerJobs.Applications.Add($application.Name, $application)
	}
}

Register-Application ([coolOrange.GenerateEngine.Inventor.Application])
Register-Application ([coolOrange.GenerateEngine.Inventor.Server.Application])
Register-Application ([coolOrange.GenerateEngine.TrueView.Application])
#Register-Application ([coolOrange.GenerateEngine.Acad.Application])

function Get-Application {
    param( [string]$application )
    (Get-PowerJobs).Applications[$application]
}

function Test-ApplicationInstalled {
    param( [string]$application )
    (Get-Application $application).IsInstalled
}

function Test-ApplicationSupportsDocument {
    param( 
        [string]$application,
        [string]$document
    )
    $fileInfo = new-object powerJobs.Interfaces.FileInfo $document
    (Get-Application $application).IsSupportedFile($fileInfo)
}