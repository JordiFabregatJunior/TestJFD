function Get-ProfilesVaultMapping($Category) {
	$mapping = @{
		"Profils Montés sur rouleaux" = @(
			"N° de pièce"
			"Revision"
			"Catégorie"
			"Description"
			"Logo"
			"Client"
			"Application"
			"Cage"
			"Rouleau haut"
			"Rouleau bas"
			"Ancien n°IL"
			"Type de papier"
			"Epaisseur du papier A"
			"Diamètre appui rouleau haut"
			"Diamètre appui rouleau bas"
			"Diamètre ext. rouleau haut"
			"Diamètre ext. rouleau bas"
			"Développement"
		)
		"Profils Standards" = @(
			"N° de pièce"
			"Revision"
			"Catégorie"
			"Description"
			"Sens"
			"Pas"
			"Espace papier"
			"Angle"
			"Compression"
			"Compression latérale"
			"Pénétration"
			"Hauteur Patrix"
			"Profondeur Matrix"
			"Cote M"
			"Cote P"
			"Cote client minimale"
			"Congé"
		)
		"Profils Standards Plus" = @(
			"N° de pièce"
			"Revision"
			"Catégorie"
			"Description"
			"Sens"
			"Pas"
			"Espace papier"
			"Angle"
			"Compression"
			"Compression latérale"
			"Pénétration"
			"Hauteur Patrix"
			"Profondeur Matrix"
			"Cote M"
			"Cote P"
			"Cote client minimale"
			"Congé"
			"Sens structure"
			"Orientation structure"
			"Forme structure"
			"Pourcentage structure min"
			"Pourcentage structure max"
			"Espace papier structure"
			"Pas structure"
			"Rayon Patrix structure"
			"Rayon Matrix structure"
			"Angle structure"
			"Compression structure"
			"Compression latérale structure"
			"Pénétration structure"
			"Hauteur Patrix structure"
			"Profondeur Matrix structure"
			"Cote client minimale structure"
		)
		"Profils Modelages 3D" = @(
			"N° de pièce"
			"Revision"
			"Catégorie"
			"Description"
			"Sens"
			"Pas"
			"Espace papier"
			"Angle"
			"Compression"
			"Compression latérale"
			"Pénétration"
			"Hauteur Patrix"
			"Profondeur Matrix"
			"Cote client minimale"
			"Congé"
			"Rayon Patrix structure"
			"Rayon Matrix structure"
		)
		"Profils Intaglio" = @(
			"N° de pièce"
			"Revision"
			"Catégorie"
			"Description"
			"Sens structure"
			"Orientation structure"
			"Forme structure"
			"Pourcentage structure min"
			"Pourcentage structure max"
			"Espace papier structure"
			"Pas structure"
			"Rayon Patrix structure"
			"Rayon Matrix structure"
			"Angle structure"
			"Compression structure"
			"Compression latérale structure"
			"Pénétration structure"
			"Hauteur Patrix structure"
			"Profondeur Matrix structure"
			"Cote client minimale structure"
		)
		"Profils Kinesis" = @(
			"N° de pièce"
			"Revision"
			"Catégorie"
			"Description"
			"Sens structure"
			"Orientation structure"
			"Forme structure"
			"Pourcentage structure min"
			"Pourcentage structure max"
			"Espace papier structure"
			"Pas structure"
			"Rayon Patrix structure"
			"Rayon Matrix structure"
			"Angle structure"
			"Compression structure"
			"Compression latérale structure"
			"Pénétration structure"
			"Hauteur Patrix structure"
			"Profondeur Matrix structure"
			"Cote client minimale structure"
		)
		"Profils Polyhedron" = @(
			"N° de pièce"
			"Revision"
			"Catégorie"
			"Description"
			"Sens structure"
			"Orientation structure"
			"Forme structure"
			"Pourcentage structure min"
			"Pourcentage structure max"
			"Espace papier structure"
			"Pas structure"
			"Rayon Patrix structure"
			"Rayon Matrix structure"
			"Angle structure"
			"Compression structure"
			"Compression latérale structure"
			"Pénétration structure"
			"Hauteur Patrix structure"
			"Profondeur Matrix structure"
			"Cote client minimale structure"
		)
	}
	if(-not $mapping.ContainsKey($Category)) {
		throw "Found no mapping for the category '$($Category)' to generate a XML file!"
	}
	$vaultProperietesForXML = $mapping[$Category]
	Add-Log "Found following vault property mapping for category '$($File._CategoryName)': $([string]::Join(", ", $vaultProperietesForXML))"
	return $vaultProperietesForXML
}

