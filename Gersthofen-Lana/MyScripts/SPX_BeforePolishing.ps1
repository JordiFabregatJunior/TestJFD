<#Import-Module PowerVault
Import-Module PowerJobs
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"
$filename = "ANH-001000410.dwg"
$file = Get-VaultFile -Properties @{"Name" = $filename}
$file = $vault.DocumentService.GetFileById($vFile.id)
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/TESTS/SPX")
$job = Add-VaultJob -Name "" -Description "-" -Parameters @{EntityClassId = "FILE"; EntityId = $vfile.Id} -Priority 10
$ToTest = @('ANH-5555_B', 'ANH-001000410B', '2345', '1423423_')
####________NoTouching!_________#>

Import-Module PowerJobs
Import-Module PowerVault

$CSVPath = 'C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\PDF-Info For testing2.csv'
$logsPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\ErrorLogs\Logs.csv"
$network = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\SPX - PDF for tests"

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
 
function Get-FileNameWithoutRevision($filename){
    try {
        $NumericName = [int]$filename
        return $NumericName
    } catch {
        if($filename -like("*_*") -and -not($filename.EndsWith("_"))) {
            return $filename.Substring(0,$filename.Length-2)
        } else {
            return $filename.Substring(0,$filename.Length-1)
        }
    }
}

#Gets latest revision PDF file like: $ListPDFNames = @{ANH-001000410 = "ANH-001000410_B.pdf"}
function Get-LatestPDFFileNames($CSVPath, $CSVContent){
    $ListPDFNames = @{} 
    $PDFRows = (Get-Content -Path $CSVPath -Encoding UTF8) -split "\n"
    foreach($Row in $PDFRows){
        $Elements = $Row -split ","
        if($Elements[2] -in @(".pdf")){
            [string]$filename = Get-FileNameWithoutRevision -filename $Elements[1]
            if(-not($ListPDFNames.ContainsKey($filename))){
                $ListPDFNames[$filename] = $Elements[3]
            } elseif($ListPDFNames[$filename] -lt $Elements[1]) {
                $CSVContent += [PSCustomObject]@{'Name' = "$($ListPDFNames[$filename])"; 'Status' = "Error"; 'Message' = "Not latest Version"} 
                $ListPDFNames[$filename] = $Elements[3]
            } elseif($Elements[1] -lt $ListPDFNames[$filename]) {
                #LogsTreatment
                $CSVContent += [PSCustomObject]@{'Name' = "$($Elements[3])"; 'Status' = "Error"; 'Message' = "Not latest Version"} 
            }
        } else {
            $CSVContent += [PSCustomObject]@{'Name' = "$($Elements[3])"; 'Status' = "Migration Not needed"; 'Message' = "Is not PDF"}
        }
    }
    return $ListPDFNames, $CSVContent
}

