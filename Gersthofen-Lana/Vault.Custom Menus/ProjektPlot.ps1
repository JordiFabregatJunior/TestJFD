function Get-FolderProperty{
    param(
        [Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.Folder]$Folder,
        [string]$PropertyName
    )
    $propDefinitions = ($vaultConnection.PropertyManager.GetPropertyDefinitions("FLDR", $null, "IncludeAll")).Values | where { $_.DisplayName -eq $propertyName } | select -First 1
    if($propDefinitions) {
        $vaultConnection.PropertyManager.GetPropertyValue($folder, $propDefinitions, $null)
    } 
}

function Get-VaultJobs {
    param( [string]$jobType )
    @(($vault.JobService.GetJobsByDate([int]::MaxValue, [DateTime]::MinValue)) | where { $_.Typ -eq $jobType })
}

function Get-AllVaultFiles {
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
}

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

function Invoke-ButtonStartPlot($Window, $ProjectNumber) {
	$selectedFiles = @(($Window.FindName("FileView").ItemsSource) | where { $_.TriggerJob })
	$triggeredJobs = @(Add-PlotVaultJobs -VaultFiles $selectedFiles -ProjectNumber $ProjectNumber)
	[System.Windows.Forms.MessageBox]::Show("Es wurden erfolgreich $($triggeredJobs.Count) Jobs in die Queue gelegt von den ausgewählten $($selectedFiles.Count) Dateien!`nWenn weniger Jobs abgesetzt wurden als ausgewählt, dann sehr wahrscheinlich weil bereits diesselben Jobs in der Queue liegen.", "Projekt Plot - Erfolg", "Ok", "Information") | Out-Null
	$Window.Close()
}

function Set-ButtonEvents($Window, $ProjectNumber) {
	$global:window = $Window
	$global:ProjectNumber = $ProjectNumber
	$Window.FindName("BtnTriggerJobs").add_Click({
		Invoke-ButtonStartPlot -Window $global:window -ProjectNumber $global:ProjectNumber
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

try {	
	Import-Module powerVault
	$folderId= $vaultContext.CurrentSelectionSet | select -First 1 -ExpandProperty "Id"
	if(-not $folderId -and -not $vaultContext) { # For debugging purposes
		Open-VaultConnection -Vault SysVault -Server "srv-vault-01" -User "Administrator" -Password ""
		$parentFolder = $vault.DocumentService.GetFolderByPath( "$/Konstruktion/Projekte/Project-Test2" )
		$folderId = $parentFolder.Id
	}
	$fldr = $vault.DocumentService.GetFolderById($folderId)
	$folder = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.Folder($vaultConnection, $fldr)
	$allVaultFiles = Get-AllVaultFiles -Folder $folder
	$folderProject = Get-FolderProperty -Folder $folder -PropertyName "Projektnummer"

	[xml]$xamlContent = Get-Content "C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\Vault.Custom\addinVault\Menus\ProjektPlotSelectionDialog.xaml"
	#	[xml]$xamlContent = Get-Content "C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\Vault.Custom\addinVault\Menus\ProjektPlotSelectionDialogTESTING.xaml"
	$plotSelectionWindow = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader -ArgumentList @($xamlContent)))

	$vaultFiles = $allVaultFiles | where { $_._Extension -eq "idw" -and -not $_.IsCheckedOut }
	$vaultFiles | foreach { Add-Member -InputObject $_ -Name "TriggerJob" -Value $true -MemberType NoteProperty}
	$plotSelectionWindow.FindName("FileView").ItemsSource = @($vaultFiles)
	$plotSelectionWindow.FindName("TxtCurrentFolder").Text = $folder.FullName
	$plotSelectionWindow.FindName("TxtCurrentProjectNumber").Text = $folderProject
	$plotSelectionWindow.FindName("TxtTotalFilesInFolder").Content = @($allVaultFiles).Count
	$plotSelectionWindow.FindName("TxtValidFilesInFolder").Content = @($vaultFiles).Count
	Set-ButtonEvents -Window $plotSelectionWindow -ProjectNumber $folderProject
	$plotSelectionWindow.ShowDialog() | Out-Null
} catch {
	[System.Windows.Forms.MessageBox]::Show("Fehlermeldung: '$($_.Exception.Message)'`n`n`nSTACKTRACE:`n$($_.InvocationInfo.PositionMessage)`n`n$($_.ScriptStacktrace)", "Projekt Plot - Fehler", "Ok", "Error") | Out-Null
}