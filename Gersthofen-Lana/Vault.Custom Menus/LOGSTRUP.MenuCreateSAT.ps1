try {	
	Import-Module powerVault
	$fileMasterId= $vaultContext.CurrentSelectionSet | select -First 1 -ExpandProperty "Id"
	$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
    $file = Get-VaultFile -FileId $file.Id
    if( @("ipt", "iam") -contains $file._Extension ) {
        $SATjob = Add-VaultJob -Name "LOGSTRUP.CreateDXF-SAT" -Description "LOGSTRUP.CreateDXF-SAT" -Parameters @{EntityClassId = "FILE"; EntityId = $file.Id; ManualExport = "SAT"} -Priority 10
    }
} catch {
	[System.Windows.Forms.MessageBox]::Show("Error: '$($_.Exception.Message)'`n`n`nSTACKTRACE:`n$($_.InvocationInfo.PositionMessage)`n`n$($_.ScriptStacktrace)", "SAT Exportation - Error", "Ok", "Error") | Out-Null
}