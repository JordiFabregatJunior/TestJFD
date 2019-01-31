try {	
    Import-Module powerVault
    if( @("idw","dwg","ipt") -notcontains $file._Extension ) {
        Write-Host "Files with extension: '$($file._Extension)' are not supported. Exportatioin aborted!"
        return
    }
    if( @("idw", "dwg") -contains $file._Extension ) {
        $PDFjob = Add-VaultJob -Name "LOGSTRUP.CreatePDF" -Description "LOGSTRUP.CreatePDF" -Parameters @{EntityClassId = "FILE"; EntityId = $file.Id} -Priority 10
    } elseif ( @("ipt") -contains $file._Extension ) {
        $SAT_DXF_job = Add-VaultJob -Name "LOGSTRUP.CreateDXF-SAT" -Description "LOGSTRUP.CreateDXF-SAT" -Parameters @{EntityClassId = "FILE"; EntityId = $file.Id} -Priority 10 
    }
}
catch{
    if($file._Extension -eq "ipt" -and -not($SAT_DXF_job)){
        Write-Host "The SAT/DXF exportation for $($file._Name) failed."        
    } elseif (@("idw", "dwg") -contains $file._Extension -and -not ($PDFjob)) {
        Write-Host "The PDF exportation for $($file._Name) failed."
    }
}