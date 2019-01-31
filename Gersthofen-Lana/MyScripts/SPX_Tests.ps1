<#Import-Module PowerVault
Import-Module PowerJobs
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$filename = "ANH-001000410.dwg"
$file = Get-VaultFile -Properties @{"Name" = $filename}
$file = $vault.DocumentService.GetFileById($vFile.id)
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/TESTS/SPX")
$job = Add-VaultJob -Name "" -Description "-" -Parameters @{EntityClassId = "FILE"; EntityId = $vfile.Id} -Priority 10
$ToTest = @('ANH-5555_B', 'ANH-001000410B', '2345', '1423423_')
Real environment:
Import-Module PowerVault
Import-Module PowerJobs
Open-VaultConnection -Server "localhost" -Vault "FB Global" -user "Administrator"
####________NoTouching!_________#>

$measuringPerformance = @{}

#Import-Module PowerJobs
Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"

function Remove-PreviousUpload{
    $ArrayOfVaultUpdatedPDFs = @()
    $ArrayOfVaultUpdatedPDFs += $PDFfile.Id
    foreach($addedPDF in $ArrayOfVaultUpdatedPDFs){
        $FileToBeRemoved = $vault.DocumentService.FindFilesByIds($addedPDF)
        $folder = $vault.DocumentService.GetFoldersByFileMasterId($FileToBeRemoved.MasterId)
        $vault.DocumentService.DeleteFileFromFolderUnconditional($FileToBeRemoved.MasterId,$folder.Id)   
    }
}

#Remove-PreviousUpload

$logsPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\ErrorLogs\Logs.csv"
$network = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\SPX - PDF for tests"
$CSVPath = 'C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\PDF-Info For testing2.csv'

$PropsToBeUpdated = 
    @(
    "Author"
    "Title"
    "Subtitle"
    "Description"
    "Project Number"
    "Project Name"
    "Project Description"
    "Project Manager"
    "Site Number"
    "Site Corporation"
    "Address Line1"
    "Address Line2"
    "City"
    "State - Region"
    "Postal Code"
    "Country"
    "Company (Supplier)"
    "Customer Name"
    "Site City"
    "Process cell"
    "Unit"
    "Group number"
    "Document type"
    "Paper size"
    "Date of Issue"
    "State"
    )
 
function Clean-Up {
    param(
        [string]$folder = $null,
        $files = @()
    )
    function Remove-EmptyFolders($folder) {
        $folders = @($folder, (Get-ChildItem $folder -Recurse))
        $folders =  @($folders | Where {$_.PSIsContainer -and @(Get-ChildItem -LiteralPath $_.Fullname -Recurse | Where { -not $_.PSIsContainer }).Count -eq 0 })
        Remove-Items $folders      
    }    
    function Remove-Items($items) {
        $items | foreach { 	Remove-Item -Path $_.FullName -Force -Recurse -confirm:$false -ErrorAction SilentlyContinue }
    }
    $files =@($files | foreach { 
        if($_.GetType() -eq [string]) { Get-Item $_ -ErrorAction SilentlyContinue }
        elseif($_.GetType() -eq [System.IO.FileInfo]) { $_ }
        else {Get-Item $_.LocalPath -ErrorAction SilentlyContinue}    
    })
    if(-not $files -and $folder) {
        $files = Get-ChildItem $folder -Recurse
    }
    Remove-Items $files 
    if( -not $folder -and $files.Count -gt 0 ) {
    $folder =$files[0]
        while( $true ) {          
            if(-not ($folder = Split-Path $folder)) {
                    throw('No folder found')
            }
            if(($files | where { (Split-Path $_).StartsWith($folder) }).Count -eq $files.Count) {
                break;
            }
        }
    }	
    Remove-EmptyFolders (Get-Item $folder)
}    

function Get-FileNameWithoutRevision{
    param(
        $Filename
    )
    if($numericName = $Filename -as [int]) {
        return $numericName 
    } else {
        if($Filename -like '*_*' -and -not($Filename.EndsWith('_'))) {
            return $Filename.Substring(0,$Filename.Length-2)
        } else {
            return $Filename.Substring(0,$Filename.Length-1)
        }
    }
}

