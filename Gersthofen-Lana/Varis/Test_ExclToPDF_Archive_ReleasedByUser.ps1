#WORKS PROPERLY (mail working with outlook but not ohter domains tested)



# This jobs exports a xls file to pdf renamed with: filename + timestamp + the name of the user who put it to review it.
# But firstly, it checks if it is allowed to do that (Managers Group)
# After that the pdf is 1. archived to local vault folder
# When archived, vault excel state is updated to released
# NOte: Archive folder path is in the same vault local path, adding a folder called Archive; therefore, it can only be ran in the Final Client Machine
# Note: The pdf generated is generated into a temporary working folder and then cleaned up



###_______________________SUPPORT FUNCTIONS

function Start-Outlook {
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    if($Global:ApplicationOutlook) { return $Global:ApplicationOutlook }
    $Global:ApplicationOutlook = New-Object -ComObject Outlook.Application
    Start-Sleep -Seconds 3
    return $Global:ApplicationOutlook 
}
function Close-Outlook {
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    if(-not $Global:ApplicationOutlook) { return }
    $Global:ApplicationOutlook.Quit()
    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$Global:ApplicationOutlook)
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    Start-Sleep -Seconds 1
}


function SendMailOutlook {
    param(
        [Parameter(Mandatory=$true)][array]$To,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Subject,
        $HTMLBody,
        [switch]$AppendDetails = $false
    )
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"

    $Global:ApplicationOutlook = Start-Outlook
    $mail = $Global:ApplicationOutlook.CreateItem([Microsoft.Office.Interop.Outlook.OlItemType]::olMailItem)

    $mail.To = "$($To)"
    $mail.Subject = $Subject

    if($AppendDetails) {
        $HTMLBody += "<br />ValidUser: {0} <br />Username: {1}" -f $IsValidUser, $userName
    }
    $mail.HTMLBody = $HTMLBody

    $mail.Send()
}




function Check_if_User_in_Group{
    param(
    [string]$groupName,
    [string]$currentUser
    )
    $group = $vault.AdminService.GetGroupByName($groupName)
    $groupInfo = $vault.AdminService.GetGroupInfoByGroupId($group.Id)
    $groupInfo.Users | ForEach-Object { [array]$users += $_ }
    foreach ($user in $users){
        if ($user.Name -ieq $currentUser){
            return $true
        }
    }
    return $False
}

function Cleanup {
    param(
    [System.IO.DirectoryInfo]$Path
    )
        Write-Host "$($Path.FullName)"
        Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
        if(-not $Path) { return $true}		   
        if(Test-Path $Path.FullName -ErrorAction SilentlyContinue) {
            Remove-Item -Path $Path.FullName -Recurse -Force -ErrorAction SilentlyContinue
            if(Test-Path $Path.FullName -ErrorAction SilentlyContinue) {
                return $false
            }
        }
        return $true
}

function Start-Excel {
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    if($Global:ApplicationExcel) { return $Global:ApplicationExcel }
    
    $processExcel = Get-Process -Name EXCEL -ErrorAction SilentlyContinue
    foreach($process in $processExcel) { $process.Kill() }
    Write-Host "Excel cleaned, so process can start"

    $Global:ApplicationExcel = New-Object -ComObject Excel.Application

    Start-Sleep -Seconds 2
    $Global:ApplicationExcel.Visible = $False
    $Global:ApplicationExcel.DisplayAlerts = $false
    Write-Host "Excel already opened"
    return $Global:ApplicationExcel 
}
function Close-Excel {
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    if(-not $Global:ApplicationExcel) { return }

    if($Global:ApplicationExcel.ActiveWorkbook) {
        $saveChanges = $false
        $Global:ApplicationExcel.ActiveWorkbook.Close($saveChanges)
    }

    $Global:ApplicationExcel.Quit()
    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$Global:ApplicationExcel)
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    Remove-Variable -Name ApplicationExcel -Scope:Global  
    Start-Sleep -Seconds 1
}
function Export-XlsToPdf {
param(
	[System.IO.FileInfo]$InputObject = "C:\Temp\Test_xlsToPDF\FINAL QCP.xlsx",
	[System.IO.FileInfo]$Path = "C:\Temp\Test_xlsToPDF\FINAL QCP.pdf"
)
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    
    $Global:ApplicationExcel = Start-Excel

    $filename = $InputObject.FullName
    $updateLinks = 3
    $readOnly = $true

	$Workbook = $Global:ApplicationExcel.Workbooks.Open($filename,	$updateLinks,	$readOnly)
    
    $destinationFilename = $Path.FullName
    $quality = [Microsoft.Office.Interop.Excel.XlFixedFormatQuality]::xlQualityStandard
    $includeDocProperties = $true
    
    if($InputObject.Name.Contains("QCP") -and ($Workbook.Worksheets.Count -gt 1)) {
        $Workbook.Worksheets | select -Last ($Workbook.Worksheets.Count - 1) | foreach {
            $_.Visible = $false
        }
    }
    $Workbook.ExportAsFixedFormat([Microsoft.Office.Interop.Excel.XlFixedFormatType]::xlTypePDF, $destinationFilename, $quality, $includeDocProperties)

    if( Test-Path $Path.FullName ) { return Get-Item $Path.FullName }
    return $null
}

