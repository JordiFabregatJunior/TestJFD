function New-ProfileXml($Directory, $File) {
	$Properties = @{ }
    $counter = 0
	(Get-ProfilesVaultMapping -Category $File._CategoryName) | foreach {
		$xmlTagName = Get-ProfilesXmlMapping -VaultProperty $_
		if(-not [string]::IsNullOrEmpty($File."$_")) {
			$Properties.Add($xmlTagName, @{"Position" = $counter; "Property_Value" = $File."$_"})
            $counter += 1
		}
	}
	$categoryShortcut = (Get-ProfilesStaticMapping -Category $file._CategoryName)["CAT"]
	$uniqueNameScheme = "$($categoryShortcut)_$($File.'N° de pièce')$($File._Revision)"
	
	$Properties.Add("pdf_file_name", @{"Position" = $counter; "Property_Value" = "$($uniqueNameScheme).pdf"}); $counter += 1
	$Properties.Add("part_number_revision", @{"Position" = $counter; "Property_Value" = "$($File.'N° de pièce')$($File._Revision)"}); $counter += 1
	if($File._Extension -eq "iam") {
		Add-Log "Assembly gets dependencies via file associations"
		(Get-VaultFileAssociations -File $file._FullPath -Dependencies) | foreach {
			$uptoDateDependency =  Get-VaultFile -File $_._FullPath
			if(Test-ValidProfileCategory -File $uptoDateDependency) {
				Add-Log "Adds '$($uptoDateDependency._PartNumber)' with category '$($uptoDateDependency._CategoryName)' to its XML."
				$Properties[$uptoDateDependency._CategoryName.Replace(" ", "_")] += @(@{"Position" = $counter; "Property_Value" = "$($uptoDateDependency._PartNumber)$($uptoDateDependency._Revision)"})
                $counter += 1
			}
		}
	}
	$xml = New-BoegliXml -Destination "$($Directory)\$($uniqueNameScheme).xml" -Properties $Properties -Counter $Counter
    return $xml
}

function New-BoegliXml($Destination, [hashtable]$Properties, $Counter) {	
	[xml]$xml = "<Data/>"
    $range = 0..$counter
    foreach ($position in $range){
	    $Properties.GetEnumerator() | foreach {
		    if($_.Value -and $_.Value.GetType().IsArray) {
			    foreach($nestedPropertyNumber in $_.Value){
                    if ($Position -eq $nestedPropertyNumber["Position"]){
				        Add-Log "Create category XML tag $($_.Key)"
				        $xmlNode = AddXmlElement -xml $xml -name $_.Key -value $null
				        $elem = $xml.CreateElement("part_number_revision")
				        Add-Log "Create nested XML innertext $nestedPropertyNumber"
				        $elem.InnerText = $nestedPropertyNumber["Property_Value"]
				        ($xmlNode.AppendChild($elem)) | Out-Null
	                }
                }
			} else {
                if ($Position -eq $_.Value["Position"]){
			        (AddXmlElement -xml $xml -name $_.Key -value $_.Value["Property_Value"]) | Out-Null
		        }
            }
        }
    }
	Add-Log "Trying to save XML to $($destination): $($xml.OuterXml)"
	$xml.Save($destination)	
	Add-Log "Successful saved XML:`n $((Get-Content -Path $destination -Encoding UTF8) -join "`n")"
}