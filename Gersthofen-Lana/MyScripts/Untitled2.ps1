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

#inline parameters are harder to read than a param() block at the start of the function
function Get-FileNameWithoutRevision($filename){
    #try catch should not be used to controll the programm flow
    #if you want to execute different code in case you can't cast a value check beforehand if the value can be cast or use the -as operator
    #the -as operator will return $null in case a cast fails 
    #e.g. if($numericName = $filename -as [int]) { #dostuff } else { #dootherstuff }
    try {
        $NumericName = [int]$filename
        return $NumericName
    } catch {
        #-like is a powershell operator not a .net function. should be used like this: $filename -like '*_*'
        #use ' to mark strings that do not contain any substitutes.
        if($filename -like "*_*" -and -not($filename.EndsWith("_"))) {
            return $filename.Substring(0,$filename.Length-2)
        } else {
            return $filename.Substring(0,$filename.Length-1)
        }
    }
}

#enum or validateset for message and status
#there is no reason to pass in the csv file as it is overridden anyway
#name should be Get-StatusReport as it returns a value
function Add-StatusReport($CSV, $Filename, $Status, $Message, $ParentFile, $ParentId){
    param(
        [ValidateSet('NoParent','MultipleParents')]
    )
    $ReportMessage = @{
       "No Parent" = "Could not be found parent file!"
       "Multiple Parents" = "Multiple possible parent files. Upload to Vault aborted"
       "Successfully Migrated" = "Attached to $($ParentFile) with ParentId: $($ParentId)"
       "Upload Error" = "Appropriate PDF $($Filename) to be migrated could not be uploaded to Vault"
       "Without Properties" = "$($Filename) migrated to Vault parent file $($ParentFile), but without its parent properties"
       "Not Attached" = "$($Filename) migrated to Vault parent file $($ParentFile), but could not be attached to it"
       "Unknown" = "Unknown error. PDF not migrated to Vault"
       "No Local PDF" = "No existing local PDF file for $($Filename)"
       "Not Latest" = "It is not latest version!"
       "Not PDF" = "File is not PDF"       
    }
    $CSV = [PSCustomObject]@{'Name' = $Filename; 'Status' = $Status; 'Message' = $ReportMessage[$Message]}
    return $CSV
}
class Tuple {

    [string] $PdfNames
    [PsObject[]] $CsvContent
}
#CSVContent is defined as a parameter, but it seems it is just the return value. For this you should define the variable within the function
#$csvContent = @()
function Get-LatestPDFFileNames($CSVPath, $CSVContent){
<#
.SYNOPSIS
Gets latest revision PDF file like: $ListPDFNames = @{ANH-001000410 = "ANH-001000410_B.pdf"}
#>
    $ListPDFNames = @{} 
    $csvContent = @()

    #use Import-Csv to read csv file
    #e.g. $csv = Import-Csv -LiteralPath $CSVPath -Encoding UTF8 -Delimiter ','
    #this allows to access the columns with their proper name e.g. $csv[0].COLUMN1
    $PDFRows = (Get-Content -Path $CSVPath -Encoding UTF8) -split "\n"
    foreach($Row in $PDFRows){
        $Elements = $Row -split ","
        if($Elements[2] -in @(".pdf")){
            [string]$filename = Get-FileNameWithoutRevision -filename $Elements[1]
            if(-not($ListPDFNames.ContainsKey($filename))){
                $ListPDFNames[$filename] = $Elements[3]
            } 
            elseif($ListPDFNames[$filename] -lt $Elements[1]) {
                $CSVContent += Add-StatusReport -CSV $CSVContent -Filename "$($ListPDFNames[$filename])" -Status "Error" -Message "Not Latest"
                $ListPDFNames[$filename] = $Elements[3]
            } 
            elseif($Elements[1] -lt $ListPDFNames[$filename]) {
                $CSVContent += Add-StatusReport -CSV $CSVContent -Filename "$($Elements[3])" -Status "Error" -Message "Not Latest"
            }
        } 
        else {
            $CSVContent += Add-StatusReport -CSV $CSVContent -Filename "$($Elements[3])" -Status "Error" -Message "Not PDF"
        }
    }
    #don't return an array with different objects.
    #use a hashtable or build a new class to hold the data if you want to return multiple values
    #it is also an indicator that your function might do to many things
    #should probably be two functions for names and csv stuff
    return $ListPDFNames, $CSVContent
}