function Copy-File {
    param (
        $path,
        $destination    
    )
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($path)
    $fileExtension = [System.IO.Path]::GetExtension($path)
    $datetimestamp = Get-Date -UFormat %y%m%d_%H%M
    $filename = $filename + '_' + $userName + '_' + $datetimestamp + $fileExtension
    $destinationFile = Join-Path $destination $filename
    if(-not (Test-Path $destination))
    {
        New-Item -Path $destination -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $path -Destination $destinationFile
}

# Import-Module "C:\ProgramData\coolOrange\powerJobs\Jobs\Support_Functions.psm1"



###________MAIN________###

#$filename_Extension = "FINAL QCP.xlsx"
#$file = Get-VaultFile -Properties @{Name = $filename_Extension}

##__Checking_that_the_user_has_rights_to_do_it

Write-Host "Getting releaser user"
$jobQueue = $vault.JobService.GetJobsByDate(1000,[DateTime]::MinValue)
$currentJob = $jobQueue | Where-Object {$_.Id.Equals($powerJobs.Job.Id)}
$JobUser = $vault.AdminService.GetUserByUserId($currentJob.CreateUserID)
$userName = $JobUser.Name
$IsValidUser = Check_if_User_in_Group -GroupName 'Administrators' -currentUser $userName
if(-not($IsValidUser)){
    Write-Host "Current user $($userName) is not allowed to release the file"
    throw "Job failed"
} elseif($IsValidUser){
     Write-Host "Current user $($userName) is allowed; going on!!!"
}

$workingDirectory = "C:\Temp\Test_xlsToPDF"
Cleanup -Path $workingDirectory
if( -not (Test-Path $workingDirectory -ErrorAction SilentlyContinue)) {
        $null = New-Item -Path $workingDirectory -ItemType Directory -Force
}
$downloadedFiles = Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory
$file = $downloadedFiles | select -First 1
$filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file._Fullpath)
$fileExtension = [System.IO.Path]::GetExtension($file._Fullpath)
$PDFPath = $workingDirectory + '\' + $filenameWithoutExtension + '.pdf'
$inputFilePath = Join-Path $workingDirectory $file._Name

if($fileExtension -ieq '.xlsx'){
    Export-XlsToPdf -InputObject $inputFilePath -Path $PDFPath
}
else{
    Write-Host "The file $($file._Name) is not '.xlsx', sorry...!"
}
Close-Excel
$localVault = 'C:/VaultJFD/2019-C-10-E-JFD'
$archiveFolder = $localVault + $file.path.Remove(0,1) + '/Archive'
Copy-file -Path $PDFPath -Destination $archiveFolder

##__UpdateState
$currentState = $file._State
$ReleasedState = "Released"
$updatedFile = Update-VaultFile -File $file.'Full Path' -Status $ReleasedState
Write-Host "Updating $($file.Name) state from $($currentState) to $($ReleasedState)"

##__Sending notification mail through Outlook
if($updatedFile){
    $Result = "Released"
}
Elseif(-not($updatedFile)){
    $Result = "Not released, something went wrong"
}
$Task = "Job successfully done"
$body = "Task: {0} Result: {1}" -f $Task, $Result
$To = "correu.brossa.6@gmail.com"

##__SendingInformingMail__OUTLOOK
SendMailOutlook -To $To -Subject "$($filenameWithoutExtension)" -HTMLBody $body -AppendDetails


<#
##__SenfingInformingMail__AllMailDealers
#SendMail -To $Global:MailRecipients -Subject "Alert" -HTMLBody $message -Process $global:process -AppendDetails
$from = "jordi.fabregat.domenech@coolorange.com"
$to = "correu.brossa.6@gmail.com"
$subject = "Released test"
#$subject = "Released $($file.Name)"
#$body = "The $($file.Name) has been released by $($userName) and archived to $($archiveFolder). Attached archived pdf file."
$body = "The  has been released by  and archived to. Attached archived pdf file."
$smtp = "coolorange-com.mail.eo.outlook.com"
$passwd = ConvertTo-SecureString -AsPlainText "jfd6CO?-" -Force
$cred = new-object Management.Automation.PSCredential $from, $passwd
$sendattachment = $False
Send-MailMessage -To $to -From $from -Subject $subject -Body $body -SmtpServer $smtp -Credential $cred 

<#  
if($sendattatchment -eq $true){
    Send-MailMessage -To $to -From $from -Subject $subject -Body $body -SmtpServer $smtp -Credential $cred -Attachments "$($destinationFile)"
}
else{
    Send-MailMessage -To $to -From $from -Subject $subject -Body $body -SmtpServer $smtp -Credential $cred
}#>


##__CleaningWorkingDirectory
Cleanup -Path $workingDirectory

Write-Host "Job is finsihed!"