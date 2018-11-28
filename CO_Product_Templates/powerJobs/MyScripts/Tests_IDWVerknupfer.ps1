function Get-AllVaultFiles ($FileIds) {
	$vaultFiles = @()
	foreach ($fileId in $FileIds){
		$vaultFiles += Get-VaultFile -FileId $fileId
	}
	Return $vaultFiles
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
	$fileIteration = New-Object Autodesk.DataManagement.Client.Framework.Vault.Currency.Entities.FileIteration($vaultConnection,$file)
	[xml]$xamlContent = Get-Content "C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\Vault.Custom\addinVault\Menus\ProjektPlotSelectionDialogTESTING.xaml"
	#[xml]$xamlContent = Get-Content "C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\Vault.Custom\addinVault\Menus\IDWFileSelectionDialog.xaml"
	$plotSelectionWindow = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader -ArgumentList @($xamlContent)))

	$vaultFileIds = Get-IDWIds -fileIteration $fileIteration
	$allVaultFiles = Get-AllVaultFiles -FileIds $vaultFileIds
	$vaultFiles = $allVaultFiles | where { $_._Extension -eq "idw"}
	$vaultFiles | foreach { Add-Member -InputObject $_ -Name "TriggerJob" -Value $true -MemberType NoteProperty}
	$plotSelectionWindow.FindName("FileView").ItemsSource = @($vaultFiles)
	# It should be the full name of the chosen iam 	$plotSelectionWindow.FindName("TxtCurrentFolder").Text = $folder.FullName
	$plotSelectionWindow.FindName("TxtSelectedAssembly").Text = $vAssembly.Name
	# It could be the name of the folder where the iam is loacted #	$plotSelectionWindow.FindName("TxtCurrentProjectNumber").Text = $folderProject
	$plotSelectionWindow.FindName("TxtSelectedAssemblyPath").Text = $vAssembly._FullPath
	# It could be removed #	$plotSelectionWindow.FindName("TxtTotalFilesInFolder").Content = @($allVaultFiles).Count
	# It could be the count of unique idws found #	$plotSelectionWindow.FindName("TxtValidFilesInFolder").Content = @($vaultFiles).Count
	$plotSelectionWindow.FindName("TxtValidIDWFiles").Content = @($vaultFiles).Count
	Set-ButtonEvents -Window $plotSelectionWindow #-ProjectNumber $folderProject
	$plotSelectionWindow.ShowDialog() | Out-Null
} catch {
	[System.Windows.Forms.MessageBox]::Show("Fehlermeldung: '$($_.Exception.Message)'`n`n`nSTACKTRACE:`n$($_.InvocationInfo.PositionMessage)`n`n$($_.ScriptStacktrace)", "IDW Verknüpfung - Fehler", "Ok", "Error") | Out-Null
}