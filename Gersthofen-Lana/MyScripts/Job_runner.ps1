<#$measuringPerformance = @{}
Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$filename = "ANH-001000410.pdf"
$vfile = Get-VaultFile -Properties @{"Name" = $filename}
$file = $vault.DocumentService.GetFileById($vFile.id)
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/TESTS/SPX")
$job = Add-VaultJob -Name "" -Description "-" -Parameters @{EntityClassId = "FILE"; EntityId = $vfile.Id} -Priority 10
####________NoTouching!_________#>







$vaultPath = '$/Designs/TESTS/Logstrup-TESTS/PART-FLA-0001.ipt'
$LocalPaTH = "C:\VaultJFD\2019-C-10-E-JFD\Designs\TESTS\Logstrup-TESTS\PART-FLA-0001.ipt"
$file = Add-VaultFile -From $LocalPaTH -to $vaultPath -FileClassification 'DesignRepresentation'


$filename = "PART-FLA-0002.ipt"

$vfile = Get-VaultFile -Properties @{Name = $filename}
$assocs = Get-VaultFileAssociations -File $vfile._FullPath

$file = $vault.DocumentService.GetFileById($vFile.id)

$Number = "100002"
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/Inventor/Test-Related-IDW")
$sourceFiles = $vault.DocumentService.GetLatestFilesByFolderId($folder.Id,$false)
$file = Add-VaultFile -From "$/Designs/Folder-Tests" -To "$/PowerVaultTestFiles/pV_7.test"


$filename = "Draw-0022.idw"
$file = Get-VaultFile -Properties @{"Name" = $filename}

$releasedData  = @{FileName = "$($file._Name)"; JobType = "JobInfo"; FileId = "$($file.Id)"; MasterId = "$($file.MasterId)"}
"###" | out-file c:\temp\testJobInfo.txt
foreach($key in $releasedData.keys){
    Write-HOst "$($Key)", $releasedData[$key]
    "$key - $($releasedData[$key])" | out-file c:\temp\testJobInfo.txt -Append
}
explorer.exe c:\temp\testJobInfo.txt

	foreach($sFile in $sFiles){
		$file = $sFile.FileObject.Name
		$order = $sFile.Level
		"$order - $file" | out-file c:\temp\sortedFiles.txt -Append
	}
[string]$candidates = ''
$fileIds = @(123,24124,231233,41243)
$newIdList = @()
foreach($Id in $fileIds){
    $candidates += $id.toString() + '-' 
}

$split = $candidates -split '(-)'

foreach($substring in $split){
    if($substring -notlike "-"){
    $newIdList += [int]$substring
    }
}
$newIdList = $newIdList[0..($newIdList.Length-2)]

$file

function Get-candidatesToRelease($files) {
	[string]$candidatesIds = ''
	foreach($file in $files){
        $candidatesIds += $File.id.toString() + '/-/' 
		if(@("Design Approval","Minor revision", "Work In Progress", "For Review") -contains $file._OldState  -and $file.State -eq "Released"){
			$candidatesIds += $id.toString() + '/-/' 
		}
	}
	return $candidatesIds
}

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
$stringIds = Get-candidatesToRelease -Files $files
$candidates = get-CandidatesIds -StringIds $stringIds


$filenames = @(
		'100018.idw'		
		'ASSY-0018.iam'		
		'PART-Part-011.ipt'			
)
$files =@()
foreach($filename in $filenames){
    $files += Get-VaultFile -Properties @{"Name" = $filename}
}

$candidatesIds = Get-candidatesToRelease -Files $files
$candidatesIds
$filename = '100018.idw'	
$file = Get-VaultFile -Properties @{"Name" = $filename}

$assocs = Get-VaultFileAssociations -File $file._FullPath
	foreach($assoc in $assocs){
        $assoc = $assocs[0]
        ADD-lOG "$($assoc._Name); $($assoc.Id)"
        $fileVersions = $vault.DocumentService.GetFilesByMasterId($assoc.MasterId)
        foreach($Id in $candidates){
            if($Id -in @(30360, 34095)$fileversions.Id.GetType(){
                $toUnrelease = $true
            }
        }
		if($toUnrelease){
            Update-VaultFile -File $assoc._FullPath -Status "Work in Progress"
            ADD-lOG "$($assoc._Name) is changed"
		}
