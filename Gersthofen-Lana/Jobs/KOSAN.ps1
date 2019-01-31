#import-module powerGate

Add-Log ">>> 'PDF > IFS' - '$($file._Name)'"
#$workingDirectory = "C:\Temp\$($file._Name)"
#$fileName = [System.IO.Path]::GetFileNameWithoutExtension($file._Name)


$jobs = $vault.JobService.GetJobsByDate(10000,[DateTime]::MinValue)
#$jobDetails = $jobs | Where-Object { $_.Id -eq $job.Id }
$fname = $file._Name.TrimEnd($file._Extension).TrimEnd('.').ToLower()
$stringIds = $job.candidatesIds

function get-CandidatesIds($StringIds){
    $newIdList = @()
    $candidateIDs = $StringIds -split '(/-/)'
    foreach($substring in $candidateIDs){
        if($substring -notlike "/-/"){
        $newIdList += [int]$substring
        }
    }
    $newIdList = $newIdList[0..($newIdList.Length-2)]
    return $newIdList
}
$candidates = get-CandidatesIds -StringIds $stringIds
try{
    Add-Log ">>> try for '$($file._Name)', fname is '$($fname)'"
    go to catc!
}catch{
    Add-Log ">>> Inside Catch for '$($file._Name)'"
    Update-VaultFile -File $file._FullPath -Status "Work in Progress"
    ADD-lOG "$($file._Name) is changed"
    $assocs = Get-VaultFileAssociations -File $file._FullPath
    Add-Log ">>> Catch: Assocs names: '$($assocs.Name)'"
    foreach($Id in $candidates){
        Add-Log ">>> Catch: release element '$($Id)'"
    }
    foreach($assoc in $assocs){
        ADD-lOG "$($assoc._Name); $($assoc.Id)"
        $assocVersions = $vault.DocumentService.GetFilesByMasterId($assoc.MasterId)
        foreach($Id in $candidates){
            if($Id -in $assocVersions.Id){
                Update-VaultFile -File $assoc._FullPath -Status "Work in Progress"
                ADD-lOG "$($assoc._Name) is changed"
			}
		}
	}
}