function Get-StatusReport {
    param(
        [Parameter(Mandatory = $true)]$Filename,
        [Parameter(Mandatory = $true)]$Status,
        [Parameter(Mandatory = $true)][ValidateSet('No Parent','Multiple Parents','Successfully Migrated','Upload Error','Without Properties','Not Attached','Unknown','No Local PDF','Not Latest','Not PDF')]$Message,
        $ParentFile,
        $ParentId
    )
    $ReportMessage = @{
       'No Parent' = "Could not be found parent file!"
       'Multiple Parents' = "Multiple possible parent files. Upload to Vault aborted"
       'Successfully Migrated' = "Attached to $($ParentFile) with ParentId: $($ParentId)"
       'Upload Error' = "Appropriate PDF $($Filename) to be migrated could not be uploaded to Vault"
       'Without Properties' = "$($Filename) migrated to Vault parent file $($ParentFile), but without its parent properties"
       'Not Attached' = "$($Filename) migrated to Vault parent file $($ParentFile), but could not be attached to it"
       'Unknown' = "Unknown error. PDF not migrated to Vault"
       'No Local PDF' = "No existing local PDF file for $($Filename)"
       'Not Latest' = "It is not latest version!"
       'Not PDF' = "File is not PDF"       
    }
    $CSV = [PSCustomObject]@{'Name' = $Filename; 'Status' = $Status; 'Message' = $ReportMessage[$Message]}
    return $CSV
}

function Get-CSVInfo($CSVPath){
<#
.SYNOPSIS
Gets latest revision PDF file like: $ListPDFNames = @{ANH-001000410 = "ANH-001000410_B.pdf"}
#>
    $listPDFNames = @{}
    $CSVContent = @()
    $csv = Import-Csv -LiteralPath $CSVPath -Encoding UTF8 -Delimiter ',' 
    foreach($row in $csv){
        if($row.Extension -in @('.pdf')){
            [string]$filename = Get-FileNameWithoutRevision -filename $row.Basename
            if(-not($listPDFNames.ContainsKey($filename))){
                $listPDFNames[$filename] = $row.Name
            } elseif($listPDFNames[$filename] -lt $row.Basename) {
                $CSVContent += Get-StatusReport -Filename "$($listPDFNames[$filename])" -Status 'Error' -Message 'Not Latest'
                $listPDFNames[$filename] = $row.Name
            } elseif($row.Basename -lt $listPDFNames[$filename]) {
                $CSVContent += Get-StatusReport -Filename "$($row.Name)" -Status 'Error' -Message 'Not Latest'
            }
        } else {
            $CSVContent += Get-StatusReport -Filename "$($row.Name)" -Status 'Error' -Message 'Not PDF'
        }
    }
    [hashtable]$CSVextraction = @{LatestPDFFileNames = $listPDFNames; CSVContent = $CSVContent} 
    return $CSVextraction
}

function New-LocalCopy {
    param(
        $localPDFLocation,
        $PDFRepositoryPath,
        $workingDirectory 
    )
    if(-not (Test-Path $workingDirectory)){
        $null = New-Item -Path $workingDirectory -ItemType Directory -Force
    }
    Copy-Item $PDFRepositoryPath -Destination $localPDFfileLocation  -ErrorAction SilentlyContinue
}

function Get-FileUDPs {
    param(
        $FileID,
        $PropsToUpdate
    )
    [hashtable]$props = @{}
    $propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId('FILE')
    $onlyFileProperties = $vault.PropertyService.GetPropertiesByEntityIds('FILE', $vfile.Id)
    forEach($Property in $onlyFileProperties){
        $propDef = $propDefs | Where { $_.Id -eq $Property.PropDefId }
        if ($propDef.IsSys -eq $false -and $propDef.DispName -in $PropsToBeUpdated){
            $propertyName = $propDef.DispName
            $props.Add($propertyName, $vfile.$propertyName)
        }
    }
    return $props
}

