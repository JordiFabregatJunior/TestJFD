Describe "Import Job" {
#    Import-Module PowerVault
    $testsBaseDirectory = (Get-Item $PSCommandPath).Directory.Parent.Parent.FullName
    Import-Module "$testsBaseDirectory\Pester.Base.Extensions.psm1"
    $jobName = "coolOrange.Import.Boms.From.Abas"

    Context "Run job wiht simple one layered Bom where all items and project folder already exist." {
        
        mock -CommandName "Convert-BomFromCsv" -Verifiable -MockWith { 
            @{
                 "Number" = "11"
                 "CSVFileName" = "Auftrags-Artikel-123987.csv"
                 "VorgangsPosition" = "99"
                 "Vorgangsnummer" = "345"
                 "Projektnummer" = "546"
                 "Children" = @(
                    @{
                        "Number" = "22"
                        "ParentNumber" = "11_99"
                        "Quantity" = "31"
                        "Position" = "1"
                        "Zeilenreihenfolge" = "1"
                        "TAGNummer" = "12"
                        "Länge" = "51"
                        "Children" = @()
                    },
                    @{
                        "Number" = "33"
                        "ParentNumber" = "11_99"
                        "Quantity" = "69"
                        "Position" = "2"
                        "Zeilenreihenfolge" = "2"
                        "TAGNummer" = "12"
                        "Länge" = "54"
                        "Children" = @()
                    }
                 ) 
            } 
        }
        mock -CommandName "Copy-VaultItemProperties" -Verifiable
        mock -CommandName "Add-VaultItemIfNotExists" -Verifiable
        mock -CommandName "Update-VaultItem" -Verifiable
        mock -CommandName "Add-VaultItemBomRow" -Verifiable -MockWith { "CreatedBom" }
        mock -CommandName "Initialize-AbasPaths" -Verifiable
        mock -CommandName "Update-VaultItemBomRow" -Verifiable
        mock -CommandName "Get-VaultItemBom" -Verifiable -MockWith { @{ "Number" = "Test"; "Children" = @() } }
        mock -CommandName "Start-CsvProcess" -Verifiable -MockWith {
            $converted = Invoke-Command $ConvertCsv -ArgumentList @("C:\temp\MyCsv.CSV")
            Invoke-Command $Operation -ArgumentList @($converted)
        }
        mock -CommandName "Get-VaultFolder" -Verifiable -ParameterFilter { 
            $Path -eq "$/Konstruktion/Projekte/546"
        } -MockWith { New-Object PSObject -Property @{ "FullName" = "$/Konstruktion/Projekte/546" } }
        mock -CommandName "Add-VaultFolderWithCategory" -Verifiable -ParameterFilter {
            $Path -eq "$/Konstruktion/Projekte/546/345"
        } -MockWith { New-Object PSObject -Property @{ "FullName" = "$/Konstruktion/Projekte/546/345" } }
        mock -CommandName "Add-VaultFolderWithCategory" -Verifiable -ParameterFilter {
            $Path -eq "$/Konstruktion/Projekte/546/345/99"
        } -MockWith { New-Object PSObject -Property @{ "FullName" = "$/Konstruktion/Projekte/546/345/99" ; "Id" = "2392"} }
        mock -CommandName "Get-VaultItem" -Verifiable -MockWith { New-Object PsObject -Property @{ "Id" = 22481;"Number" = "99" } }

        . "$($env:POWERJOBS_JOBSDIR)\$jobName.ps1"
        #.(Join-Path $env:POWERJOBS_JOBSDIR "$jobName.ps1")

        it "Folder path for CSV files is set correctly" {
            Assert-MockCalled -CommandName Start-CsvProcess -ParameterFilter {
                $CsvDirectory -eq "\\htt-abas\schnittstellen\vault\vorgaenge\export"
            }
        }
        it "Abas paths are initialized" {
            Assert-MockCalled -CommandName Initialize-AbasPaths -ParameterFilter {
                $Root -eq "\\htt-abas\schnittstellen\vault\vorgaenge\export"
            }
        }
        it "Adds two BomRows to root item" {
            Assert-MockCalled -CommandName Add-VaultItemBomRow -ParameterFilter {
                $ParentNumber -eq "11_99" -and $BomRowNumber -eq "22"# -and $Quantity -eq "31" -and $Position -eq "1"
            }
            Assert-MockCalled -CommandName Add-VaultItemBomRow -ParameterFilter {
                $ParentNumber -eq "11_99" -and $BomRowNumber -eq "33" #-and $Quantity -eq "69" -and $Position -eq "2"
            }
        }

        it "Updates Auftragsartikel (root) with UDPs like 'AbasExportCSV' with CSV Filename" {            
            Assert-MockCalled -CommandName Update-VaultItem -ParameterFilter {
                $Number -eq "11_99" -and (Compare-Object -ReferenceObject $Properties -DifferenceObject @{ 
                    "AbasExportCSV" = "Auftrags-Artikel-123987.csv"
                    "Vorgangsnummer" = "345"
                    "Projektnummer" = "546"
                    "VorgangsPosition" = "99"
                }) -eq $null
            }
        }

        it "Copies Vault properties from original imported Item to new added Auftragsartikel" {
            Assert-MockCalled -CommandName Copy-VaultItemProperties -ParameterFilter {
                $SourceItemNumber -eq "11" -and $DestinationItemNumber -eq "11_99" -and (Compare-Object -ReferenceObject $Properties -DifferenceObject @( 
                    "Title", "Typ / Abmessung" , "DN / Zoll" , "PN / Druckstufe", "Abmessung DIN", "Norm Dichtleiste", "Werkstoff", "Norm-Werkstoff", "Nachweis / Prüfvorschrift", "Zeugnis EN10204", "Anschluss DIN", "Suchwort", "Kennung", "Hersteller", "AbasArtikelID"
                )) -eq $null
            }
        }

        it "Added sub-folder 'Vorgangsnummer' with category 'Projekt' in vault project folder identified with the 'Projektnummer'" {
            Assert-MockCalled -CommandName "Add-VaultFolderWithCategory" -ParameterFilter {
                $Path -eq "$/Konstruktion/Projekte/546/345" -and $Category -eq "Projekt"
            }
        }
        it "Added sub-folder 'VorgangsPosition' in the vault folder 'Vorgangsnummer' with category 'Projekt'" {
            Assert-MockCalled -CommandName "Add-VaultFolderWithCategory" -ParameterFilter {
                $Path -eq "$/Konstruktion/Projekte/546/345/99" -and $Category -eq "Projekt"
            }
        }
        it "Added subfolder 'Berechnungen' with category 'Projekt' to vault folder 'VorgangsPosition'" {
            Assert-MockCalled -CommandName Add-VaultFolderWithCategory -ParameterFilter {
                $Path -eq "$/Konstruktion/Projekte/546/345/99/Berechnungen" -and $Category -eq "Projekt"
            }
        }
        it "Added subfolder 'Konstruktionsdaten' with category 'Projekt' to vault folder 'VorgangsPosition'" {
            Assert-MockCalled -CommandName Add-VaultFolderWithCategory -ParameterFilter {
                $Path -eq "$/Konstruktion/Projekte/546/345/99/Konstruktionsdaten" -and $Category -eq "Projekt"
            }
        }
        it "Added subfolder 'Nebendokumente' with category 'Projekt' to vault folder 'VorgangsPosition'" {
            Assert-MockCalled -CommandName Add-VaultFolderWithCategory -ParameterFilter {
                $Path -eq "$/Konstruktion/Projekte/546/345/99/Nebendokumente" -and $Category -eq "Projekt"
            }
        }
    }
}