#All code prepared => Only missing DataStandard + remove the rest of previous code
#[xml]$xamlContent = Get-Content "C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\Vault.Custom\addinVault\Menus\ProjektPlotSelectionDialogTESTING.xaml"

###_________Version 7/11-11:15h
function Get-AllVaultFiles ($FileIds) {
	$vaultFiles = @()
	foreach ($fileId in $FileIds){
		$vaultFiles += Get-VaultFile -FileId $fileId
	}
	Return $vaultFiles
}

function CheckLinksInFolder ($Folder) {
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

function Invoke-ButtonStartPlot($Window, $Folder) {
	$selectedIDWFiles = @(($Window.FindName("FileView").ItemsSource) | where { $_.TriggerJob })
	foreach ($IDWFile in $SelectedIDWFiles){
    	$vault.DocumentService.AddLink($Folder.Id,"FILE",$IDWFile.Id,"")
    }
	[System.Windows.Forms.MessageBox]::Show("Es wurden erfolgreich $($selectedIDWFiles.Count) Dateien verknüpft!`n", "IDW Verknüpfung - Erfolg", "Ok", "Information") | Out-Null
	$Window.Close()
}

function Set-ButtonEvents($Window, $Folder) {
	$global:window = $Window
	$global:Folder = $Folder
	$Window.FindName("BtnTriggerJobs").add_Click({
		Invoke-ButtonStartPlot -Window $global:window -Folder $global:Folder
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

function Get-IDWIds ($fileIteration){
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
	$allAssociatedFilesIds = @()
	$IDWIds = @()
	$ValidParents = @{}
	foreach ($dependentFile in $fal){
		$allAssociatedFilesIds += $dependentFile.CldFileId
	}
	$UniqueFilesIds = $allAssociatedFilesIds | Select-Object -Unique
	Foreach ($file in $fal){
		if ($file.CldFileId -in $UniqueFilesIds){
			$ValidParents[$file.CldFileId] = $file.ParFileId
		}
	}
	$IDWIds =  $ValidParents.Values
	return $IDWIds
}

try {	
	Import-Module powerVault
	$fileMasterId= $vaultContext.CurrentSelectionSet | select -First 1 -ExpandProperty "Id"
	$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
	$vAssembly = Get-VaultFile -FileId $file.Id
	if (-not ($vAssembly._Extension -eq 'iam')){
		[System.Windows.Forms.MessageBox]::Show("Die Datei $($vAssembly.Name) ist keine Baugruppe.", "IDW Verknüpfung - Fehler", "Ok", "Information") | Out-Null
		Break
	}
	$folder = $vault.DocumentService.GetFolderByPath($vAssembly.Path)
	$fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)
	[xml]$xamlContent = Get-Content "C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\Vault.Custom\addinVault\Menus\ProjektPlotSelectionDialogTESTING.xaml"
	$plotSelectionWindow = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader -ArgumentList @($xamlContent)))

	$vaultFileIds = Get-IDWIds -fileIteration $fileIteration
	$allVaultFiles = Get-AllVaultFiles -FileIds $vaultFileIds
	$vaultFilesIdsWithLinks = CheckLinksInFolder -Folder $folder 
	<#$linksOnFolder = $vault.DocumentService.GetLinksByParentIds($Folder.Id, "FILE")
	[array]$vaultFilesIdsWithLinks= @()
	foreach ($link in $linksOnFolder){
		if ($link.ToEntId -in $vaultFileIds){
			$vaultFilesIdsWithLinks += $link.ToEntId
		}
	}#>
	[array]$vaultFiles = $allVaultFiles | where { $_._Extension -in @("idw", "dwg") -and $_.Path -ne $folder.FullName -and $_.Id -notin $vaultFilesIdsWithLinks}
	<#if ($vaultFiles.Count -eq $null){
		[System.Windows.Forms.MessageBox]::Show("Es sind bereits alle Zeichnungen der ausgewählten Baugruppe schon mit dem Ordner verknüpft.", "IDW Verknüpfung - Fehler", "Ok", "Information") | Out-Null
		Break
	}#>
	$vaultFiles | foreach { Add-Member -InputObject $_ -Name "TriggerJob" -Value $true -MemberType NoteProperty}
	$plotSelectionWindow.FindName("FileView").ItemsSource = @($vaultFiles)
	$plotSelectionWindow.FindName("TxtSelectedAssembly").Text = $vAssembly.Name
	$plotSelectionWindow.FindName("TxtSelectedAssemblyPath").Text = $vAssembly._FullPath
	$plotSelectionWindow.FindName("TxtValidDrawingFiles").Content = @($vaultFiles).Count
	$plotSelectionWindow.FindName("TxtDrawingsAlreadyInFolder").Content = @($allVaultFiles).Count - @($vaultFiles).Count
	Set-ButtonEvents -Window $plotSelectionWindow -Folder $folder
	$plotSelectionWindow.ShowDialog() | Out-Null
} catch {
	[System.Windows.Forms.MessageBox]::Show("Fehlermeldung: '$($_.Exception.Message)'`n`n`nSTACKTRACE:`n$($_.InvocationInfo.PositionMessage)`n`n$($_.ScriptStacktrace)", "IDW Verknüpfung - Fehler", "Ok", "Error") | Out-Null
}





