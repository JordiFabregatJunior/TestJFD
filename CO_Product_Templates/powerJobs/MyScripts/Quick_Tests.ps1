Import-Module PowerVault
Open-VaultConnection -Server "2019-sv-12-E-JFD" -Vault "Demo-JF" -user "Administrator"

<#Update-VaultFile -File $vfile._FullPath -Properties @{“Manager”=“testingManager”}
$workingDirectory = "C:\Temp\$($file._Name)"
$downloadedFiles = Save-VaultFile -File $vfile._FullPath -DownloadDirectory $workingDirectory 
$vFileLocal = $downloadedFiles | select -First 1
#$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen } #>

$filename = "PART-BOX-0003.ipt"
$filename = "Main.iam"
$filename = "ASSY-0016.iam"	
$File = Get-VaultFile -Properties @{"Name" = $filename}
$Directory = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\Boegli"
$PropertiesAfterIAM = New-ProfileXml -Directory $Directory -File $File
$content = Get-Content -Path $vFileLocal.LocalPath
$folder = $vault.DocumentService.GetFolderByPath("$/Designs/Inventor/Test-Related-IDW")

function Get-PropertiesSorted($Properties) {
    $Properties = $Properties.GetEnumerator() | sort IsNestedXmlTag,@{ expression= {
        if ($_.Value -and $_.Value.GetType().IsArray) {
            $IsNestedXmlTag=”1” 
        } else {
            $IsNestedXmlTag=”0” 
        }
        add-member noteproperty “IsNestedXmlTag” $IsNestedXmlTag -InputObject $_
    } } 
    return $Properties | sort-Object IsNestedXmlTag
}

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
	if($File._Extension -eq "iam") {
		Write-Host "Assembly gets dependencies via file associations"
		(Get-VaultFileAssociations -File $file._FullPath -Dependencies) | foreach {
			$uptoDateDependency =  Get-VaultFile -File $_._FullPath
			if(Test-ValidProfileCategory -File $uptoDateDependency) {
				Write-Host "Adds '$($uptoDateDependency._PartNumber)' with category '$($uptoDateDependency._CategoryName)' to its XML."
				$Properties[$uptoDateDependency._CategoryName.Replace(" ", "_")] += @( "$($uptoDateDependency._PartNumber)$($uptoDateDependency._Revision)")
			}
		}
	}
	$Properties = Get-PropertiesSorted -Properties $Properties
    $hashProperties = @{}
    foreach ($Prop in $Properties){
        $hashProperties.add($Prop.key,$Prop.Value)
    }
	New-BoegliXml -Destination "$($Directory)\$($uniqueNameScheme).xml" -Properties $Properties
}

function New-BoegliXml($Destination, $Properties) {	
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
			}
		} else {
			(AddXmlElement -xml $xml -name $_.Key -value $_.Value) | Out-Null
		}
	}
	Write-Host "Trying to save XML to $($destination): $($xml.OuterXml)"
	$xml.Save($destination)	
	Write-Host "Successful saved XML:`n $((Get-Content -Path $destination -Encoding UTF8) -join "`n")"
}

<#function New-ProfileXml($Directory, $File) {
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
	
	$Properties.Add("pdf_file_name", @{"Position" = $counter; "Property_Value" = "$($uniqueNameScheme).pdf"})
    $counter += 1
	$Properties.Add("part_number_revision", @{"Position" = $counter; "Property_Value" = "$($File.'N° de pièce')$($File._Revision)"})
    $counter += 1
	if($File._Extension -eq "iam") {
		Write-Host "Assembly gets dependencies via file associations"
		(Get-VaultFileAssociations -File $file._FullPath -Dependencies) | foreach {
			$uptoDateDependency =  Get-VaultFile -File $_._FullPath
			if(Test-ValidProfileCategory -File $uptoDateDependency) {
				Write-Host "Adds '$($uptoDateDependency._PartNumber)' with category '$($uptoDateDependency._CategoryName)' to its XML."
				$Properties[$uptoDateDependency._CategoryName.Replace(" ", "_")] += @(@{"Position" = $counter; "Property_Value" = "$($uptoDateDependency._PartNumber)$($uptoDateDependency._Revision)"})
                $counter += 1
			}
		}
	}
    $Properties
	$xml = New-BoegliXml -Destination "$($Directory)\$($uniqueNameScheme).xml" -Properties $Properties -Counter $Counter
    $xml
    #$testProp = $Properties["Profils_Standards"][0]
    Show-Inspector
    return $xml
#}

function New-BoegliXml($Destination, [hashtable]$Properties, $Counter) {	
	[xml]$xml = "<Data/>"
    $range = 0..$counter
    foreach ($position in $range){
	    $Properties.GetEnumerator() | foreach {
		    if($_.Value -and $_.Value.GetType().IsArray) {
			    foreach($nestedPropertyNumber in $_.Value){
                    if ($Position -eq $nestedPropertyNumber["Position"]){
				        Write-Host "Create category XML tag $($_.Key)"
				        $xmlNode = AddXmlElement -xml $xml -name $_.Key -value $null
				        $elem = $xml.CreateElement("part_number_revision")
				        Write-Host "Create nested XML innertext $nestedPropertyNumber"
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
	Write-Host "Trying to save XML to $($destination): $($xml.OuterXml)"
	$xml.Save($destination)	
	Write-Host "Successful saved XML:`n $((Get-Content -Path $destination -Encoding UTF8) -join "`n")"
}#>