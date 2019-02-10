function Get-LinksInFolder ($Folder) {
	$linksOnFolder = $vault.DocumentService.GetLinksByParentIds($Folder.Id, "FILE")
	[array]$vaultFilesIdsWithLinks= @()
	foreach ($link in $linksOnFolder){
		if ($link.ToEntId -in $vaultFileIds){
			$vaultFilesIdsWithLinks += $link.ToEntId
		}
	}
	Return $vaultFilesIdsWithLinks
}

function Set-FilesInGui($Window, $Enable = $false) {
	$allFiles = $Window.FindName("FileView").ItemsSource
	$Window.FindName("FileView").ItemsSource = $null
	$allFiles | foreach { $_.TriggerJob = $Enable }
	$Window.FindName("FileView").ItemsSource = $allFiles
}
function Add-DrawingJobs($IDlistDrawsToBeUpdated){
    Write-Host "InsideAdd-drws: $($IDlistDrawsToBeUpdated.keys)"
    $IDlistDrawsToBeUpdated
	foreach($Extension in $IDlistDrawsToBeUpdated.Keys){
		foreach($Id in $IDlistDrawsToBeUpdated[$Extension]){
			if($Extension -eq 'pdf'){
				$3CCreatePDF = Add-VaultJob -Name "Sample.CreatePDF" -Description "Export drawing to PDF" -Parameters @{EntityClassId = "FILE"} -Priority 10 
			} elseif($Extension -eq 'dxf'){
				$3CCreateDXF = Add-VaultJob -Name "Sample.CreateDWG" -Description "Export drawing to DXF" -Parameters @{EntityClassId = "FILE"} -Priority 10 
			} elseif($Extension -eq 'dwg'){
				$3CCreateDWG = Add-VaultJob -Name "Sample.CreateDXF" -Description "Export drawing to DWG" -Parameters @{EntityClassId = "FILE"} -Priority 10 
			}
		}
	}
}

function Invoke-ButtonStartExport($Window, $Folder, $IDlistDrawsToBeUpdated) {
    Write-host "$($IDlistDrawsToBeUpdated.Keys), and values = $($IDlistDrawsToBeUpdated.Values)"
	if($Window.FindName("BtnTriggerJobs").content -eq 'Export'){
		$selectedIDWFiles = @(($Window.FindName("FileView").ItemsSource) | where { $_.TriggerJob })
		foreach ($IDWFile in $SelectedIDWFiles){
			$vault.DocumentService.AddLink($Folder.Id,"FILE",$IDWFile.Id,"")
		}
		[System.Windows.Forms.MessageBox]::Show("$($selectedIDWFiles.Count) files have been successfully exported!`n", "IDW / DWG Export - Success", "Ok", "Information") | Out-Null
	} else {
		Add-DrawingJobs -IDlistDrawsToBeUpdated $global:IDlistDrawsToBeUpdated
	}
	$Window.Close()
}

function Set-ButtonEvents($Window, $Folder, $IDlistDrawsToBeUpdated) {
	$global:window = $Window
	$global:Folder = $Folder
    $global:IDlistDrawsToBeUpdated = $IDlistDrawsToBeUpdated
	$Window.FindName("BtnTriggerJobs").add_Click({
		Invoke-ButtonStartExport -Window $global:window -Folder $global:Folder -IDlistDrawsToBeUpdated $global:IDlistDrawsToBeUpdated
	})
	$global:Window.FindName("BtnCancel").add_Click({
		$global:Window.Close()
	})
	$Window.FindName("BtnSelectAll").add_PreviewMouseLeftButtonDown({
		Set-FilesInGui -Window $global:Window -Enable $true
	})
	$Window.FindName("BtnUnselectAll").add_PreviewMouseLeftButtonDown({
		Set-FilesInGui -Window $global:Window -Enable $false
	})
}

function Get-DrawingFileIds ($fileIteration){
	$frgs = New-Object Autodesk.DataManagement.Client.Framework.Vault.Settings.FileRelationshipGatheringSettings
		$frgs.IncludeAttachments = $false
		$frgs.IncludeChildren = $true
		$frgs.IncludeRelatedDocumentation = $true
		$frgs.RecurseChildren = $true
		$frgs.IncludeParents = $true
		$frgs.RecurseParents = $false
		$frgs.DateBiased = $false
		$frgs.IncludeHiddenEntities = $false
		$frgs.IncludeLibraryContents = $false
		$ids = @()
		$ids += $fileIteration.EntityIterationId     
	$fal = $vaultConnection.FileManager.GetFileAssociationLites([int64[]]$ids, $frgs)

	#IDWs/DWG are always parents => Extract unique idw/dwg IDs:
	$parentFileIds = @()
	foreach ($assocLite in $fal){
		$parentFileIds += $assocLite.ParFileId
	}
	$UniqueParentIds = $parentFileIds | Select-Object -Unique
	#Extract only idws/dwgs (exclude ipn and others) + return array with them:
	$IDWIDs = @()
	foreach($parentId in $UniqueParentIds){
		$candidateFile = $vault.DocumentService.GetFileById($parentId)
		$parentExtension = [System.IO.Path]::GetExtension("$($candidateFile.Name)")
		if($parentExtension -in @(".idw", ".dwg")){
			$IDWIDs += $parentId
		}
	}
	return $IDWIDs
}

