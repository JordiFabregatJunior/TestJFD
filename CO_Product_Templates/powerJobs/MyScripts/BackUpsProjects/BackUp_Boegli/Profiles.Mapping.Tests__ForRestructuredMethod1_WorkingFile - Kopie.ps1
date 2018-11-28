$repositoryFolder = (Get-Item $PSCommandPath).Directory.Parent.Parent.Parent.FullName
Import-Module "$repositoryFolder\Files.Tests\Pester.Base.Extensions.psm1"
$ModuleName = "Profiles.Mapping"

Describe "New-ProfileXml" {
	mock -CommandName "Add-Log" -Verifiable -MockWith { Write-Host $Text }
	mock -CommandName "Clean-Up"
	mock -CommandName "Close-Document" -MockWith { $true }

	Context "Part (ipt) file has correct category for mapping" {
		mock -CommandName "New-BoegliXml" -ModuleName $ModuleName -MockWith { "success" }

		$vaultFile = New-PSVaultFile -Name "Test.ipt"
		$xml = New-ProfileXml -Directory "C:\temp\export" -File $vaultFile
		it "Adds static values to XML: pdf_file_name and part_number_revision" {
			Assert-MockCalled -CommandName "New-BoegliXml" -ModuleName $ModuleName -ParameterFilter {
				$expectedProperties = @{
					"numero_de_piece" = "6131"
					"revision" = "SX"
					"description" = "Parlo"
					"sens" = "Zenza"
					"compression_lat" = "Shortcut"
					"penetration" = "specialz"
					"profondeur_matrix" = "matrix"
					"cote_client_min" = "cotepièce"
					"conge" = "jaw`´ol"
					"part_number_revision" = "6131SX"
					"pdf_file_name" = "STA_6131SX.pdf"
				}
				((Compare-Hashtable $expectedProperties $Properties) | Should -BeNullOrEmpty) -eq $null
			}
		}
		it "Exported XML file name is generated out of vault properties" {
			Assert-MockCalled -CommandName "New-BoegliXml" -ModuleName $ModuleName -ParameterFilter {
				$Destination -eq "C:\temp\export\STA_6131SX.xml"
			}
		}
		it "Returns the generated XML" {
			$xml | Should -be "success"
		}
	}
	
	Context "Triggered for Assembly with some dependencies" {
		mock -CommandName "Test-ValidProfileCategory" -ModuleName $ModuleName -MockWith { $true }
		#mock -CommandName "AddXmlElement"
#		mock -CommandName "New-BoegliXml" -ModuleName $ModuleName -MockWith { "success" }
		mock -CommandName "Get-VaultFileAssociations" -ModuleName $ModuleName -ParameterFilter {
			$File -eq "$/Designs/PRC-9009.iam" -and $Dependencies.IsPresent
		} -MockWith {
			@(
				(New-PSVaultFile -Name "PRC-9009.idw")
				(New-PSVaultFile -Name "PRC-1001.ipt")
				(New-PSVaultFile -Name "Other Dependency.ipt")
				(New-PSVaultFile -Name "Other Dependency2.png")
			)
		}
		mock -CommandName "Get-VaultFile" -ModuleName $ModuleName -ParameterFilter { $File -eq "$/Designs/PRC-9009.idw" } -MockWith { New-PSVaultFile -Name "PRC-9009.idw" }
		mock -CommandName "Get-VaultFile" -ModuleName $ModuleName -ParameterFilter { $File -eq "$/Designs/PRC-1001.ipt" } -MockWith { New-PSVaultFile -Name "PRC-1001.ipt" }
		mock -CommandName "Get-VaultFile" -ModuleName $ModuleName -ParameterFilter { $File -eq "$/Designs/Other Dependency.ipt" } -MockWith { New-PSVaultFile -Name "Other Dependency.ipt" }
		mock -CommandName "Get-VaultFile" -ModuleName $ModuleName -ParameterFilter { $File -eq "$/Designs/Other Dependency2.png" } -MockWith { New-PSVaultFile -Name "Other Dependency2.png" }
		$vaultFile = New-PSVaultFile -Name "PRC-9009.iam"

		it "For Assembly dependencies _partNumber and _Revision are included and the dependencies are set at the end of the XML" {
			$xml = New-ProfileXml Directory "C:\temp\export"-File $vaultFile
			$RequiredProperties = @(
				"part_number_revision"
				"Profils_Standards"

			)
			#Assert-MockCalled -CommandName "New-BoegliXml" -ModuleName $ModuleName -ParameterFilter {
			<#$expectedProperties = @(
				"PRC-9009.idw 999SX"
				"PRC-1001.ipt 999SX"
				"Other Dependency.ipt 999SX"
				"Other Dependency2.png 999SX"
			)#>
			Check-XMLOrderedContent -xml $xml | Should -be $true
			#((Compare-Object -ReferenceObject $Properties["Profils_Standards"] -DifferenceObject $expectedProperties -SyncWindow 0 -CaseSensitive)| Should -BeNullOrEmpty) -eq $null
		}
		it "Returns the generated XML" {
			$xml = New-BoegliXml -Destination "C:\temp\export" -Properties @{} -File $vaultFile
			$xml | Should -not -be $null
		}
	}
}