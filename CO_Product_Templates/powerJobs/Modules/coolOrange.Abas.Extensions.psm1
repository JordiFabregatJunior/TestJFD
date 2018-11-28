function Initialize-AbasPaths {
    param(
        $Root
    )
    $global:AbasErrorDirectory = "$Root\Error"
    $global:AbasArchiveDirectory = "$Root\Archiv"
    
    @($Root, $AbasErrorDirectory, $AbasArchiveDirectory) | foreach {
        if(-not (Test-Path -Path $_)) {
            throw "Required Path does not exist and job gets aborted: $_"
        }
    }
    
    Add-Log "Directory for the operation: $Root"
    Add-Log "Directory for errors: $AbasErrorDirectory"
    Add-Log "Directory for successful: $AbasArchiveDirectory"
}

function Start-CsvProcess {
    param(
        $CsvDirectory,
        [scriptblock]$ConvertCsv,
        [scriptblock]$Operation
    )
    $allCsvFiles = (Get-ChildItem -Path $CsvDirectory -Filter "*.csv")
    $limit = 500
    if($allCsvFiles.Length -gt $limit) {
        Add-Log "LIMIT of processing files in one job is set to $limit , otherwise the RAM are increased to much. Currently in the folder are $($allCsvFiles.Length) files"
    }
    $allCsvFiles | select -First $limit | foreach {
    
        try {
            $timeStamp = Get-Date -Format "ddMMyyyy_HHmmss"
            $newFileName = (Split-Path $_.FullName -Leaf) -replace @("\.$($_.Extension.TrimStart('.'))", "_$($timeStamp)$($_.Extension)")
            $importContent = Invoke-Command -ScriptBlock $ConvertCsv -ArgumentList @($_.FullName)
            $importedVaultEntity = Invoke-Command -ScriptBlock $Operation -ArgumentList @($importContent)
        } catch {
            Add-Log $_.Exception.Message
        }
        
        if(-not $importedVaultEntity) {
            $errorFileLocation = "$($global:AbasErrorDirectory)\$newFileName"
            Move-Item -Path $_.FullName -Destination $errorFileLocation -Force
            Add-Log "Failed to import into vault, therefore moved file to $errorFileLocation!"
        } else {
            $newLocation = "$($global:AbasArchiveDirectory)\$newFileName"
            Move-Item -Path $_.FullName -Destination $newLocation -Force
            Add-Log "Moved to $newLocation"
        }
    }
}


function Convert-FromCsv {
    param($FilePathCsv)
    Add-Log "Parsing $FilePathCsv"
    $fileContentSeperated = (Get-Content -Path $FilePathCsv -Encoding UTF8) -split "#"
    @{
        "Nummer" = $fileContentSeperated[0]
        "Übereinstimmungswert" = $fileContentSeperated[0]
        "Title" = $fileContentSeperated[1]
        "Typ / Abmessung" = $fileContentSeperated[2]
        "DN / Zoll" = $fileContentSeperated[3]
        "PN / Druckstufe" = $fileContentSeperated[4]
        "Abmessung DIN" = $fileContentSeperated[5]
        "Norm Dichtleiste" = $fileContentSeperated[6]
        "Werkstoff" = $fileContentSeperated[7]
        "Norm-Werkstoff" = $fileContentSeperated[8]
        "Nachweis / Prüfvorschrift" = $fileContentSeperated[9]
        "Zeugnis EN10204" = $fileContentSeperated[10]
        "Anschluss DIN" = $fileContentSeperated[11]
        "Suchwort" = $fileContentSeperated[12]
        "Kennung" = $fileContentSeperated[13]
        "Hersteller" = $fileContentSeperated[14]
        "AbasArtikelID"=$fileContentSeperated[15]
    }
}

function Convert-ProjectFromCsv {
    param($FilePathCsv)
    Add-Log "Parsing Project from $FilePathCsv"
    $fileContentSeperated = (Get-Content -Path $FilePathCsv -Encoding UTF8) -split "#"
    @{
        "Name" = $fileContentSeperated[0]
        "Angebots / Auftrags Nr." = $fileContentSeperated[0]
        "Firma" = $fileContentSeperated[1]
        "Beschreibung" = $fileContentSeperated[2]
        "Wärmeträger" = $fileContentSeperated[3]
        "zul. max. Temp" = $fileContentSeperated[4]
        "zul. max. Druck" = $fileContentSeperated[5]
        "Kundenprojekt" = $fileContentSeperated[6]
    }
}

function Get-ElementAt($Array, $Index, [switch]$RemoveStringEmpty = $false) {
    if($Index -lt $Array.Length) {
        if($RemoveStringEmpty) {
            return ($Array[$Index]) -replace @(" ", "")
        }
        return $Array[$Index]
    }
}

