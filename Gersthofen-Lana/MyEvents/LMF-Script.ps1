#Register-VaultEvent -EventName UpdateFileStates_Restrictions -Action 'Check-FourEyes'

function Get-LastUser($Files,$LatestFileVersion){
    $LastVersion = $LatestFileVersion.MaxCkInVerNum
    for($i =0; $i -lt $LastVersion; $i++){
        $Ver = $LastVersion - $i
        $fileVer = $Files | Where-Object { $_.VerNum -eq $ver}
        if($ver -eq 1){
            return $fileVer.CreateUserId
        }
        $vfileVer = Get-VaultFile -FileId $fileVer.Id
        $filePreVer = $Files | Where-Object { $_.VerNum -eq $($ver-1)}
        $vfilePreVer = Get-VaultFile -FileId $filePreVer.Id
        If($vfileVer.'_State(Ver)' -ne $vfilePreVer.'_State(Ver)'){
            return $fileVer.CreateUserId
        }
    }
}

function Check-FourEyes ($files){
    $currentUserId = $vaultConnection.UserId
    foreach($vfile in $files){
        $lfcDef = $vfile._LifeCycleDefinition
        if($lfcDef -in @("Artaker flexibel", "Simple Release Process","Flexible Release Process")){
            $LatestFileVersion = $vault.DocumentService.GetLatestFileByMasterId($vfile.MasterId)
            $fileAllVersions = $vault.DocumentService.GetFilesByMasterId($vfile.MasterId)
            $LastStateChangeUser = Get-LastUser -Files $fileAllVersions -LatestFileVersion $LatestFileVersion
            if($lfcDef -eq "Simple Release Process" -and $vfile._Extension -in @("dwg","idw")){
                if ($vfile._State -eq "Work in Progress" -and $vfile._NewState -eq "Released"){
                    if($LastStateChangeUser -eq $currentUserId){
                        Add-VaultRestriction -EntityName $vfile._Name -Message "Datei kann nicht von der gleichen Person geprüft und freigegeben werden!"
                    }
                }    
            } elseif ($lfcDef -eq "Artaker flexibel" -and $vfile._Extension -in @("dwg","idw")){
                if ($vfile._State -in @("Work in Progress", "Zu überprüfen") -and $vfile._NewState -eq "Freigegeben"){
                    if($LastStateChangeUser -eq $currentUserId){
                        Add-VaultRestriction -EntityName $vfile._Name -Message "Datei kann nicht von der gleichen Person geprüft und freigegeben werden!"
                    }
                }    
            }
        } else {
            return
        }
    }
}
<#
$filename = "Draw-0010.idw"
$file = Get-VaultFile -Properties @{"Name" = $filename}
Check-FourEyes -files $file
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/Logstrup-Tests")
$FileLatestVersion = $vault.DocumentService.GetLatestFileByMasterId($vfile.MasterId)
$fileData = @{
    "Filename" = $Filename
    "MasterID" = $vfile.MasterId
    "file.Id" =  $vfile.Id
    "FolderId" = $folder.Id
    "Versions" = $FileLatestVersion.MaxCkInVerNum
    "LatestId" = $FileLatestVersion.Id
}  |  Out-GridView


Write-Host "$($Files[19].VerNum -eq $ver)"
$vfileVersion = Get-VaultFile -FileId 28103
$LastVersion = $FileLatestVersion.MaxCkInVerNum
$Files = $vault.DocumentService.GetFilesByMasterId($vfile.MasterId)
for($i =0; $i -lt $LastVersion; $i++){
    $Ver = $LastVersion - $i
    $fileVer = $Files |�Where-Object { $_.VerNum -eq $ver}
    $vfileVer = Get-VaultFile -FileId $fileVer.Id
    $filePreVer = $Files |�Where-Object { $_.VerNum -eq $($ver-1)
    $vfilePreVer = Get-VaultFile -FileId $filePreVer.Id
    If($vfileVer.'_State(Ver)' -ne $vfilePreVer.'_State(Ver)'){
        return $fileVer.CreateUserId
    }
}#>