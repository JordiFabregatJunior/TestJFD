Add-Log "*** Started Job to Export Vault BOM to Abas for item $($item._Number)!"

$AbasDirectory = "\\htt-abas\schnittstellen\vault\vorgaenge\import"

# For Debugging
#$AbasDirectory = "C:\TEST-Abas"
#Import-Module powerVault
#Open-VaultConnection -Vault HTT_Testsystem -User coolorange -Password technopart -Server vaultsrv
#Import-Module powerJobs

function Get-VaultItemBomWithUDps {
    param($Number)
    Add-Log "Getting Item BOM for $Number"
    $itemBom = (Get-VaultItemBOM -Number $Number) | where { -not $_._Number.StartsWith("Vault-") }
    foreach ($itemBomRow in $itemBom) {
        $udpProperties = (Get-VaultItemBomProperties -ParentNumber $Number -BomRowNumber $itemBomRow._Number)
        $udpProperties.Keys | foreach {
            $itemBomRow | Add-Member -Name $_ -Value $udpProperties[$_] -MemberType NoteProperty
        }
    }
    return $itemBom
}

function Update-BomStructure {
    param($Item)
    Add-Log "Change children properties for item $($Item._Number)"
    $item.Children | foreach {
        if($_) {
            foreach($staticProperty in @("VorgangsPosition", "Projektnummer", "Vorgangsnummer")) {
                Add-Member -InputObject $_ -Name $staticProperty -Value $Item."$staticProperty" -MemberType NoteProperty -Force
            }
            $itemBom = Get-VaultItemBomWithUDps -Number $_._Number
            if($itemBom) {    
                foreach($bomRow in $itemBom) {
                    if($_.Bom_RowOrder) {
                        Add-Member -InputObject $bomRow -Name Bom_RowOrder -Value ("{0}.{1}" -f $_.Bom_RowOrder,$bomRow.Bom_RowOrder) -MemberType NoteProperty -Force
                    }
                }
                $_ | Add-Member -Name "Children" -MemberType NoteProperty -Value $itemBom
                Update-BomStructure -Item $_
            }
        }        
    }
}
$rootItemBom = Get-VaultItemBomWithUDps -Number $item._Number
$item | Add-Member -Name "Children" -MemberType NoteProperty -Value $rootItemBom
Update-BomStructure -Item $item

$csvs = Convert-BomToCsv -Bom $item
$csvContent = [string]::Join([System.Environment]::NewLine, $csvs)

$newFileName = "$($item.AbasExportCSV)"
if(-not $newFileName) {
    throw "Aborted job, because UDP 'AbasExportCSV' must be set for $($item._Number) to generate the CSV file."
}
$csvContent | Out-File -FilePath "$AbasDirectory\$newFileName" -Encoding utf8 -Force
Add-Log "File created: $AbasDirectory\$newFileName"

Add-Log "*** Finished Job to Export Vault BOM to Abas!"