function Convert-BomRowFromCsv($BomRowAbas) {
    Add-Log "Parsing BomRow: $BomRowAbas"
    $fileContentSeperated = $BomRowAbas -split "#"

    $stufeInt = $null
    if(-not [int]::TryParse($fileContentSeperated[3], [ref]$stufeInt)) {
        throw "'Stufe' muss ein Integer Wert sein, der Wert von Spalte 4 war: $($fileContentSeperated[2])"
    }
    @{
        "ParentNumber" = ""
        "Vorgangsnummer" = (Get-ElementAt -Array $fileContentSeperated -Index 0 -RemoveStringEmpty)
        "Projektnummer" = $fileContentSeperated[1]
        "VorgangsPosition" = $fileContentSeperated[2]
        "Stufe" = $stufeInt
        "Position" = $fileContentSeperated[4]
        "Zeilenreihenfolge" = $fileContentSeperated[5]
        "Number" = $fileContentSeperated[6]
        "Übereinstimmungswert" = $fileContentSeperated[6]
        "Länge" = "$($fileContentSeperated[7]) $($fileContentSeperated[8])"
        "Breite" = "$($fileContentSeperated[9]) $($fileContentSeperated[10])"
        "Quantity" = $fileContentSeperated[11]
        "Einheit" = $fileContentSeperated[12]
        "Positionstext" = $fileContentSeperated[13]
        "TAGNummer" = $fileContentSeperated[14]
        "Aktiv" = $fileContentSeperated[15]
        "AbasArtikelID" = $fileContentSeperated[16]
        "Reservierungs ID" = $fileContentSeperated[17]
        "Children" = @()
    }    
}

function Convert-BomFromCsv {
    param($FilePathCsv)
    Add-Log "Parsing BOM from $FilePathCsv"
    
    $abasBomRows = (Get-Content -Path $FilePathCsv -Encoding UTF8) -split "\n" | foreach {  
        $convertedBomRow = Convert-BomRowFromCsv -BomRowAbas $_ 
        $convertedBomRow["CSVFileName"] = Split-Path -Path $FilePathCsv -Leaf
        $convertedBomRow
    }
    $currentParent = $rootBomHeader = ($abasBomRows | select -First 1)
    for ($i = 1; $i -lt $abasBomRows.Length; $i++) {
        
        # If this row is direct below the parent
        if(($abasBomRows[$i])["Stufe"] - 1 -eq $currentParent["Stufe"]) {
            $currentParent["Children"] += $abasBomRows[$i]
            ($abasBomRows[$i])["ParentNumber"] = $currentParent["Number"]
        } else {            
            $parentIteration = $i
            # Searches the parent row: Goes one row up until it finds the direct parent
            do {
                if($parentIteration -eq 0) {
                    throw "Stücklisten-Kopf von folgender Position wurde nicht gefunden: $(($abasBomRows[$i])["Number"])"
                }
                $parentIteration--
            } while (($abasBomRows[$i])["Stufe"]-1 -ne ($abasBomRows[$parentIteration])["Stufe"])
            $currentParent = $abasBomRows[$parentIteration]
            $currentParent["Children"] += $abasBomRows[$i]
            ($abasBomRows[$i])["ParentNumber"] = $currentParent["Number"]
        }
    }
    return $rootBomHeader
}

function Convert-BomRowToCsv {
    param($BomRow, [int]$Stufe)
    Add-Log "Convert to CSV Bom Row $($BomRow._Number)"

    $sequenceDefinitions = @{
        0 = $BomRow.Vorgangsnummer
        1 = $BomRow.Projektnummer
        2 = $BomRow.VorgangsPosition
        3 = $Stufe
        4 = $BomRow.Bom_PositionNumber
        5 = $BomRow.Bom_RowOrder
        6 = $BomRow._Number
        7 = $BomRow.Bom_Länge -replace "[^0-9]+,?.?[^0-9]+", ""
        8 = $BomRow.Bom_Länge -replace "[^a-z]", ""
        9 = $BomRow.Bom_Breite -replace "[^0-9]+,?.?[^0-9]+", ""
        10 = $BomRow.Bom_Breite -replace "[^a-z]", ""
        11 = $BomRow.Bom_Quantity 
        12 = $BomRow.Bom_Unit
        13 = $BomRow.Positionstext
        14 = $BomRow.TAGNummer
        15  = $BomRow.Aktiv
        16  = $BomRow.AbasArtikelID 
        17  = $BomRow."Bom_Reservierungs ID"
        18 = if($BomRow.Bom_IsCad) { "CAD"} else { "Manuell" }
    }
    if([string]::IsNullOrEmpty($BomRow.Vorgangsnummer) -or [string]::IsNullOrEmpty($BomRow.Projektnummer) -or [string]::IsNullOrEmpty($BomRow.VorgangsPosition)) {
        throw "Failed BOM export, because properties for $($BomRow._Number) are not set: Vorgangsnummer, Projektnummer, VorgangsPosition"
    }
    $highestNumber = $sequenceDefinitions.Keys | sort | select -Last 1
    $csv = ""
    for ($i = 0; $i -le $highestNumber; $i++) {
        $csv += "$($sequenceDefinitions[$i])#"
    }
    return $csv
}

function Convert-BomToCsv {
    param($Bom, $Stufe = 0)
    Add-Log "Convert to CSV bom $($bom._Number)"
    $csvs = @()
    $csvs += Convert-BomRowToCsv -BomRow $Bom -Stufe $Stufe
    $Stufe++
    $Bom.Children | foreach {
        if($_.Children) {
            $csvs += Convert-BomToCsv -Bom $_ -Stufe $Stufe
        } else {
            $csvs += Convert-BomRowToCsv -BomRow $_ -Stufe $Stufe
        }
    }
    return $csvs
}

function Add-Link($Number, $Folder){
    $pvItem = Get-VaultItem -Number $Number
    $linksOnFolder = $vault.DocumentService.GetLinksByParentIds($Folder.Id, "ITEM")
    [array]$vaultFilesIdsWithLinks= @()
    foreach ($link in $linksOnFolder){
	    $vaultFilesIdsWithLinks += $link.ToEntId
    }
    if ($pvItem.Id -notin $vaultFilesIdsWithLinks){
        $link = $vault.DocumentService.AddLink($Folder.Id,"ITEM",$pvItem.Id,"")
    }
}