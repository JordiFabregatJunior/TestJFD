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

#ForDebugging:
#$file = "ANH-001000410_B"
#$filename = "ANH-001000410.ipt"
<#Testing NameWithoutRevision Extraction
foreach ($name in $ToTest){
    $returnedName = Get-FileNameWithoutRevision -filename $name
    Write-Host "$($returnedName)"
}


$CSVPath = 'C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\PDF-Info For testing.csv'
$ListPDFNames = @{} 
$PDFRows = (Get-Content -Path $CSVPath -Encoding UTF8) -split "\n"
foreach($Row in $PDFRows){
    $Elements = $Row -split ","
    if($Elements[2] -in @(".pdf")){
        [string]$filename = Get-FileNameWithoutRevision -filename $Elements[1]
        if(-not($ListPDFNames.ContainsKey($filename)) -or $ListPDFNames[$filename] -lt $Elements[1]){
            $ListPDFNames[$filename] = $Elements[3]    
        } <#else {
            #To Test if possible to add to previous if condition
            if($ListPDFNames[$filename] -lt $Elements[1]){
                $ListPDFNames[$filename] = $Elements[3]
            }
        }
    }
}
$ListPDFNames


foreach ($element in $PDFElements){
    Write-Host "$($element)"
}


$ListPDFNames = @{} 
$PDFRows = (Get-Content -Path $CSVPath -Encoding UTF8) -split "\n"
for($i =18; $i -lt 24; $i++){
    $Row = $PDFRows[$i] -split ","
    if($Row[2] -in @(".pdf")){
        [string]$filename = Get-FileNameWithoutRevision -filename $Row[1]
        if(-not($ListPDFNames.ContainsKey($filename))){
            $ListPDFNames[$filename] = $Row[3]    
        } else {
            #To Test if possible to add to previous if condition
            if($ListPDFNames[$filename] -lt $Row[1]){
                $ListPDFNames[$filename] = $Row[3]
            }
        }
    }
    <#$PDFRow = (Get-Content -Path $CSVPath -Encoding UTF8) -split "\n"
    $PDFElements = $PDFRow[$i] -split ","
    Write-Host "$($PDFElements[3])"
    foreach ($element in $PDFElements){
        Write-Host "$($element)" 
    }#> 
#>

###___ErrorTreatmentCases: 
<#
$CSVContent += [PSCustomObject]@{'Name' = "$($Name)"; 'Status' = "Successfully Migrated!"; 'Message' = "Attached to (ParentFullname): $($ParentName)"}
$CSVContent += [PSCustomObject]@{'Name' = "$($Name)"; 'Status' = "Error"; 'Message' = "Not found parent file"}
$CSVContent += [PSCustomObject]@{'Name' = "$($Name)"; 'Status' = "Error"; 'Message' = "More than one parent file"}
$CSVContent += [PSCustomObject]@{'Name' = "$($Name)"; 'Status' = "Migration Not needed"; 'Message' = "Is not PDF"}    
$CSVContent += [PSCustomObject]@{'Name' = "$($Name)"; 'Status' = "Migration Not needed"; 'Message' = "Not latest Version"}
#>   

$scriptRunTime = Measure-Command{
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
function Get-LatestPDFFileNames($CSVPath){
    $ListPDFNames = @{} 
    $PDFRows = (Get-Content -Path $CSVPath -Encoding UTF8) -split "\n"
    foreach($Row in $PDFRows){
        $Elements = $Row -split ","
        if($Elements[2] -in @(".pdf")){
            [string]$filename = Get-FileNameWithoutRevision -filename $Elements[1]
            if(-not($ListPDFNames.ContainsKey($filename)) -or $ListPDFNames[$filename] -lt $Elements[1]){
                $ListPDFNames[$filename] = $Elements[3]    
            } elseif($Elements[1] -lt $ListPDFNames[$filename]) {
                #LogsTreatment
                #$CSVContent += [PSCustomObject]@{'Name' = "$($Elements[3])"; 'Status' = "Error"; 'Message' = "Not latest Version"} 
            }
        } else {
            #$CSVContent += [PSCustomObject]@{'Name' = "$($Elements[3])"; 'Status' = "Migration Not needed"; 'Message' = "Is not PDF"}
        }
    }
    return $ListPDFNames
}

function Get-FileAssocParams($VFile){
    $parentAssociationType, $childAssociationType = @('All','All')
    $parentRecurse, $childRecurse = $false, $false
    $includeRelatedDocuments = $false
    $includeHidden = $true

    $fileAssocs = $vault.DocumentService.GetFileAssociationsByIds($VFile.Id, $parentAssociationType, $parentRecurse, $childAssociationType, $childRecurse, $includeRelatedDocuments, $includeHidden)
    $fileAssocs = $fileAssocs[0]
    $fileAssocParams = @()
    if($fileAssocs.FileAssocs -ne $null){
	    foreach($fileAssoc in $fileAssocs.FileAssocs){
		    $fileAssocParam = New-Object Autodesk.connectivity.Webservices.FileAssocParam
		    $fileAssocParam.CldFileId = $fileAssoc.CldFile.Id
		    $fileAssocParam.ExpectedVaultPath = $fileAssoc.ExpectedVaultPath
		    $fileAssocParam.RefId = $fileAssoc.RefId
		    $fileAssocParam.Source = $fileAssoc.Source
		    $fileAssocParam.Typ = $fileAssoc.Typ
		    $fileAssocParams += $fileAssocParam
	    }
    }
    return ,$fileAssocParams
}

###___MAIN
$LogsPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\ErrorLogs\Logs.csv"
$network = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\SPX - PDF for tests"
$CSVContent = @()
$PDFs = Get-LatestPDFFileNames -CSVPath 'C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\SPX - ProjectFolder\PDF-Info For testing2.csv'

$entityClassId = 'FILE'
$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($entityClassId)

foreach ($PDFfileName in $PDFs.keys){
    $vfiles = @()
    $vfiles = Get-VaultFiles -Properties @{"Name" = "$($PDFfileName).dwg"}
    if ($vfiles.Count -eq 0){
        $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs["$($PDFfileName)"])"; 'Status' = "Error"; 'Message' = "Not found parent file"}
    } else {
        if($vfiles.Count -ge 2){
            $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs["$($PDFfileName)"])"; 'Status' = "Error"; 'Message' = "More than one parent file"}
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
            #GetFoldersByFileMasterId
            ###___DATA_FOR_ADDFILE
            $folder = $vault.DocumentService.GetFolderByPath($vFile.Path)
            $comment = "From pdf migration" #[string]::Empty
            $lastWrite = get-date
            $fileAssocParams = Get-FileAssocParams($vFile)
            $BOM = $null #$vault.DocumentService.GetBOMByFileId($vFile.Id)           
            $hidden = $false
            $uploadTicket = New-Object Autodesk.Connectivity.WebServices.ByteArray
            [string]$filename = "$($PDFfileName).pdf"
            $PDFfile = $Vault.DocumentService.AddUploadedFile($folder.Id,$filename,$comment,$lastWrite,$BOM,"None",$hidden,$uploadTicket)
            $PDFfile = Update-VaultFile -File $vaultPDFfileLocation -Properties $props
            $updatedFile = Update-VaultFile -File $vfile._FullPath -AddAttachments @($PDFfile._FullPath)
            $CSVContent += [PSCustomObject]@{'Name' = "$($PDFs["$($PDFfileName)"])"; 'Status' = "Successfully Migrated!"; 'Message' = "Attached to (ParentFullname): $($ParentName)"}
        }
    }
    #Clean-Up -folder $workingDirectory
}
$CSVContent | Export-Csv -Path $LogsPath -Delimiter ';' -NoTypeInformation
}
$measuringPerformance.add("Run $(Get-Date)", "Test Script(7 files): $($scriptRunTime.TotalMilliseconds) milliseconds // Expected Real Time: $($scriptRunTime.TotalHours*12000/7) hours")
$measuringPerformance.GetEnumerator() | Sort-Object Name -Descending
Write-host "The script took $($scriptRunTime.TotalMilliseconds) milliseconds"


