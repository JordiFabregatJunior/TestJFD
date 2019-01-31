Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$filename = "PART-BOX-0003.idw"
$filename = "PartForPEventsTesting.idw"
$vDraw = Get-VaultFile -Properties @{"Name" = $filename}
$Draw = $vault.DocumentService.GetLatestFileByMasterId($vDraw.MasterId)
$filename = "PartForPEventsTesting.ipt"
$vPart = Get-VaultFile -Properties @{"Name" = $filename}
$Part = $vault.DocumentService.GetLatestFileByMasterId($vPart.MasterId)
$Characteristics = @{
    "PartVerNum" = $Part.VerNum
    "PartMaxCkInVerNum" = $Part.MaxCkInVerNum
    "DrawVerNum" = $Draw.VerNum
    "DrawMaxCkInVerNum" = $Draw.MaxCkInVerNum
} | Out-GridView
[array]$files = @($vDraw, $vPart)
[array]$fileCollection = @() 
foreach($file in $files){
    $fileCollection +=  $vault.DocumentService.GetFilesByMasterId($file.MasterId)    
}
foreach($fileVersion in $fileCollection){
    Write-host "$($fileVersion.Name), version: $($fileVersion.VerNum), CreateUserName: $($fileVersion.CreateUserName)"   
}
$MaxFile = $fileCollection.First

    Check-File -File $FileLatestVersion -CurrentUserId $currentUserId
function Check-File($File){
    if ($currentState -eq "Work in Progress" -and $newState -eq "Released"){
        if($File.CreateUserId -eq $currentUserId){
            Add-VaultRestriction -EntityName $file._Name -Message "File $($file._Name) cannot be reviewed and released by the same person"
            return
        }
    }    
}

$currentUserId = $vaultConnection.WebServiceManager.SecurityService.SecurityHeader.UserId
$currentUserId = $vaultConnection.UserId
#$NewFiles = $updateFileStates.CurrentTransaction.NewStates
foreach($vfile in $files){
    $FileLatestVersion = $vault.DocumentService.GetLatestFileByMasterId($vfile.MasterId)  
    if ($file._State -eq "Work in Progress" -and $vfile._NewState -eq "Released"){
        if($file.CreateUserId -eq $currentUserId){
            Add-VaultRestriction -EntityName $vfile._Name -Message "File $($vfile._Name) cannot be reviewed and released by the same person"
            return
        }
    }    
}