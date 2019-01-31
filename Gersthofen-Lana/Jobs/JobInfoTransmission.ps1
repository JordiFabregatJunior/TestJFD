Add-Log ">>> Inside job for '$($file._Name)'"
$releasedData = $job.ReleasesInOperation 
$aaTest = $releasedData['FileName']
Show-Inspector
Add-log "$($aaTest)"
Add-log "$($job.JobType)"
Add-log "$($job.ReleasesInOperation.Filename)"
"###$($aaTest)" | out-file c:\temp\testJobInfo.txt
foreach($key in $releasedData.Keys){
    "$key - $($releasedData[$key])" | out-file c:\temp\testJobInfo.txt -Append
}
explorer.exe c:\temp\testJobInfo.txt

#$releasedInOperation  = @{FileName = "$($file._Name)"; JobType = "JobInfo"; FileId = "$($file.Id)"; MasterId = "$($file.MasterId)"}