#pass in a powerVault Fileobject



<#
function Rename-File($PVaultFile,$NewFileName){
    $fileExtension = [System.IO.Path]::GetExtension($PVaultFile.Name)
    $newFileName = "$($NewFileName)" + "$($fileExtension)"
    $vFile = $vault.DocumentService.GetLatestFileByMasterId($PVaultFile.MasterId)

    if($vFile.CheckedOut){
        throw "The file $($vFile.Name) is already checked out, so it can't be renamed"
    }

    $fileAssocParams = GetFileAssocParams($vFile)
    $BOM = $vault.DocumentService.GetBOMByFileId($vFile.Id)
    $downloadTicket = New-Object Autodesk.Connectivity.WebServices.ByteArray
    $lastWrite = $vFile.ModDate
    $comment = [string]::Empty
    $buffer = New-Object Autodesk.Connectivity.WebServices.ByteArray

    $CheckedOutFile = $vault.DocumentService.CheckoutFile($vFile.Id, "Master", [System.Environment]::MachineName, $vFile.LocalPath, $comment, [ref] $buffer)
    try {
        if($CheckedOutFile){
            $CheckedInFile = $vault.DocumentService.CheckinUploadedFile($vFile.MasterId,"",$false,$lastWrite,$fileAssocParams,$BOM,$false,$newFileName,$vFile.FileClass,$hidden,$null)
        }
    }
    catch {
        $UndoCheckedOutFile = $vault.DocumentService.UndoCheckoutFile($vFile.MasterId,[ref]$downloadTicket)
        throw "The file $($vFile.Name) could not be checked out. Ensure there is no existing file with same filename"
    }
}
#>