###___MAIN
$scriptRunTime = Measure-Command {
$CSVInfo = Get-CSVInfo -CSVPath $CSVPath
$CSVContent = $CSVInfo['CSVContent']
$LatestPDFFileNames = $CSVInfo['LatestPDFFileNames']

foreach ($PDFfileName in $LatestPDFFileNames.keys){
    $vfiles = @()
    $PDFNameWithRevision = $LatestPDFFileNames["$($PDFfileName)"]
    $PDFRepositoryPath = Join-Path $network $PDFNameWithRevision
    if((Test-Path $PDFRepositoryPath) -eq $false){
        $CSVContent += Get-StatusReport -Filename $PDFNameWithRevision -Status 'Error' -Message 'No Local PDF'
        continue
    }
    $vfiles = Get-VaultFiles -Properties @{"Name" = "$($PDFfileName).dwg"}
    if ($vfiles.Count -eq 0){
        $CSVContent += Get-StatusReport -Filename $PDFNameWithRevision -Status 'Error' -Message 'No Parent'
        continue
    } elseif ($vfiles.Count -ge 2){
        $CSVContent += Get-StatusReport -Filename $PDFNameWithRevision -Status 'Error' -Message 'Multiple Parents'
        continue
    } else {

        $workingDirectory = "C:\Temp\$($PDFfileName)"
        $localPDFfileLocation = Join-Path $workingDirectory "$($PDFfileName).pdf"
        New-LocalCopy -localPDFLocation $localPDFfileLocation -PDFRepository $PDFRepositoryPath -workingDirectory $workingDirectory
        $vfile = $vfiles | Sort-Object -Descending -Property _CheckInDate | Select -First 1
        $props = Get-FileUDPs -FileID $vfile.Id -PropsToUpdate $PropsToBeUpdated                    
        $vaultPDFfileLocation = $vfile._EntityPath +"/"+ (Split-Path -Leaf $localPDFfileLocation)
        $PDFfile = Add-VaultFile -From $localPDFfileLocation -To $vaultPDFfileLocation -FileClassification None
        #$updatedPDF = Update-VaultFile -File $PDFfile._FullPath -Properties $props -LifecycleDefinition "Office Simple LC" -Status "Release"
        $updatedPDF = Update-VaultFile -File $PDFfile._FullPath -Properties $props
        $attachToParentFile = Update-VaultFile -File $vfile._FullPath -AddAttachments @($updatedPDF._FullPath)
        
        #CSVReportTreatment
        if(-not([string]::IsNullOrEmpty($attachToParentFile))){
            $CSVContent += Get-StatusReport -Filename $PDFNameWithRevision -Status 'Successfully Migrated!' -Message 'Successfully Migrated' -ParentFile $vfile._Name -ParentId $vfile.Id
        } elseif([string]::IsNullOrEmpty($PDFfile)) {
            $CSVContent += Get-StatusReport -Filename $PDFNameWithRevision -Status 'Error' -Message 'Upload Error'                
        } elseif([string]::IsNullOrEmpty($updatedPDF)) {
            $CSVContent += Get-StatusReport -Filename $PDFNameWithRevision -Status 'Error' -Message 'Without Properties' -ParentFile $vfile._Name 
        } elseif([string]::IsNullOrEmpty($attachToParentFile)){
            $CSVContent += Get-StatusReport -Filename $PDFNameWithRevision -Status 'Error' -Message 'Not Attached' -ParentFile $vfile._Name 
        } else {
            $CSVContent += Get-StatusReport -Filename $PDFNameWithRevision -Status 'Error' -Message 'Unknown'
        }

        if(Test-Path($workingDirectory)){
            Clean-Up -folder $workingDirectory
        }
    }
}
$CSVContent | Export-Csv -Path $logsPath -Delimiter ';' -NoTypeInformation -ErrorAction SilentlyContinue
}

$measuringPerformance.add("Run $(Get-Date)", "Test Script(7 files): $($scriptRunTime.TotalMilliseconds) milliseconds // Expected Real Time: $($scriptRunTime.TotalHours*12000/7) hours")
$measuringPerformance.GetEnumerator() | Sort-Object Name -Descending
Write-host "The script took $($scriptRunTime.TotalMilliseconds) milliseconds"