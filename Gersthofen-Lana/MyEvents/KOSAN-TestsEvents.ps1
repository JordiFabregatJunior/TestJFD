Import-Module "C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault.Custom\addinVault\IfsCommunication.ps1"

#Register-VaultEvent -EventName UpdateFileStates_Post -Action 'PostFileStateChange'


function ComputeDepth($myFile,$myFiles,$level)
{
	$level++
	$parents = $myFiles | Where-Object { $_.Children -contains $myFile.MasterId }
	if($parents -ne $null){
		$levels = @()
		foreach($parent in $parents){
			$levels += ComputeDepth -myFile $parent -myFiles $myFiles -level $level
			
		}
		$levels = $levels | Sort-Object -Descending # | Select-Object -First
		$level = $levels[0]
	}
	return $level
}

function GetSortedFiles($files)
{
	$assocs = $vault.DocumentService.GetFileAssociationsByIds($files.Id, "None", $false, "Dependency", $false, $false, $false)
	$myFiles = @()
	
	for($i = 0;$i -lt $files.Count;$i++){
		$file = $files[$i]
		$myfile = New-Object psobject -Property @{MasterId=$file.MasterId;FileObject=$file;Level=0;Name=$file.Name;Children=@()}
		if($assocs[$i].FileAssocs -ne $null){
			$myfile.Children = $assocs[$i].FileAssocs.cldFile.MasterId
		}
		$myFiles += $myfile
	}
	
	foreach($myFile in $myFiles){
		$myFile.Level = ComputeDepth -myFile $myFile -myFiles $myFiles -level 0
	}
	foreach($myFile in $myFiles){ #set drawings at same level as model
		if($myFile.Name.EndsWith(".idw")){
			if($myFile.Children -ne $null){
				$child = $myFile.Children[0]
				$child = $myFiles | Where-Object { $_.MasterId -eq $child }
				if($child -ne $null){
					$myFile.Level = $child.Level 
				}
			}
		}
	}
	$sf = $myFiles | Sort-Object -Property Level -Descending
	return $sf
}
function Get-CandidatesToRelease($files) {
	[string]$candidatesIds = ''
	foreach($file in $files){
		if(@("Design Approval","Minor revision", "Work In Progress", "For Review") -contains $file._OldState  -and $file.State -eq "Released"){
			$candidatesIds += $File.Id.toString() + '/-/' 
		}
	}
	return $candidatesIds
}