function Get-ProfilesStaticMapping($Category) {
	$mapping = @{
		"Profils Montés sur rouleaux" = @{
			"CAT" = "MSR"
		}
		"Profils Standards" = @{
			"CAT" = "STA"
		}
		"Profils Standards Plus" = @{
			"CAT" = "STP"
		}
		"Profils Modelages 3D" = @{
			"CAT" = "MOD"
		}
		"Profils Intaglio" = @{
			"CAT" = "INT"
		}
		"Profils Kinesis" = @{
			"CAT" = "KIN"
		}
		"Profils Polyhedron" = @{
			"CAT" = "POL"
		}
	}
	if(-not $mapping.ContainsKey($Category)) {
		throw "Found no mapping for the category '$($Category)' to generate a XML file!"
	}
	$mapping[$Category]
}

function Get-ProfilesXmlMapping($VaultProperty) {
	# Mapping is used for special properties where no pattern is implemented
	$mapping = @{
		# "Vault property name" = "XML Tag name"
		"N° de pièce" = "numero_de_piece"
		"Catégorie" = "categorie"
		"Ancien n°IL" = "ancien_no_IL"
		"Epaisseur du papier A" = "epaisseur_papier_A"
		"Diamètre appui rouleau haut" = "diam_appui_rouleau_haut"
		"Diamètre appui rouleau bas" = "diam_appui_rouleau_bas"
		"Diamètre ext. rouleau haut" = "diam_ext_rouleau_haut"
		"Diamètre ext. rouleau bas" = "diam_ext_rouleau_bas"
		"Développement" = "developpement"
		"Compression latérale" = "compression_lat"
		"Pénétration" = "penetration"
		"Cote M" = "cote_M"
		"Cote P" = "cote_P"
		"Cote client minimale" = "cote_client_min"
		"Congé" = "conge"
		"Sens structure" = "sens_struc"
		"Orientation structure" = "orientation_struc"
		"Forme structure" = "forme_struc"
		"Pourcentage structure min" = "pourcentage_min_struc"
		"Pourcentage structure max" = "pourcentage_max_struc"
		"Espace papier structure" = "espace_papier_struc"
		"Pas structure" = "pas_struc"
		"Rayon Patrix structure" = "rayon_patrix_struc"
		"Rayon Matrix structure" = "rayon_matrix_struc"
		"Angle structure" = "angle_struc"
		"Compression structure" = "compression_struc"
		"Compression latérale structure" = "compression_lat_struc"
		"Pénétration structure" = "penetration_struc"
		"Hauteur Patrix structure" = "hauteur_patrix_struc"
		"Profondeur Matrix structure" = "profondeur_matrix_struc"
		"Cote client minimale structure" = "cote_client_min_struc"
	}
	if(-not $mapping.ContainsKey($VaultProperty)) {
		$convertXmlTagName = $VaultProperty.Replace(" ", "_").ToLower() # Vault Property 'Hauteur Patrix' get converted to 'hauteur_patrix'
		Add-Log "Found no special XML mapping for the vault property '$($VaultProperty)' to create a XML Tag, therefore automatically generated: $convertXmlTagName"
		return $convertXmlTagName
	}
	$xmlTagName = $mapping[$VaultProperty]
	Add-Log "Found following special XML Tag for the vault property '$($VaultProperty)': $($xmlTagName)"
	return $xmlTagName
}

function Test-ValidProfileCategory($File) {
	try {
		return (Get-ProfilesVaultMapping -Category $File._CategoryName) -ne $null
	}
	catch {
		return $false
	}
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
		Add-Log "Assembly gets dependencies via file associations"
		(Get-VaultFileAssociations -File $file._FullPath -Dependencies) | foreach {
			$uptoDateDependency =  Get-VaultFile -File $_._FullPath
			if(Test-ValidProfileCategory -File $uptoDateDependency) {
				Add-Log "Adds '$($uptoDateDependency._PartNumber)' with category '$($uptoDateDependency._CategoryName)' to its XML."
				$Properties[$uptoDateDependency._CategoryName.Replace(" ", "_")] += @( "$($uptoDateDependency._PartNumber)$($uptoDateDependency._Revision)")
			}
		}
	}
	New-BoegliXml -Destination "$($Directory)\$($uniqueNameScheme).xml" -Properties $Properties
}

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
}
