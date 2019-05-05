###___Tests Jossi

<#Import-Module PowerVault
Open-VaultConnection -Server "localhost" -Vault "VaultJFD" -user "Administrator"
$filename = "TestPDF.idw"
$file = Get-VaultFile -Properties @{"Name" = $filename}
$job = Add-VaultJob -Name "Jossi_PDF" -Description "Jossi PDF" -Parameters @{EntityClassId = "FILE"; EntityId = $file.Id} -Priority 10
#>



$latestFile = $vault.DocumentService.GetLatestFileByMasterId($File.MasterId)
$fileVersions = $vault.DocumentService.GetFilesByMasterId($File.MasterId)
$lastVersion = $latestFile.MaxCkInVerNum
for($i =0; $i -lt $lastVersion; $i++){
    $RevPropRequired = $false
    $Ver = $lastVersion - $i
    $fileVer = $fileVersions | Where-Object { $_.VerNum -eq $ver}
    $vfileVer = Get-VaultFile -FileId $fileVer.Id
    if($ver -eq 1){
        Write-Host "The file $($File) has not been changed of state yet. PDF job not triggered!"
    }
    $filePreVer = $fileVersions | Where-Object { $_.VerNum -eq $($ver-1)}
    $vfilePreVer = Get-VaultFile -FileId $filePreVer.Id    
    If($vfileVer.'_State(Ver)' -ne $vfilePreVer.'_State(Ver)'){
        If($vfileVer.'_State(Ver)' -eq 'Freigegeben' -and $vfilePreVer.'_State(Ver)' -eq 'Freigegeben Prototyp' ){
            $RevPropRequired = $true
        }
        return @($fileVer.CreateUserName, $fileVer.CreateDate, $RevPropRequired)
    }    
}





$hidePDF = $false
$workingDirectory = "C:\Temp\$($file._Name)"
$localPDFfileLocation = "$workingDirectory\$($file._Name).pdf"
$vaultPDFfileLocation = $file._EntityPath +"/"+ (Split-Path -Leaf $localPDFfileLocation)
$vaultNeutralPDFfileLocation = '$/Designs/TESTS/JOSSI' +"/"+ (Split-Path -Leaf $localPDFfileLocation)
$fastOpen = $file._Extension -eq "idw" -or $file._Extension -eq "dwg" -and $file._ReleasedRevision


$PropsByNum = @{
    1='KONSTRUKTEUR'
    2='ERSTELLUNGSDATUM'
    3='KONTROLLIERT VON'
    4='KONTROLLDATUM'
    5='GENEHM.DAT KONSTR.'
    6='KONSTR GEN VON'
    7='RevProtText'
}

$files = @()
$fileVersions = $vault.DocumentService.GetFilesByMasterId($file.MasterId)
foreach ($version in $fileVersions) {
    $file = get-vaultFile -FileId $version.Id 
    $files += $file
}

trace-PreviousState -File $file
function trace-PreviousState($File){
    $latestFile = $vault.DocumentService.GetLatestFileByMasterId($File.MasterId)
    $lastVersion = $latestFile.MaxCkInVerNum
    $fileVersions = $vault.DocumentService.GetFilesByMasterId($File.MasterId)
    for($i =0; $i -lt $lastVersion; $i++){
        $Ver = $lastVersion - $i
        $fileVer = $fileVersions | Where-Object { $_.VerNum -eq $ver}
        $vfileVer = Get-VaultFile -FileId $fileVer.Id
        if($ver -eq 1){
            Add-Log "The file $($File) has not been changed of state yet"
        }
        $filePreVer = $fileVersions | Where-Object { $_.VerNum -eq $($ver-1)}
        $vfilePreVer = Get-VaultFile -FileId $filePreVer.Id        
        return ($vfileVer.'_State(Ver)' -eq 'In Bearbei' -and $vfilePreVer.'_State(Ver)' -eq 'Work in Progress'
    }
}
