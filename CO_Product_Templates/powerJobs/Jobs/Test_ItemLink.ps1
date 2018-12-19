$vault.DocumentService.AddLink($Folder.Id,"FILE",$IDWFile.Id,"")


Add-Log "*** Start Job to Import Abas BOM to Vault"

$AbasDirectory = "\\htt-abas\schnittstellen\vault\vorgaenge\export"

# For Debugging
#$AbasDirectory = "C:\TEST-Abas"
#Import-Module powerVault
#Open-VaultConnection -Vault HTT_Testsystem -User coolorange -Password technopart -Server vaultsrv
#Import-Module powerJobs

function Add-VaultBom {
        param(
            $AbasBom
        )
    Add-Log "Start processing BOM $($AbasBom["Number"])"
    $existingBom = Get-VaultItemBom -Number $AbasBom["Number"]
   foreach($abasChild in $AbasBom["Children"]) {
        Add-Log "Start adding BomRow $($abasChild["Number"]) for Parent $($abasChild["ParentNumber"])"

        $bomHeaderNumber = $abasChild["ParentNumber"]
        $bomRowNumber = $abasChild["Number"]
        Add-VaultItemIfNotExists -ItemNumber $abasChild["Number"]
        if($abasChild["Children"].Length -gt 0) {
            $vaultItemBom = Add-VaultBom -AbasBom $abasChild
        }

        $rowAlreadyExists = $existingBom | where { $_.Bom_Number -eq $bomRowNumber -and $_.Bom_RowOrder -eq $abasChild["Zeilenreihenfolge"] -and $_.Bom_PositionNumber -eq $abasChild["Position"] }
        if($rowAlreadyExists) {
            Add-Log "$bomRowNumber existiert bereits für $bomHeaderNumber mit der identischen Zeilenreihenfolge und Position"
        } else {
            $vaultItemBom = Add-VaultItemBomRow -ParentNumber $bomHeaderNumber -BomRowNumber $bomRowNumber -Quantity $abasChild["Quantity"] -Position $abasChild["Position"] -BOMOrder $abasChild["Zeilenreihenfolge"]
        }

        @("Quantity", "Position", "Number", "Zeilenreihenfolge", "ParentNumber", "Stufe", "Children") | foreach {
            $abasChild.Remove($_)
        }
        Update-VaultItemBomRow -ParentNumber $bomHeaderNumber -BomRowNumber $bomRowNumber -Properties $abasChild
        $updatedVaultItem = Update-VaultItem -Number $bomRowNumber -Properties @{ 
            "Vorgangsnummer" = "$($abasChild["Vorgangsnummer"])"
            "Projektnummer" = "$($abasChild["Projektnummer"])"
            "VorgangsPosition" = "$($abasChild["VorgangsPosition"])"
            "AbasArtikelID" = "$($abasChild["AbasArtikelID"])"
            "Übereinstimmungswert" = "$($abasChild["Übereinstimmungswert"])"
        }
    }
    if(-not $vaultItemBom) {
        return $existingBom
    }
    return $vaultItemBom
}

function Set-VaultAuftragsItem($ItemNumber, $OldItemNumber) {
    Add-VaultItemIfNotExists -ItemNumber $ItemNumber
    Copy-VaultItemProperties -SourceItemNumber $OldItemNumber -DestinationItemNumber $ItemNumber -Properties @(
        "Title", "Typ / Abmessung" , "DN / Zoll" , "PN / Druckstufe", "Abmessung DIN"
        "Norm Dichtleiste", "Werkstoff", "Norm-Werkstoff", "Nachweis / Prüfvorschrift", "Zeugnis EN10204"
        "Anschluss DIN", "Suchwort", "Kennung", "Hersteller", "AbasArtikelID"
    )
    $updatedVaultRootItem = Update-VaultItem -Number $ItemNumber -Properties @{ 
        "AbasExportCSV" = "$($importedBom["CSVFileName"])"
        "Vorgangsnummer" = "$($importedBom["Vorgangsnummer"])"
        "Projektnummer" = "$($importedBom["Projektnummer"])"
        "VorgangsPosition" = "$($importedBom["VorgangsPosition"])"
        "AbasArtikelID" = "$($importedBom["AbasArtikelID"])"
        "Übereinstimmungswert" = "$($importedBom["Übereinstimmungswert"])"
    }
}

Initialize-AbasPaths -Root $AbasDirectory
$vaultRootProjectFolder = "$/Konstruktion/Projekte"

Start-CsvProcess -CsvDirectory $AbasDirectory -ConvertCsv { param($FilePath) Convert-BomFromCsv -FilePathCsv $FilePath } -Operation {
    param($importedBom)

    $originalItemNumber = $importedBom["Number"]
    $auftragsArtikelNumber = "$($originalItemNumber)_$($importedBom["VorgangsPosition"])"
    $importedBom["Number"] = $auftragsArtikelNumber
    $importedBom["Children"] | foreach { $_["ParentNumber"] = $auftragsArtikelNumber }
    
    Set-VaultAuftragsItem -ItemNumber $auftragsArtikelNumber -OldItemNumber $originalItemNumber

    $projectFolderPath = "$vaultRootProjectFolder/$($importedBom["Projektnummer"])"
    $projectVaultFolder = Get-VaultFolder -Path $projectFolderPath
    if(-not $projectVaultFolder) {
        throw "BOM Import wird abgebrochen, weil der Projekt Ordner in Vault nicht existiert: $projectFolderPath"
    }
    Add-Log "Projekt Ordner wurde in Vault gefunden: $projectFolderPath"

    $vaultFolderCategory = "Projekt"
    $auftragsVaultFolder = Add-VaultFolderWithCategory -Path "$($projectVaultFolder.FullName)/$($importedBom["Vorgangsnummer"])" -Category $vaultFolderCategory
    $positionsVaultFolder = Add-VaultFolderWithCategory -Path "$($auftragsVaultFolder.FullName)/$($importedBom["VorgangsPosition"])" -Category $vaultFolderCategory
    @("Berechnungen", "Konstruktionsdaten", "Nebendokumente") | foreach {
        Add-VaultFolderWithCategory -Path "$($positionsVaultFolder.FullName)/$_" -Category $vaultFolderCategory
    }
    $vaultItemBom = Add-VaultBom -AbasBom $importedBom    
    $vItem = Get-VaultItem -Number $auftragsArtikelNumber
    $vault.DocumentService.AddLink($positionsVaultFolder.Id,"ITEM",$vItem.Id,"")
    return $vaultItemBom
}

Add-Log "*** Finished Job to Import Abas BOM to Vault!"