###___MAIN
#for larger scripts I like to use [System.Diagnostics.Stopwatch] as you don't need to wrap a lot of code into additional code blocks
$scriptRunTime = Measure-Command {
    $CSVContent = @()
    #variable is called pdf but actually contains PDF names and CSVcontent
    $PDFs = Get-LatestPDFFileNames -CSVContent $CSVContent -CSVPath $CSVPath
    $CSVContent += $PDFs[1]
    
    #in the case of entityClassId it is probably fine to use the string directly. You will rarely change it, if ever.
    #in case you defined the variable so the function parameters can be read it would make sense to do the same before GetPropertiesByEntityIds
    $entityClassId = 'FILE' 
    $propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($entityClassId)

    foreach ($PDFfileName in $PDFs[0].keys){
        $vfiles = @()
        $workingDirectory = "C:\Temp\$($PDFfileName)"
        $fromPath = Join-Path $network $PDFs[0]["$($PDFfileName)"]#hard to read. Will be better if PDFs is cleaned up
        $path = Join-Path $workingDirectory $PDFs[0]["$($PDFfileName)"] #path is rather generic. What path is it?

        #Don't use huge code blocks in if statements. Instead reverse the statement and break or continue the loop. Continue will continue with the next element, break will end the loop
        #e.g. if( (Test-Path $fromPath) -eq $false) {
        #         #do some stuff here
        #         continue
        #     }
        if(Test-Path $fromPath){ 
            if(-not (Test-Path $workingDirectory)){
                #use $null = instead of | Out-Null. It has much better performance
                New-Item -Path $workingDirectory -ItemType Directory -Force | Out-Null
            }
            Copy-Item $fromPath -Destination $workingDirectory #you can also rename the file with the copy commandlet. You just need to pass in the FullPath to Destination
            if(Test-Path $path){
                Rename-Item -Path $path -NewName "$($PDFfileName).pdf" -ErrorAction SilentlyContinue  
            }
            $localPDFfileLocation = Join-Path $workingDirectory "$($PDFfileName).pdf"#youcan use that for copying + renaming
            $vfiles = Get-VaultFiles -Properties @{"Name" = "$($PDFfileName).dwg"}
            $PDFCompleteName = "$($PDFs[0]["$($PDFfileName)"])"
            if ($vfiles.Count -eq 0){ #same as before. do your cleanup and continue the loop
                $CSVContent += Add-StatusReport -CSV $CSVContent -Filename $PDFCompleteName -Status "Error" -Message "No Parent"
            } 
            else {
                if($vfiles.Count -ge 2){
                    $CSVContent += Add-StatusReport -CSV $CSVContent -Filename $PDFCompleteName -Status "Error" -Message "Multiple Parents"
                } 
                else {
                    [hashtable]$props = @{}
                    $vfile = $vfiles | Sort-Object -Descending -Property _CheckInDate | Select -First 1
                    
                    $entityClassId = 'FILE' 
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
                    $updatedPDF = Update-VaultFile -File $PDFfile._FullPath -Properties $props
                    $attachToParentFile = Update-VaultFile -File $vfile._FullPath -AddAttachments @($updatedPDF._FullPath)
                    if(-not([string]::IsNullOrEmpty($attachToParentFile))){
                        $CSVContent += Add-StatusReport -CSV $CSVContent -Filename $PDFCompleteName -Status "Successfully Migrated!" -Message "Successfully Migrated" -ParentFile $vfile._Name -ParentId $vfile.Id
                    } 
                    else {
                        if([string]::IsNullOrEmpty($PDFfile)){
                            $CSVContent += Add-StatusReport -CSV $CSVContent -Filename $PDFCompleteName -Status "Error" -Message "Upload Error"
                        } elseif([string]::IsNullOrEmpty($updatedPDF)) {
                            $CSVContent += Add-StatusReport -CSV $CSVContent -Filename $PDFCompleteName -Status "Error" -Message "Without Properties" -ParentFile $vfile._Name 
                        } elseif([string]::IsNullOrEmpty($attachToParentFile)){
                            $CSVContent += Add-StatusReport -CSV $CSVContent -Filename $PDFCompleteName -Status "Error" -Message "Not Attached" -ParentFile $vfile._Name 
                        } else {
                            $CSVContent += Add-StatusReport -CSV $CSVContent -Filename $PDFCompleteName -Status "Error" -Message "Unknown"
                        }
                    }
                }
            }    
        } 
        else {
            $CSVContent += Add-StatusReport -CSV $CSVContent -Filename $PDFs[0]["$($PDFfileName)"] -Status "Error" -Message "No Local PDF"
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