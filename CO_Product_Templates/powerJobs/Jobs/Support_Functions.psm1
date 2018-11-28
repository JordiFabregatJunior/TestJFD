function Start-Excel {
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    if($Global:ApplicationExcel) { return $Global:ApplicationExcel }
    
    $processExcel = Get-Process -Name EXCEL -ErrorAction SilentlyContinue
    foreach($process in $processExcel) { $process.Kill() }

    $Global:ApplicationExcel = New-Object -ComObject Excel.Application

    Start-Sleep -Seconds 2
    $Global:ApplicationExcel.Visible = $false
    $Global:ApplicationExcel.DisplayAlerts = $false
    return $Global:ApplicationExcel 
}
function Close-Excel {
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    if(-not $Global:ApplicationExcel) { return }

    if($Global:ApplicationExcel.ActiveWorkbook) {
        $saveChanges = $false
        $Global:ApplicationExcel.ActiveWorkbook.Close($saveChanges)
    }

    $Global:ApplicationExcel.Quit()
    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$Global:ApplicationExcel)
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    Remove-Variable -Name ApplicationExcel -Scope:Global  
    Start-Sleep -Seconds 1
}
function Export-XlsToPdf {
param(
	[System.IO.FileInfo]$InputObject = "C:\temp\test.xlsx",
	[System.IO.FileInfo]$Path = "C:\TEMP\xlsx_tst.pdf"
)
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    
    $Global:ApplicationExcel = Start-Excel

    $filename = $InputObject.FullName
    $updateLinks = 3
    $readOnly = $true

	$Workbook = $Global:ApplicationExcel.Workbooks.Open($filename,	$updateLinks,	$readOnly)
    
    $destinationFilename = $Path.FullName
    $quality = [Microsoft.Office.Interop.Excel.XlFixedFormatQuality]::xlQualityStandard
    $includeDocProperties = $true
    
    if($InputObject.Name.Contains("QCP") -and ($Workbook.Worksheets.Count -gt 1)) {
        $Workbook.Worksheets | select -Last ($Workbook.Worksheets.Count - 1) | foreach {
            $_.Visible = $false
        }
    }
    $Workbook.ExportAsFixedFormat([Microsoft.Office.Interop.Excel.XlFixedFormatType]::xlTypePDF, $destinationFilename, $quality, $includeDocProperties)

    if( Test-Path $Path.FullName ) { return Get-Item $Path.FullName }
    return $null
}