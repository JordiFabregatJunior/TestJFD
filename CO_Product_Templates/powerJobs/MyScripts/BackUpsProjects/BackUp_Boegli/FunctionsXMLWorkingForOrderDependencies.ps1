function New-ProfileXml($Directory, $File) {
	$Properties = @{ }
	(Get-ProfilesVaultMapping -Category $File._CategoryName) | foreach {
		$xmlTagName = Get-ProfilesXmlMapping -VaultProperty $_
		if(-not [string]::IsNullOrEmpty($File."$_")) {
			$Properties.Add($xmlTagName, $File."$_")
		}
	}
	$categoryShortcut = (Get-ProfilesStaticMapping -Category $file._CategoryName)["CAT"]
	$uniqueNameScheme = "$($categoryShortcut)_$($File.'N° de pièce')$($File._Revision)"
	
	$Properties.Add("pdf_file_name", "$($uniqueNameScheme).pdf")
	$Properties.Add("part_number_revision", "$($File.'N° de pièce')$($File._Revision)")
	<#if($File._Extension -eq "iam") {
		Add-Log "Assembly gets dependencies via file associations"
		(Get-VaultFileAssociations -File $file._FullPath -Dependencies) | foreach {
			$uptoDateDependency =  Get-VaultFile -File $_._FullPath
			if(Test-ValidProfileCategory -File $uptoDateDependency) {
				Add-Log "Adds '$($uptoDateDependency._PartNumber)' with category '$($uptoDateDependency._CategoryName)' to its XML."
				$Properties[$uptoDateDependency._CategoryName.Replace(" ", "_")] += @( "$($uptoDateDependency._PartNumber)$($uptoDateDependency._Revision)")
			}
		}
	}#>
	New-BoegliXml -Destination "$($Directory)\$($uniqueNameScheme).xml" -Properties $Properties -File $File
    #$testProp = $Properties["Profils_Standards"][0]
    #Show-Inspector
}
<#
function New-BoegliXml($Destination, [hashtable]$Properties) {	
	[xml]$xml = "<Data/>"
	$Properties.GetEnumerator() | foreach {
		if($_.Value -and $_.Value.GetType().IsArray) {
			foreach($nestedPropertyNumber in $_.Value){
				Add-Log "Create category XML tag $($_.Key)"
				$xmlNode = AddXmlElement -xml $xml -name $_.Key -value $null
				$elem = $xml.CreateElement("part_number_revision")
				Add-Log "Create nested XML innertext $nestedPropertyNumber"
				$elem.InnerText = $nestedPropertyNumber
				($xmlNode.AppendChild($elem)) | Out-Null
			}
		} else {
			(AddXmlElement -xml $xml -name $_.Key -value $_.Value) | Out-Null
		}
	}
	Add-Log "Trying to save XML to $($destination): $($xml.OuterXml)"
	$xml.Save($destination)	
	Add-Log "Successful saved XML:`n $((Get-Content -Path $destination -Encoding UTF8) -join "`n")"
}#>

function New-BoegliXml($Destination, [hashtable]$Properties, $File) {	
	[xml]$xml = "<Data/>"
	$Properties.GetEnumerator() | foreach {
		(AddXmlElement -xml $xml -name $_.Key -value $_.Value) | Out-Null
	}
    if($File._Extension -eq "iam") {
	    Add-Log "Assembly gets dependencies via file associations"
	    (Get-VaultFileAssociations -File $file._FullPath -Dependencies) | foreach {
		    $uptoDateDependency =  Get-VaultFile -File $_._FullPath
		    if(Test-ValidProfileCategory -File $uptoDateDependency) {
			    Add-Log "Adds '$($uptoDateDependency._PartNumber)' with category '$($uptoDateDependency._CategoryName)' to its XML."
                $Key = $uptoDateDependency._CategoryName.Replace(" ", "_")
                $value = "$($uptoDateDependency._PartNumber)$($uptoDateDependency._Revision)"
			    #$Properties[$key] += @($value)
		        Add-Log "Create category XML tag $($Key)"
			    $xmlNode = AddXmlElement -xml $xml -name $key -value $null
			    $elem = $xml.CreateElement("part_number_revision")
			    Add-Log "Create nested XML innertext $value"
			    $elem.InnerText = $value
			    ($xmlNode.AppendChild($elem)) | Out-Null
            }
	    }
	}
	Add-Log "Trying to save XML to $($destination): $($xml.OuterXml)"
	$xml.Save($destination)	
	Add-Log "Successful saved XML:`n $((Get-Content -Path $destination -Encoding UTF8) -join "`n")"
}