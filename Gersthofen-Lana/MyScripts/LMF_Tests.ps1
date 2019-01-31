<#$measuringPerformance = @{}
Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$filename = "ANH-001000410.pdf"
$vfile = Get-VaultFile -Properties @{"Name" = $filename}
$file = $vault.DocumentService.GetFileById($vFile.id)
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/TESTS/SPX")
$job = Add-VaultJob -Name "" -Description "-" -Parameters @{EntityClassId = "FILE"; EntityId = $vfile.Id} -Priority 10
####________NoTouching!_________#>

$CSV = @()

$FilenameIPT= "PART-Part-010.ipt"
$FilenameIDW= "PART-Part-010.idw"
$filenameCopyIPT= "Copy of PART-Part-010.ipt"
$filenameCopyIDW = "Copy of PART-Part-010.idw"

$ipt = Get-VaultFile -Properties @{Name = $FilenameIPT}
$idw = Get-VaultFile -Properties @{Name = $FilenameIDW}
$Copyipt = Get-VaultFile -Properties @{Name = $filenameCopyIPT}
$Copyidw = Get-VaultFile -Properties @{Name = $filenameCopyIDW}					
$IPTMasterID = $Copyipt.MasterId
$IDWMasterId = $Copyidw.MasterId

update-data -IDWMasterId $IDWMasterId -IPTMasterID $IPTMasterID  -CSV $CSV

function update-data($IDWMasterId, $IPTMasterID, $CSV){
    $logsPath = 'C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\LMF\Logs.csv'
    $idwAPIAllVersions = $vault.DocumentService.GetFilesByMasterId($IDWMasterId)
    $iptAPIAllVersions = $vault.DocumentService.GetFilesByMasterId($IPTMasterID)    
    foreach($Version in $idwAPIAllVersions){
        $idw = Get-VaultFile -FileId $Version.Id
        $idwAPI = $vault.DocumentService.GetFileById($idw.Id)
        $CSV += [PSCustomObject]@{'Date' = $idwAPI.CkInDate; 'Id/MasterId' = "$($idw.Id) / $($idwAPI.MasterId)";'CreateUserAPI' = $idwAPI.CreateUserName; 'CreatedBy' = $idw.'Created By'; 'Initial Approver' = $idw.'Initial Approver'; 'Version' = $idwAPI.VerNum; 'Name' = $idwAPI.Name;'VersionState' = $idw.'State (Historical)'; 'Comments' = $idw.comment; 'EngApprovedBy' = $idw.'Engr Approved By'}
    }
    $CSV | Export-Csv -Path $logsPath -Delimiter ';' -NoTypeInformation -ErrorAction SilentlyContinue
    explorer.exe $logsPath
    $xl=[Runtime.InteropServices.Marshal]::GetActiveObject("Excel.Application")
    $xl.Workbooks.Activate
    $xl.ActiveWorkbook.Worksheets("Logs").Columns("A:I").AutoFit
}

$filenameIPT = "PART-Part-010.ipt"
$filenameIDW = "PART-Part-010.idw"
$ipt = Get-VaultFile -Properties @{Name = $filenameIPT}
$idw = Get-VaultFile -Properties @{Name = $filenameIDW}
$OriginalProps = @{ipt = "MasterId: $($ipt.MasterId), Id: $($ipt.Id)"; idw = "MasterId: $($idw.MasterId), Id: $($idw.Id)"}

$idwAPI = $vault.DocumentService.GetFileById($idw.Id)
$idwAPIAllVersions = $vault.DocumentService.GetFilesByMasterId($idwAPI.MasterId)
$idwLatestFileVersion = $vault.DocumentService.GetLatestFileByMasterId($idwAPI.MasterId)


$CopyProps = @{ipt = "MasterId: $($Copyipt.MasterId), Id: $($Copyipt.Id)"; idw = "MasterId: $($Copyidw.MasterId), Id: $($Copyidw.Id)"}
$OriginalProps, $CopyProps

$FilenameCopyIPT = "Copy of PART-Part-010.ipt"
$filenameCopyIDW = "Copy of PART-Part-010.idw"

$Copyipt = Get-VaultFile -Properties @{Name = $filenameCopyIPT}
$Copyidw = Get-VaultFile -Properties @{Name = $filenameCopyIDW}
$CopyidwAPI = $vault.DocumentService.GetFileById($Copyidw.Id)
$Files = $vault.DocumentService.GetFilesByMasterId($CopyidwAPI.MasterId) #$CopyidwAPIAllVersions
$LatestFileVersion = $vault.DocumentService.GetLatestFileByMasterId($CopyidwAPI.MasterId)  #CopyidwLatestFileVersion


function Get-LastUser($Files,$LatestFileVersion){
    $LastVersion = $LatestFileVersion.MaxCkInVerNum
    if($LastVersion -le 2){
        return $LatestFileVersion.CreateUserId
    }
    for($i =0; $i -lt $LastVersion; $i++){
        $Ver = $LastVersion - $i
        $fileVer = $Files | Where-Object { $_.VerNum -eq $ver}
        $vfileVer = Get-VaultFile -FileId $fileVer.Id
        if($ver -lt 2){
            return $fileVer.CreateUserId
        }
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
            $LastStateChangeUser = Get-LastUser -Files $Files -LatestFileVersion $LatestFileVersion
            if($lfcDef -eq "Simple Release Process" -and $vfile._Extension -in @("dwg","idw")){
                if ($vfile._State -eq "Work in Progress" -and $vfile._NewState -eq "Released"){
                    Show-Inspector
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