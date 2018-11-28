function New-ProfileXml($Directory, $File) {
	$Properties = @{ }
	(Get-ProfilesVaultMapping -Category $File._CategoryName) | foreach {
		$xmlTagName = Get-ProfilesXmlMapping -VaultProperty $_
		if(-not [string]::IsNullOrEmpty($File."$_")) {
			$Properties.Add($xmlTagName, $File."$_")
		}
	}
    $Properties.Add("test_property", $File.Test)
	$categoryShortcut = (Get-ProfilesStaticMapping -Category $file._CategoryName)["CAT"]
	$uniqueNameScheme = "$($categoryShortcut)_$($File.'N° de pièce')$($File._Revision)"
	
	$Properties.Add("pdf_file_name", "$($uniqueNameScheme).pdf")
	$Properties.Add("part_number_revision", "$($File.'N° de pièce')$($File._Revision)")

		Add-Log "Assembly gets dependencies via file associations"
		(Get-VaultFileAssociations -File $file._FullPath -Dependencies) | foreach {
			$uptoDateDependency =  Get-VaultFile -File $_._FullPath
			if(Test-ValidProfileCategory -File $uptoDateDependency) {
				Add-Log "Adds '$($uptoDateDependency._PartNumber)' with category '$($uptoDateDependency._CategoryName)' to its XML."
				$Properties[$uptoDateDependency._CategoryName.Replace(" ", "_")] += @("$($uptoDateDependency._PartNumber)$($uptoDateDependency._Revision)")
			}
		}
	New-BoegliXml -Destination "$($Directory)\$($uniqueNameScheme).xml" -Properties $Properties
}

###____________MyThings

$Destination = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\Boegli\boegli.xml"
$Properties = @{"angle" = 40.00; "pas"= $null; "part_number_revision" = "PR900002-"; "cote_client_min" = "0.191 mm"}
AddXmlElement -xml $xml -name "pas" -value $property["pas"]
$xml.Save($destination)
function AddXmlElement($xml, $name, $value)
$contentXML = Get-Content -Path $destination -Encoding UTF8
#

foreach ($line in $contentXML){
    foreach ($car in $line){
        $line
        break
    }
}

function AddXmlElement($xml, $name, $value){
    $elem = $xml.CreateElement($name)
    if($value -eq $null){
        $elem.InnerText = [string]::Empty
    }
    else { 
        $elem.InnerText = $value 
    }
    $xml.DocumentElement.AppendChild($elem)
}

function New-BoegliXml($Destination, [hashtable]$Properties) {	
	[xml]$xml = "<Data/>"
	$Properties.GetEnumerator() | foreach {
		if($_.Value -and $_.Value.GetType().IsArray) {
			foreach($nestedPropertyNumber in $_.Value){
				Write-Host "Create category XML tag $($_.Key)"
				$xmlNode = AddXmlElement -xml $xml -name $_.Key -value $null
				$elem = $xml.CreateElement("part_number_revision")
				Write-Host "Create nested XML innertext $nestedPropertyNumber"
				$elem.InnerText = $nestedPropertyNumber
				($xmlNode.AppendChild($elem)) | Out-Null
                Show-Inspector
			}
		} else {
			(AddXmlElement -xml $xml -name $_.Key -value $_.Value) | Out-Null
		}
	}
	Write-Host "Trying to save XML to $($destination): $($xml.OuterXml)"
	$xml.Save($destination)	
	Write-Host "Successful saved XML:`n $((Get-Content -Path $destination -Encoding UTF8) -join "`n")"
}

New-BoegliXml -Destination $Destination -Properties $Properties