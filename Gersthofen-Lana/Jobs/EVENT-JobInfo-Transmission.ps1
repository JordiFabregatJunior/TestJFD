#Register-VaultEvent -EventName UpdateFileStates_Post -Action 'PostFileStateChange'

function PostFileStateChange($files){
    $releasedInOperation = @()
    $priority = 10
    foreach($file in $files){
        $releasedInOperation += @{FileName = "$($file._Name)"; JobType = "JobInfo"; FileId = "$($file.Id)"; MasterId = "$($file.MasterId)"}
        Add-VaultJob -Name "JobInfoTransmission" -Description "'$($file._Name)' - JobInfoTransmission" -Priority $priority -Parameters @{"EntityClassId"="File";"EntityId"=$file.Id;"EntityMasterId"=$file.MasterId; "ReleasesInOperation" = $releasedInOperation }				
    }<#
    foreach($file in $files){
        $lfcDef = $file._LifeCycleDefinition   
        if($lfcDef -eq "Simple Release Process" -and $file._Extension -in @("dwg","idw","ipt", "iam") -and $file._State -eq "Work in Progress" -and $file._NewState -eq "Released"){
            Add-VaultJob -Name "JobInfoTransmission" -Description "'$($file._Name)' - JobInfoTransmission" -Priority $priority -Parameters @{"EntityClassId"="File";"EntityId"=$file.Id;"EntityMasterId"=$file.MasterId; "ReleasesInOperation" = $releasedInOperation }				
        }
    }#>
}