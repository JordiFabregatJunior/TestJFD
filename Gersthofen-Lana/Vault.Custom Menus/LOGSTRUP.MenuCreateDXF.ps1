
try {	
	Import-Module powerVault
	$fileMasterId= $vaultContext.CurrentSelectionSet | select -First 1 -ExpandProperty "Id"
	$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
    $file = Get-VaultFile -FileId $file.Id
    if( @("ipt","idw", "dwg") -contains $file._Extension ) {
        $DXFjob = Add-VaultJob -Name "LOGSTRUP.CreateDXF-SAT" -Description "LOGSTRUP.CreateDXF-SAT" -Parameters @{EntityClassId = "FILE"; EntityId = $file.Id; ManualExport = "DXF"} -Priority 10
    }
} catch {
	[System.Windows.Forms.MessageBox]::Show("Error: '$($_.Exception.Message)'`n`n`nSTACKTRACE:`n$($_.InvocationInfo.PositionMessage)`n`n$($_.ScriptStacktrace)", "DXF Exportation - Error", "Ok", "Error") | Out-Null
}