###___MAIN
$scriptRunTime = Measure-Command {

    $CSVContent = @()
    $PDFs = Get-LatestPDFFileNames -CSVContent $CSVContent -CSVPath $CSVPath
    $CSVContent += $PDFs[1]
    $entityClassId = 'FILE'
    $propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($entityClassId)

    foreach ($PDFfileName in $PDFs[0].keys){
        $vfiles = @()
        #$PDFfileName = 'ANH-001000410'
        $workingDirectory = "C:\Temp\$($PDFfileName)"
        $fromPath = Join-Path $network $PDFs[0]["$($PDFfileName)"]
        $Path = Join-Path $workingDirectory $PDFs[0]["$($PDFfileName)"]
        if(Test-Path $fromPath){
            if(-not (Test-Path $workingDirectory)){
                New-Item -Path $workingDirectory -ItemType Directory -Force | Out-Null
            }
            Copy-Item $fromPath -Destination $workingDirectory
            if(Test-Path $Path){
                Rename-Item -Path $Path -NewName "$($PDFfileName).pdf" -ErrorAction SilentlyContinue  
            }
            $localPDFfileLocation = Join-Path $workingDirectory "$($PDFfileName).pdf"
            $vfiles = Get-VaultFiles -Properties @{"Name" = "$($PDFfileName).dwg"}
            if ($vfiles.Count -eq 0){
                $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs[0]["$($PDFfileName)"])"; 'Status' = "Error"; 'Message' = "Not found parent file"}
            } else {
                if($vfiles.Count -ge 2){
                    $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs[0]["$($PDFfileName)"])"; 'Status' = "Error"; 'Message' = "More than one parent file"}
                } else {
                    [hashtable]$props = @{}
                    $vfile = $vfiles | Sort-Object -Descending -Property _CheckInDate | Select -First 1
                    $onlyFileProperties = $vault.PropertyService.GetPropertiesByEntityIds($entityClassId, $vfile.Id)
                    forEach($Property in $onlyFileProperties){
                        $propDef = $propDefs | Where { $_.Id -eq $Property.PropDefId }
                        if ($propDef.IsSys -eq $false -and $propDef.DispName -in $PropsToBeUpdated){
                            $propertyName = $propDef.DispName
                            $props.Add($propertyName, $vfile.$propertyName)
                        }
                    }
                    $vaultPDFfileLocation = $vfile._EntityPath +"/"+ (Split-Path -Leaf $localPDFfileLocation)
                    $PDFfile = Add-VaultFile -From $localPDFfileLocation -To $vaultPDFfileLocation -FileClassification None
                    $updatedPDFfile = Update-VaultFile -File $PDFfile._FullPath -Properties $props
                    $attachToParentFile = Update-VaultFile -File $vfile._FullPath -AddAttachments @($updatedPDFfile._FullPath)
                    if(-not([string]::IsNullOrEmpty($attachToParentFile))){
                        $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs[0]["$($PDFfileName)"])"; 'Status' = "Successfully Migrated!"; 'Message' = "Attached to (ParentFullname, MasterId): $($vfile._Name),$($vfile.MasterId)"}
                    } else {
                        if([string]::IsNullOrEmpty($PDFfile)){
                            $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs[0]["$($PDFfileName)"])"; 'Status' = "ERROR"; 'Message' = "Appropriate PDF $($PDFs[0]["$($PDFfileName)"]) to be migrated could not be uploaded to Vault"}
                        } elseif([string]::IsNullOrEmpty($updatedPDFfile)) {
                            $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs[0]["$($PDFfileName)"])"; 'Status' = "ERROR"; 'Message' = "$($PDFs[0]["$($PDFfileName)"]) migrated to Vault parent file $($vfile._Name), but without its parent properties"}
                        } elseif([string]::IsNullOrEmpty($attachToParentFile)){
                            $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs[0]["$($PDFfileName)"])"; 'Status' = "ERROR"; 'Message' = "$($PDFs[0]["$($PDFfileName)"]) migrated to Vault parent file $($vfile._Name), but could not be attached to it"}
                        } else {
                            $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs[0]["$($PDFfileName)"])"; 'Status' = "Error"; 'Message' = "Unknown error. PDF not migrated to Vault"}                        
                        }
                    }
                }
            }    
        } else {
            $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs[0]["$($PDFfileName)"])"; 'Status' = "Error"; 'Message' = "No existing local PDF file for $($PDFs[0]["$($PDFfileName)"]) "}            
        }

        if(Test-Path($workingDirectory)){
            Clean-Up -folder $workingDirectory
        }
    }
    $CSVContent | Export-Csv -Path $logsPath -Delimiter ';' -NoTypeInformation -ErrorAction SilentlyContinue
}

$measuringPerformance.add("Run $(Get-Date)", "Test Script(7 files): $($scriptRunTime.TotalMilliseconds) milliseconds // Expected Real Time: $($scriptRunTime.TotalHours*12000/7) hours")
$measuringPerformance.GetEnumerator() | Sort-Object Name -Descending
Write-host "The script took $($scriptRunTime.TotalMilliseconds) milliseconds"