Add-Log "*** Start Job to Import Abas Items to Vault"

$AbasDirectory = "\\htt-abas\schnittstellen\vault\stammdaten"

# For Debugging
#$AbasDirectory = "C:\TEST-Abas"
#Import-Module powerVault
#Open-VaultConnection -Vault HTT_Testsystem -User coolorange -Password technopart -Server vaultsrv
#Import-Module powerJobs

Initialize-AbasPaths -Root $AbasDirectory

Start-CsvProcess -CsvDirectory $AbasDirectory -ConvertCsv { param($FilePath) Convert-FromCsv -FilePathCsv $FilePath } -Operation {
    param($importedItem)
    $itemNumber = $importedItem["Nummer"]
    $importedItem.Remove("Nummer")

    $existingVaultItem = Get-VaultItem -Number $itemNumber
    if(-not $existingVaultItem) {
        if(-not (Add-VaultItem -ItemNumber $itemNumber)) { return }
        Add-Log "Artikel wurde erfolgreich in Vault erstellt!"
    }
    return (Update-VaultItem -Number $itemNumber -Properties $importedItem -Title $importedItem["Title"])
}

Add-Log "*** Finished Job to Import Abas Items to Vault!"