function PostFileStateChange($files, $successful)
{

	if($successful -eq $fale){ return }
	$currentDomain = [AppDomain]::CurrentDomain
	$disable = $currentDomain.GetData("KC_DiableIfsJobs")
	$sFiles = GetSortedFiles -files $files	
	"###" | out-file c:\temp\sortedFiles.txt
	foreach($sFile in $sFiles){
		$file = $sFile.FileObject.Name
		$order = $sFile.Level
		"$order - $file" | out-file c:\temp\sortedFiles.txt -Append
	}
	
	$priority = 20
	$candidatesIds = Get-CandidatesToRelease -Files $files
	"$($candidatesIds)" | out-file c:\temp\sortedFiles.txt -Append
	explorer.exe c:\temp\sortedFiles.txt
	foreach($sFile in $sFiles){
		$file = $sFile.FileObject
		$order = $sFile.Level
		
		$partNumber = $file.'Part Number'
		if($partNumber -ne $null){ $partNumber = $partNumber.ToUpper() }
		<#
		$IfsPart = Get-ERPObject -EntitySet "Parts" -Key @{ partNumber=$partNumber } -Expand @('documentLinks')
		if($file._OldState -eq "Released" -and $file.State -eq "Design Process")
		{
			if(@("ipt","iam") -contains $file._Extension)
			{
				$ifsUser = $vaultConnection.UserName.TrimStart("KC\").ToUpper()
				$newRevItem = Add-ERPObject -EntitySet "Parts" -Properties @{partNumber=$partNumber;revision_comment=$file._Comment;standardNameId=$IfsPart.standardNameId;purchaseText=$IfsPart.purchaseText;note=$IfsPart.note;fndUser=$ifsUser}
			}
		}
		if($file._OldState -eq "Released" -and $file.State -eq "Minor revision")
		{
			if(@("ipt","iam") -contains $file._Extension)
			{
				if($IfsPart -ne $null){
					$ifsUser = $vaultConnection.UserName.TrimStart("KC\").ToUpper()
					$update = Update-ERPObject -EntitySet "Parts" -Keys @{partNumber=$partNumber} -Properties @{status='Released';fndUser=$ifsUser;revision_comment=$file._Comment}
				}
			}
		}#>
		if(@("Design Approval","Minor revision", "Work In Progress") -contains $file._OldState  -and $file.State -eq "Released")
		{
			if($disable){ continue }
			$fname = $file._Name.TrimEnd($file._Extension).TrimEnd('.').ToLower()
			if(@("ipt","iam") -contains $file._Extension){
				$drawing = $files | Where-Object { $_.Name.ToLower() -eq "$fname.idw" -or $_.Name.ToLower() -eq "$fname.dwg"  }
				if($drawing -ne $null){
					#[System.Windows.Forms.MessageBox]::Show("$($file._Name) has drawing $($drawing._Name), so skip...")
					continue #if in the list of to be processed files, there is a drawing, then the model can be skipped.
				}
			}
			if(@("idw","dwg") -contains $file._Extension){
				$Ifsdoc = $IfsPart.documentLinks | Where-Object { $_.docClass -eq $file.'Document class' -and $_.docRev -eq $file.Revision }
				if($Ifsdoc -ne $null -and $Ifsdoc.status -eq "Released"){
					[System.Windows.Forms.MessageBox]::Show("IFS document $partNumber is released. No job queued for file '$($file._Name)'. IFS document will not be updated and item and part will not be released in IFS!","IFS document is released","OK","Warning")
					continue
				}
			}
			if(@("ipt","iam") -contains $file._Extension -and $IfsPart.status -eq "Released"){
				[System.Windows.Forms.MessageBox]::Show("IFS part $partNumber is released. No job queued for file '$($file._Name)'","IFS part is released","OK","Warning")
				continue
			}

			#[System.Windows.Forms.MessageBox]::Show("queue job for $($file._Name) - $partNumber")
			if(@("idw","dwg") -contains $file._Extension) {
				if(@("$fname.idw", "$fname.dwg") -contains $file._Name.ToLower() -and $fname -match "^[0-9]{6}$"){
					Add-VaultJob -Name "KOSAN" -Description "'$($file._Name)' - Create PDF and upload to IFS" -Priority $priority -Parameters @{"EntityClassId"="File";"EntityId"=$file.Id;"EntityMasterId"=$file.MasterId; "candidatesIds" = $candidatesIds }
					$priority++
				}
			}
			if(@("ipt","iam") -contains $file._Extension){
				Add-VaultJob -Name "KOSAN" -Description "'$($file._Name)' - release model in IFS" -Priority $priority -Parameters @{"EntityClassId"="File";"EntityId"=$file.Id;"EntityMasterId"=$file.MasterId; "candidatesIds" = $candidatesIds }				
				$priority++
			}
		}
	}
	$states = $files.State
	if($disable -and $states -contains "Released"){
		[System.Windows.Forms.MessageBox]::Show("IFS jobs have been enabled again")
		$currentDomain.SetData("KC_DiableIfsJobs", $false)
	}
}

#Register-VaultEvent -EventName UpdateFileStates_Restrictions -Action 'FileStateChangeRestriction'

function FileStateChangeRestriction($files)
{
	$currentDomain = [AppDomain]::CurrentDomain
	$disable = $currentDomain.GetData("KC_DiableIfsJobs")
	$states = $files._NewState
	if($disable -and $states -contains "Released"){
		$answer = [System.Windows.Forms.MessageBox]::Show("IFS jobs have been temporarely disabled! The liefcycle transition will not queue IFS jobs. Do you want to continue this way?","IFS jobs diabled","YesNo")
		if($answer -eq "no") { 
			Add-VaultRestriction -EntityName "IFS Jobs" -Message "Operation stopped by you."
		 }
	}
	#Add-VaultRestriction -EntityName "stop" -Message "stop"
	$jobs = $vault.JobService.GetJobsByDate(10000,[DateTime]::MinValue)
	$hasJobs = $false
	$jobs = $jobs | Where-Object { @("Ready","Running") -contains $_.StatusCode }
	$masterIds = @()
	foreach ($job in @($jobs))
	{
		foreach ($p in $job.ParamArray)
		{
			if($p.Name -eq "EntityMasterId") { $masterIds += $p.Val }
		}
	}
	
	foreach($file in $files)
	{
		if($masterIds -contains $file.MasterId) { 
			Add-VaultRestriction -EntityName $file.Name -Message "A job for '$($file.Name)' is in the job queue!!! You can not change the state while a job is queued for this file. Please try again later..."
		}
		$partNumber = $file.'Part Number'
		if($partnumber -like "*wrap*") { continue }
		if($partnumber -like "*sub*") { continue }
		if($partnumber -like "*phantom*") { continue }
		if($partNumber -ne $null){ $partNumber = $partNumber.ToUpper() }
		$IfsPart = Get-ERPObject -EntitySet "Parts" -Key @{ partNumber=$partNumber } -Expand @("documentLinks") 
		if("iam" -eq $file._Extension -and $file._NewState -eq "Released"){
			
			if($IfsPart -eq $null){
				if($partNumber -notmatch "^[0-9]{6}$"){ #6 digits number
					$answer = [System.Windows.Forms.MessageBox]::Show("The part number '$partNumber' does not exist in IFS. Shall this be ignored?","Missing part number","YesNo")
					if($answer -eq "yes") { continue }
				}
				Add-VaultRestriction -EntityName $file.Name -Message "IFS item does not exist!"
			}
            else{
				
                $bomObject = Get-ERPObject -EntitySet "BomLists" -Key @{ partNumber=$IfsPart.PartNumber;partRevision=$IfsPart.PartRevision }
			    if($IfsPart.Status -ne "Released" -and $bomObject -eq $null){
					$answer = [System.Windows.Forms.MessageBox]::Show("The BOM '$partNumber' does not exist in IFS. Shall this be ignored?","Missing BOM","YesNo")
					if($answer -eq "yes") { continue }
				    Add-VaultRestriction -EntityName $file.Name -Message "IFS BOM does not exist!"
			    }
            }
		}
		if(@("idw","dwg") -contains $file._Extension -and $file._NewState -eq "Released"){
			$fileDocClass = $file.'Document class'
			$fileDocClassIsEmpty = $fileDocClass -eq "" -or $fileDocClass -eq $null
			if($fileDocClassIsEmpty -and $IfsPart -eq $null){ 
				Add-VaultRestriction -EntityName $file.Name -Message "'Document class' is empty, and IFS part does not exist. Please set the 'Document class' manually!"
				continue
			}
			if($fileDocClassIsEmpty){
				$docClasses = @($IfsPart.documentLinks.docClass)
				if($docClasses -contains 'T1' -and $docClasses -contains 'TEGN_KON'){
					Add-VaultRestriction -EntityName $file.Name -Message "'Document class' is empty, and too many classes have been found in IFS. Please set manually!"
				}
				elseif($docClasses -contains 'T1') {
					Update-VaultFile -File $file._FullPath -Properties @{'Document class'='T1'} -Comment "Automatically set the 'Document class' to T1"
				}
				elseif($docClasses -contains 'TEGN_KON') {
					Update-VaultFile -File $file._FullPath -Properties @{'Document class'='TEGN_KON'} -Comment "Automatically set the 'Document class' to TEGN_KON"
				}
				else{
					Add-VaultRestriction -EntityName $file.Name -Message "'Document class' ist empty, and no class could be found in IFS. Plase set manually!"
				}
			}
		}
	}
} 
