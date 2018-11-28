Add-Log "*** Start Job to Import Abas Projects to Vault"

$AbasDirectory = "\\htt-abas\schnittstellen\vault\Projekte"

# For Debugging
#$AbasDirectory = "C:\TEST-Abas"
#Import-Module powerVault
#Open-VaultConnection -Vault HTT_Testsystem -User coolorange -Password technopart -Server vaultsrv
#Import-Module powerJobs

Initialize-AbasPaths -Root $AbasDirectory
$vaultRootProjectFolder = "$/Konstruktion/Projekte"

Start-CsvProcess -CsvDirectory $AbasDirectory -ConvertCsv { param($FilePath) Convert-ProjectFromCsv -FilePathCsv $FilePath } -Operation {
    param($importedItem)
    $folderName = $importedItem["Name"]
    $importedItem.Remove("Name")

    Add-Log "Start Import Project Folder: $folderName"

    $existingVaultFolder = Get-VaultFolder -Path "$vaultRootProjectFolder/$folderName"
    if(-not $existingVaultFolder) {
        $existingVaultFolder = Add-VaultFolder -Path "$vaultRootProjectFolder/$folderName" -Force
        if(-not $existingVaultFolder) {
            Add-Log "Failed to add Vault Folder $folderName"
            return 
        }
    }
    $importedItem.Add("Category", "Projekt")
    return (Update-VaultFolder -Folder $existingVaultFolder -Properties $importedItem)
}

Add-Log "*** Finished Job to Import Abas Projects to Vault!"