function Get-ProfilesVaultMapping($Category) {
	$mapping = @{
		"Profils Mont�s sur rouleaux" = @(
			"N� de pi�ce"
			"Revision"
			"Cat�gorie"
			"Description"
			"Logo"
			"Client"
			"Application"
			"Cage"
			"Rouleau haut"
			"Rouleau bas"
			"Ancien n�IL"
			"Type de papier"
			"Epaisseur du papier A"
			"Diam�tre appui rouleau haut"
			"Diam�tre appui rouleau bas"
			"Diam�tre ext. rouleau haut"
			"Diam�tre ext. rouleau bas"
			"D�veloppement"
		)
		"Profils Standards" = @(
			"N� de pi�ce"
			"Revision"
			"Cat�gorie"
			"Description"
			"Sens"
			"Pas"
			"Espace papier"
			"Angle"
			"Compression"
			"Compression lat�rale"
			"P�n�tration"
			"Hauteur Patrix"
			"Profondeur Matrix"
			"Cote M"
			"Cote P"
			"Cote client minimale"
			"Cong�"
		)
		"Profils Standards Plus" = @(
			"N� de pi�ce"
			"Revision"
			"Cat�gorie"
			"Description"
			"Sens"
			"Pas"
			"Espace papier"
			"Angle"
			"Compression"
			"Compression lat�rale"
			"P�n�tration"
			"Hauteur Patrix"
			"Profondeur Matrix"
			"Cote M"
			"Cote P"
			"Cote client minimale"
			"Cong�"
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
			"Compression lat�rale structure"
			"P�n�tration structure"
			"Hauteur Patrix structure"
			"Profondeur Matrix structure"
			"Cote client minimale structure"
		)
		"Profils Modelages 3D" = @(
			"N� de pi�ce"
			"Revision"
			"Cat�gorie"
			"Description"
			"Sens"
			"Pas"
			"Espace papier"
			"Angle"
			"Compression"
			"Compression lat�rale"
			"P�n�tration"
			"Hauteur Patrix"
			"Profondeur Matrix"
			"Cote client minimale"
			"Cong�"
			"Rayon Patrix structure"
			"Rayon Matrix structure"
		)
		"Profils Intaglio" = @(
			"N� de pi�ce"
			"Revision"
			"Cat�gorie"
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
			"Compression lat�rale structure"
			"P�n�tration structure"
			"Hauteur Patrix structure"
			"Profondeur Matrix structure"
			"Cote client minimale structure"
		)
		"Profils Kinesis" = @(
			"N� de pi�ce"
			"Revision"
			"Cat�gorie"
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
			"Compression lat�rale structure"
			"P�n�tration structure"
			"Hauteur Patrix structure"
			"Profondeur Matrix structure"
			"Cote client minimale structure"
		)
		"Profils Polyhedron" = @(
			"N� de pi�ce"
			"Revision"
			"Cat�gorie"
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
			"Compression lat�rale structure"
			"P�n�tration structure"
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
		"Profils Mont�s sur rouleaux" = @{
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
		"N� de pi�ce" = "numero_de_piece"
		"Cat�gorie" = "categorie"
		"Ancien n�IL" = "ancien_no_IL"
		"Epaisseur du papier A" = "epaisseur_papier_A"
		"Diam�tre appui rouleau haut" = "diam_appui_rouleau_haut"
		"Diam�tre appui rouleau bas" = "diam_appui_rouleau_bas"
		"Diam�tre ext. rouleau haut" = "diam_ext_rouleau_haut"
		"Diam�tre ext. rouleau bas" = "diam_ext_rouleau_bas"
		"D�veloppement" = "developpement"
		"Compression lat�rale" = "compression_lat"
		"P�n�tration" = "penetration"
		"Cote M" = "cote_M"
		"Cote P" = "cote_P"
		"Cote client minimale" = "cote_client_min"
		"Cong�" = "conge"
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
		"Compression lat�rale structure" = "compression_lat_struc"
		"P�n�tration structure" = "penetration_struc"
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
	$uniqueNameScheme = "$($categoryShortcut)_$($File.'N� de pi�ce')$($File._Revision)"
	
	$Properties.Add("pdf_file_name", "$($uniqueNameScheme).pdf")
	$Properties.Add("part_number_revision", "$($File.'N� de pi�ce')$($File._Revision)")
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
