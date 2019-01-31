try {	
	Import-Module powerVault
	$fileMasterId= $vaultContext.CurrentSelectionSet | select -First 1 -ExpandProperty "Id"
	$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
    $file = Get-VaultFile -FileId $file.Id
    if( @("idw", "dwg") -contains $file._Extension ) {
        $PDFjob = Add-VaultJob -Name "LOGSTRUP.CreatePDF" -Description "LOGSTRUP.CreatePDF" -Parameters @{EntityClassId = "FILE"; EntityId = $file.Id} -Priority 10
    }
} catch {
	[System.Windows.Forms.MessageBox]::Show("Error: '$($_.Exception.Message)'`n`n`nSTACKTRACE:`n$($_.InvocationInfo.PositionMessage)`n`n$($_.ScriptStacktrace)", "PDF Exportation - Error", "Ok", "Error") | Out-Null
}