###########################___________________PREVIOUS CODE
#It will be awesome
function Get-VaultJobs {
    param( [string]$jobType )
    @(($vault.JobService.GetJobsByDate([int]::MaxValue, [DateTime]::MinValue)) | where { $_.Typ -eq $jobType })
}

function Get-AllVaultFiles ($FileIds) {
	$vaultFiles = @()
	foreach ($fileId in $FileIds){
		$vaultFiles += Get-VaultFile -FileId $fileId
	}
	Return $vaultFiles
}

<#function Get-AllVaultFiles {
	param(
        [Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.Folder]$Folder
    )
	$vaultFiles = Get-VaultFiles -Folder $folder.FullName
	$fileLinks = $vault.DocumentService.GetLinksByParentIds(@($folder.Id), @("FILE"))
	$vaultFiles += $fileLinks | where { $_.ToEntId } | foreach {
		$originalVaultFile = (Get-VaultFile -FileId $_.ToEntId)
		Add-Member -InputObject $originalVaultFile -Name "LinkPath" -Value "$($folder.FullName)/$($originalVaultFile._Name)" -MemberType NoteProperty
		$originalVaultFile
	}
	return $vaultFiles
}#>

function Test-JobExists($jobType, $jobArguments) {
	$jobForFileAlreadyExists = @(Get-VaultJobs -JobType $jobType) | where {
		$presentJobEntityClassId = $_.ParamArray | where {$_.Name -eq "EntityClassId"} | select -ExpandProperty "Val"
		$presentJobFileId = $_.ParamArray | where {$_.Name -eq "EntityId"} | select -ExpandProperty "Val"
		$presentJobProjekt = $_.ParamArray | where {$_.Name -eq "Projekt"} | select -ExpandProperty "Val"
		$presentJobEntityClassId -eq $jobArguments["EntityClassId"] -and $presentJobFileId -eq $jobArguments["EntityId"] -and $presentJobProjekt -eq $jobArguments["Projekt"]
   }
}

function Add-PlotVaultJobs($VaultFiles, $ProjectNumber, $JobPriority = "Low") {
	$VaultFiles | foreach {
		$jobArguments = @{
			"EntityClassId" = "File"
			"EntityId" = $_.Id
			"Projekt" = $ProjectNumber
		}
		$jobType = "AutoPlot"
		$jobForFileAlreadyExists = Test-JobExists -JobType $jobType -JobArguments $jobArguments
		if(-not $jobForFileAlreadyExists) {
			Add-VaultJob -Name $jobType -Parameters $jobArguments -Description "Update iProperty 'Project' and plots afterward. Projektnummer: '$ProjectNumber' for file '$($_.Name)'" -Priority $JobPriority
		}
	}
}


function Set-FilesInGui($Window, $Enable = $false) {
	$allFiles = $Window.FindName("FileView").ItemsSource
	$Window.FindName("FileView").ItemsSource = $null
	$allFiles | foreach { $_.TriggerJob = $Enable }
	$Window.FindName("FileView").ItemsSource = $allFiles
}

function Invoke-ButtonStartPlot($Window, $Folder) {
	$selectedIDWFiles = @(($Window.FindName("FileView").ItemsSource) | where { $_.TriggerJob })
	#$triggeredJobs = @(Add-PlotVaultJobs -VaultFiles $selectedFiles -ProjectNumber $ProjectNumber)
	foreach ($IDWFile in $SelectedIDWFiles){
    	$vault.DocumentService.AddLink($Folder.Id,"FILE",$IDWFile.Id,"")
    }
	[System.Windows.Forms.MessageBox]::Show("Es wurden erfolgreich $($selectedIDWFiles.Count) Dateien verknüpft!`n", "IDW Verknüpfung - Erfolg", "Ok", "Information") | Out-Null
	$Window.Close()
}

