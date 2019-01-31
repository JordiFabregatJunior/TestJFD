Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Paula"
$filename = "Copy of PART-BOX-0003.idw"
$filename = "Copy of PART-BOX-0003.idw.pdf"
$filename = "Copy of PART-BOX-0003.idw.dwg"
$filename = "PART-NOT-0000.ipt"
$vfilePDF = Get-VaultFile -Properties @{"Name" = $filename}
$file = Get-VaultFile -Properties @{"Name" = $filename}
$file = Select-File -Extension "idw"; Write-Host "$($file._FullPath)"
$PDFjob = Add-VaultJob -Name "LOGSTRUP.CreatePDF" -Description "LOGSTRUP.CreatePDF" -Parameters @{EntityClassId = "FILE"; EntityId = $file.Id} -Priority 10
$updated = Update-VaultFile -File $vfilePDF._FullPath -RevisionDefinition "Standard Alphabetic Format" -Revision "B"

if($updated){
    Write-host "Revision: $($vfile._Revision)"
}
$fileIDW = $vault.DocumentService.GetFileById($vfileIDW.id)

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


function Restore-Files{
    $filename = "Copy of PART-BOX-0003.idw"
    $folder = $vault.DocumentService.GetFolderByPath("$/Designs/Logstrup-TESTS")	
    $files = $vault.DocumentService.GetLatestFilesByFolderId($folder.Id,$false)
    foreach ($file in $files){
        if ($file.Name -eq $filename){
            $PDFjob = Add-VaultJob -Name "Sample.CreatePDF" -Description "-" -Parameters @{EntityClassId = "FILE"; EntityId = $file.Id} -Priority 10
            #$DXFjob = Add-VaultJob -Name "Sample.CreateDXF" -Description "-" -Parameters @{EntityClassId = "FILE"; EntityId = $file.Id} -Priority 10
        }
    }
    return $PDFjob
}

Write-Host "Starting job 'Remove.Files' for file '$($file._Name)' ..."

if( @("idw","dwg","ipt") -notcontains $file._Extension ) {
    Write-Host "Files with extension: '$($file._Extension)' are not supported"
    return
}

$pdf = Restore-Files
$jobPermissions = $vault.JobService.CheckRolePermissions(@("GetJobsByDate", "AddJob")) 
if($jobPermissions -contains $false) {
	Add-VaultRestriction -EntityName $file._Name -Message "Cannot change state of file to '$($file._NewState)' because current user requires following permissions: JobQueueRead, JobQueueAdd"
	return
}

$jobQueue = $vault.JobService.GetJobsByDate(1000,[DateTime]::MinValue)
$currentJob = $jobQueue | Where-Object {$_.Id.Equals($powerJobs.Job.Id)}
$vaultUser = $vault.AdminService.GetUserByUserId($vaultconnection.UserID)
$vault.jobservice.


$vaultUser = $vault.AdminService.GetUserByUserId($vaultconnection.UserID)
$userRoles = $vault.AdminService.GetRolesByUserId($vaultUser.Id)
$userName = $JobUser.Name
$IsValidUser = Check-UserPermissions -UserId 'Administrators' -RequiredPermissions $userName
if(-not($IsValidUser)){
    Write-Host "Current user $($VaultUser.Name) is not allowed "
    throw "Job failed"
} elseif($IsValidUser){
     Write-Host "Current user $($userName) is allowed; going on!!!"
}


$file = Select-File -Extension "idw"; Write-Host "$($file._FullPath)"
$fileAssoc = Get-VaultFileAssociations -File $file._FullPath -Attachments | select -First 1 
$folder = $vault.DocumentService.GetFoldersByFileMasterId($file.MasterId)

foreach ($attach in $fileAssoc){
    if($file._Extension -eq "idw" -and $attach._Extension -eq "pdf"){
        $vault.DocumentService.DeleteFileFromFolderUnconditional($attach.MasterId,$folder.Id)      
    }
    elseif($file._Extension -eq "ipt" -and $attach._Extension -in @("SAT","DXF")){
        #$vault.DocumentService.DeleteFileFromFolderUnconditional($attach.MasterId,$folder.Id)
        $vault.DocumentService.DeleteFileFromFolder($attach.MasterId,$folder.Id)
    }
}

catch{
    Write-Host "Current user has no permission to delete files, please contact your administrator"
}


$NetworkPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\Logstrup\MockedNetwork\"
$FileNameWithExtension = "Copy of PART-BOX-0003.idw.pdf"
$destinationFile = Join-Path $NetworkPath $FileNameWithExtension
if(Test-Path $DestinationFile) { 
    Remove-Item -Path $destinationFile -Force
}

Test -Param ""


function Test {
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Param
    )
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
}