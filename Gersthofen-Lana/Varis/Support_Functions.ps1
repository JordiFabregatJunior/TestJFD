
function Archive-ExistingFile {
    param (
        $path,
        $destination,
        $filename
    )
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    $existingFile = @() 
    $existingFile += Get-ChildItem -Path $path -Filter "$($filename + '*')"
    if ($existingFile){
        $existingFullFileName = Join-Path $path $existingFile[0]
        $destinationFile = Join-Path $destination $existingFile[0]
        if(-not (Test-Path $destination))
        {
            New-Item -Path $destination -ItemType Directory -Force | Out-Null
        }
        Move-Item -Path $existingFullFileName -Destination $destinationFile
    }
}
 
function Archive-File {
    param (
        $path,
        $destination,
        $archive
    )
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($path)
    $fileExtension = [System.IO.Path]::GetExtension($path)    
    $archiveDestination = Join-Path $destination $archive
    Archive-ExistingFile -path $destination -destination $archiveDestination -filename $filename
    $datetimestamp = Get-Date -UFormat %y%m%d_%H%M
    $filename = $filename + $datetimestamp + $fileExtension
    $destinationFile = Join-Path $destination $filename
    Copy-Item -Path $path -Destination $destinationFile
}