function Select-Attachments($Files, $Window){
    $AttachUpdateComment = 'Update Needed'
	$IDlistDrawsToBeUpdated = @{pdf = @(); dxf = @(); dwg=@()}
	$jobExtensions = @('pdf', 'dxf','dwg')
	foreach($file in $Files){	
		$drawCreateDate = $file._DateVersionCreated
		$attachments = Get-VaultFileAssociations -File $file._FullPath
		# Missing Attachments
		foreach($Extension in $jobExtensions){
			if($Extension -notin $attachments._Extension){
				$IDlistDrawsToBeUpdated[$Extension] += $file.Id
				[array]$IDs += $file.Id
			}
		}
		# Outdated Attachments
		foreach($attach in $attachments){
			if($attach._Extension -in @('dwg','pdf','dxf')){
				if($attach._DateVersionCreated -lt $drawCreateDate){
					$IDlistDrawsToBeUpdated[$attach._Extension] += $file.Id
					[array]$IDs += $file.Id
				}
			}
		}
		if($file.Id -in $IDs){
			$updateNeeded = $true
			Add-Member -InputObject $file -Name "NeedsAttachUpdate" -Value $true -MemberType NoteProperty
			Add-Member -InputObject $file -Name "AttachUpdateComment" -Value $AttachUpdateComment -MemberType NoteProperty
		}
	}
	if($updateNeeded){
		$Window.FindName("BtnTriggerJobs").Content = 'Update Attachments'
		$Window.FindName("TxtAllAttachStatus").Text = 'An attachment update is required before export'
	}
	return $IDlistDrawsToBeUpdated
}


###_MOCKED_TESTS

function Get-VaultFileAssociations ($File){
    $file = $allVaultFiles | where { $_._FullPath -eq $File}
    return $file._Attachments
}
function Add-VaultJob ($Name, $Description, $Parameters, $Priority){
    Write-host $Description
}

$vAssembly = New-Object psobject -Property @{
    "Name" = 'Main.iam'
    "_FullPath" = '$/Designs/TESTS/3C-HOLDING/Main.iam'
}
$allVaultFiles = @(
    New-Object psobject -Property @{
        "IsCheckedOut" = $true
        "_Extension" = 'idw'
        "Id" = '123'
        "_State" = 'Work In Progress'
        "_CheckoutUserName" = 'Jordi'
        "_Name" = 'CheckedOutDraw'
        "_FullPath" = '$/Designs/TESTS/3C-HOLDING/CheckedOutDraw.iam'
        "_DateVersionCreated" = (Get-Date -Year 2000 -Month 12 -Day 30)
        "_Attachments" = New-Object psobject -Property @{
            "_DateVersionCreated" = (Get-Date -Year 2000 -Month 12 -Day 29)
            "_Extension" = 'pdf'
        }
    }
    New-Object psobject -Property @{
        "IsCheckedOut" = $false
        "_Extension" = 'idw'
        "Id" = '353'
        "_State" = 'Released'
        "_CheckoutUserName" = ''
        "_Name" = 'CheckedINDraw'
        "_FullPath" = '$/Designs/TESTS/3C-HOLDING/CheckedINDraw.iam'
        "_DateVersionCreated" = (Get-Date -Year 2000 -Month 12 -Day 28)
        "_Attachments" = @(
            New-Object psobject -Property @{
                "_DateVersionCreated" = (Get-Date -Year 2000 -Month 12 -Day 29)
                "_Extension" = 'dxf'}
            New-Object psobject -Property @{
                "_DateVersionCreated" = (Get-Date -Year 2000 -Month 12 -Day 29)
                "_Extension" = 'dwg'}
            New-Object psobject -Property @{
                "_DateVersionCreated" = (Get-Date -Year 2000 -Month 12 -Day 29)
                "_Extension" = 'pdf'}
        )
    }
    New-Object psobject -Property @{
        "IsCheckedOut" = $false
        "_Extension" = 'ipn'
        "_State" = 'Work In Progress'
        "_CheckoutUserName" = 'Jordi'
        "_Name" = 'NotDrawingFile'
        "_FullPath" = '$/Designs/TESTS/3C-HOLDING/NotDrawingFile.iam'
    }
)

$folder = New-Object psobject -Property @{
    "FullName" = '3C-HOLDING'
    "Id" = 1111
}

###CODE 
[xml]$xamlContent = Get-Content "C:\Users\jordiFD\source\repos\WpfApp1\WpfApp1\Issue5.xaml"
$plotSelectionWindow = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader -ArgumentList @($xamlContent)))
[array]$vaultFiles = $allVaultFiles | where { $_._Extension -in @("idw", "dwg")}
$IDlistDrawsToBeUpdated = Select-Attachments -files $vaultFiles -Window $plotSelectionWindow
$CountCheckouts = 0
foreach($vaultFile in $vaultFiles){
	if($vaultFile.IsCheckedOut -eq $false){
        Add-Member -InputObject $vaultFile -Name "CheckOutDisable" -Value $true -MemberType NoteProperty
        Add-Member -InputObject $vaultFile -Name "TriggerJob" -Value $true -MemberType NoteProperty  
	} else {
        Add-Member -InputObject $vaultFile -Name "CheckOutDisable" -Value $false -MemberType NoteProperty
        Add-Member -InputObject $vaultFile -Name "TriggerJob" -Value $false -MemberType NoteProperty
		$CountCheckouts += 1
	}
}
$plotSelectionWindow.FindName("FileView").ItemsSource = @($vaultFiles)
$plotSelectionWindow.FindName("TxtSelectedAssembly").Text = $vAssembly.Name
$plotSelectionWindow.FindName("TxtSelectedAssemblyPath").Text = $vAssembly._FullPath
$plotSelectionWindow.FindName("TxtValidDrawingFiles").Content = @($vaultFiles).Count
$plotSelectionWindow.FindName("TxtDrawingsAlreadyInFolder").Content = @($allVaultFiles).Count - @($vaultFiles).Count
$plotSelectionWindow.FindName("TxtCheckOutDrawings").Content = $CountCheckouts
Set-ButtonEvents -Window $plotSelectionWindow -Folder $folder
$plotSelectionWindow.ShowDialog() | Out-Null