function Set-ButtonEvents($Window, $Folder) {
	$global:window = $Window
	$global:Folder = $Folder
	$Window.FindName("BtnTriggerJobs").add_Click({
		Invoke-ButtonStartPlot -Window $global:window -Folder $global:Folder
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

function Get-IDWIds ($fileIteration){
	$frgs = New-Object Autodesk.DataManagement.Client.Framework.Vault.Settings.FileRelationshipGatheringSettings
		$frgs.IncludeAttachments = $false
		$frgs.IncludeChildren = $true
		$frgs.IncludeRelatedDocumentation = $true
		$frgs.RecurseChildren = $true
		$frgs.IncludeParents = $true
		$frgs.RecurseParents = $false
		#$frgs.VersionGatheringOption = "Actual"
		$frgs.DateBiased = $false
		$frgs.IncludeHiddenEntities = $false
		$frgs.IncludeLibraryContents = $false
		$ids = @()
		$ids += $fileIteration.EntityIterationId
		#$dsDiag.Inspect()       
	$fal = $vaultConnection.FileManager.GetFileAssociationLites([int64[]]$ids, $frgs)
	#$fal | Out-GridView
	$allAssociatedFilesIds = @()
	$IDWIds = @()
	$ValidParents = @{}
	foreach ($dependentFile in $fal){
		$allAssociatedFilesIds += $dependentFile.CldFileId
	}
	$UniqueFilesIds = $allAssociatedFilesIds | Select-Object -Unique
	Foreach ($file in $fal){
		if ($file.CldFileId -in $UniqueFilesIds){
			$ValidParents[$file.CldFileId] = $file.ParFileId
		}
	}
	$IDWIds =  $ValidParents.Values
	return $IDWIds
}

try {	
	Import-Module powerVault
	<#For debugging purposes
	#$filename = "main.iam"			
	#$PVaultFile = Get-VaultFile -Properties @{Name = $filename}
	#$file = $vault.DocumentService.GetLatestFileByMasterId($PVaultFile.MasterId)#>
	$fileMasterId= $vaultContext.CurrentSelectionSet | select -First 1 -ExpandProperty "Id"
	$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
	$vAssembly = Get-VaultFile -FileId $file.Id
	if (-not ($vAssembly._Extension -eq 'iam')){
		[System.Windows.Forms.MessageBox]::Show("Die Datei $($vAssembly.Name) ist keine Baugruppe.", "IDW Verknüpfung - Fehler", "Ok", "Information") | Out-Null
		Break
	}
	$folder = $vault.DocumentService.GetFolderByPath($vAssembly.Path)
	$fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)
	[xml]$xamlContent = Get-Content "C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\Vault.Custom\addinVault\Menus\ProjektPlotSelectionDialogTESTING.xaml"
	$plotSelectionWindow = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader -ArgumentList @($xamlContent)))

	$vaultFileIds = Get-IDWIds -fileIteration $fileIteration
	$allVaultFiles = Get-AllVaultFiles -FileIds $vaultFileIds
	$alldrawings = @($allVaultFiles).Count
	$linksOnFolder = $vault.DocumentService.GetLinksByParentIds($Folder.Id, "FILE")
	[array]$vaultFilesIdsWithLinks= @()
	foreach ($link in $linksOnFolder){
		if ($link.ToEntId -in $vaultFileIds){
			$vaultFilesIdsWithLinks += $link.ToEntId
		}
	}
	[array]$vaultFiles = $allVaultFiles | where { $_._Extension -in @("idw", "dwg") -and $_.Path -ne $folder.FullName -and $_.Id -notin $vaultFilesIdsWithLinks}
	if ($vaultFiles.Count -eq $null){
		[System.Windows.Forms.MessageBox]::Show("Es sind bereits alle Zeichnungen der ausgewählten Baugruppe schon mit dem Ordner verknüpft.", "IDW Verknüpfung - Fehler", "Ok", "Information") | Out-Null
		Break
	}
	$vaultFiles | foreach { Add-Member -InputObject $_ -Name "TriggerJob" -Value $true -MemberType NoteProperty}
	$plotSelectionWindow.FindName("FileView").ItemsSource = @($vaultFiles)
	$plotSelectionWindow.FindName("TxtSelectedAssembly").Text = $vAssembly.Name
	$plotSelectionWindow.FindName("TxtSelectedAssemblyPath").Text = $vAssembly._FullPath
	$plotSelectionWindow.FindName("TxtValidDrawingFiles").Content = @($vaultFiles).Count
	$plotSelectionWindow.FindName("TxtDrawingsAlreadyInFolder").Content = @($allVaultFiles).Count - @($vaultFiles).Count
	Show-Inspector
	Set-ButtonEvents -Window $plotSelectionWindow -Folder $folder
	$plotSelectionWindow.ShowDialog() | Out-Null
} catch {
	[System.Windows.Forms.MessageBox]::Show("Fehlermeldung: '$($_.Exception.Message)'`n`n`nSTACKTRACE:`n$($_.InvocationInfo.PositionMessage)`n`n$($_.ScriptStacktrace)", "IDW Verknüpfung - Fehler", "Ok", "Error") | Out-Null
}