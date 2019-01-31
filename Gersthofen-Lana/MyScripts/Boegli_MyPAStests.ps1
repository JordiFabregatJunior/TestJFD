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
		"Engineering" = @(
            "Test"
			"Material"
            "Designer"
            "Part Number"
            "Manager"
            "Test"
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
	Write-Host "Found following vault property mapping for category '$($File._CategoryName)': $([string]::Join(", ", $vaultProperietesForXML))"
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
		"Engineering" = @{
			"CAT" = "ENG"
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
        "Designer" = "Designer"
        "Material" = "Material"
        "Part Number" = "Part_Number"
        "Manager" = "Manager"
        "Test" = "Test_Property"
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
		Write-Host "Found no special XML mapping for the vault property '$($VaultProperty)' to create a XML Tag, therefore automatically generated: $convertXmlTagName"
		return $convertXmlTagName
	}
	$xmlTagName = $mapping[$VaultProperty]
	Write-Host "Found following special XML Tag for the vault property '$($VaultProperty)': $($xmlTagName)"
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
<#
function New-ProfileXml($Directory, $File) {
	$Properties = @{ }
	(Get-ProfilesVaultMapping -Category $File._CategoryName) | foreach {
		$xmlTagName = Get-ProfilesXmlMapping -VaultProperty $_
		if(-not [string]::IsNullOrEmpty($File."$_")) {
			$Properties.Add($xmlTagName, $File."$_")
		}
	}
	$categoryShortcut = (Get-ProfilesStaticMapping -Category $file._CategoryName)["CAT"]
	$uniqueNameScheme = "$($categoryShortcut)_$($File._Name)$($File._Revision)"
	
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
	New-BoegliXml -Destination "$($Directory)\$($uniqueNameScheme).xml" -Properties $Properties
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
			}
		} else {
			(AddXmlElement -xml $xml -name $_.Key -value $_.Value) | Out-Null
		}
	}
	Write-Host "Trying to save XML to $($destination): $($xml.OuterXml)"
	$xml.Save($destination)	
	Write-Host "Successful saved XML:`n $((Get-Content -Path $destination -Encoding UTF8) -join "`n")"
}#>


function AddXmlElement($xml, $name, $value)
{
    $elem = $xml.CreateElement($name)
    $elem.InnerText = $value
    $xml.DocumentElement.AppendChild($elem)
}

function GetReplaceItemNumber($file)
{
    $replaceItemNumber = ""
    try {
        $currentRev = $file.Revision
        $currentVersionNumber = $file._VersionNumber

        # iterate thru previous file versions until we find another a file with previous revision
        $versionNumber = $file._VersionNumber
        do {
            --$versionNumber
            $vaultFile = $vault.DocumentService.GetFileByVersion($file.MasterId, $versionNumber)
        } while ($versionNumber -gt 1 -and $vaultFile.FileRev.Label -eq $currentRev)

        if ($vaultFile) {
            $previousFile = Get-VaultFile -FileId $vaultFile.Id
            $replaceItemNumber = $previousFile.'Num ERP'
        }
    }
    Catch {
        Write-Host "Error in GetReplaceItemNumber()"
    }
    return $replaceItemNumber
}

function ExportToXml($file,$pdfFileName,$destination)
{
    [xml]$xml = "<Data/>"

    (AddXmlElement -xml $xml -name "destination" -value "Nav_Item") | Out-Null
    (AddXmlElement -xml $xml -name "pdf_file_name" -value $pdfFileName) | Out-Null
    (AddXmlElement -xml $xml -name "item_number" -value $file.'Num ERP') | Out-Null
    $replaceItemNumber = GetReplaceItemNumber -file $file
    (AddXmlElement -xml $xml -name "replace_item_number" -value $replaceItemNumber) | Out-Null

    $xml.Save($destination)
}
function Join-VaultPath {
param($Path0, $Path1)
	if(-not $Path1) { return $Path0 }
	if(-not $Path0) { return $Path1 }
	
	$is0Slash = $Path0.EndsWith("/")
	$is1Slash = $Path1.StartsWith("/")
	if($is0Slash -and $is1Slash) {
		$Path1 = $Path1.Substring(1)
	}
	if(-not ($is0Slash -or $is1Slash)) {
		$Path0 += "/"
	}
	return ($Path0 + $Path1)
}
function Copy-ExportedFile {
param(
[string]$SourceFullPath,
[System.IO.DirectoryInfo]$CopyDirectory
)
	if( (Test-Path $CopyDirectory) -eq $false ) {
		$null = New-Item -ItemType Directory -Path ($CopyDirectory)
		if( (Test-Path $CopyDirectory) -eq $false ) {
			throw "Could not create directory $($TargetDirectory.FullName)"
		}
	}
	
	$CopyFullPath = Join-Path $CopyDirectory ( [System.IO.Path]::GetFileName($SourceFullPath) )
	$null = Copy-Item $SourceFullPath $CopyFullPath -Force
	if( (Test-Path $CopyFullPath) -eq $false ) {
		throw "Could not copy $($SourceFullPath.FullName) to $($TargetFullPath)"
	}
}
function GetApplication($File) {
	if($File._Provider -eq "AutoCAD") {
		return $powerJobs.Applications.'DWG TrueView'
	}
	if($File._Provider -eq "Inventor" -or $File._Provider -eq "Inventor DWG") {
		return $powerJobs.Applications.Inventor
	}
}

function Get-PdfFileName($File, [switch]$Profile = $false) {	
	if($Profile) {
		$categoryShortcut = (Get-ProfilesStaticMapping -Category $file._CategoryName)["CAT"]
		return "$($categoryShortcut)_$($File.'N° de pièce')$($File._Revision).pdf"
	}
	$fileName = [system.io.path]::GetFileNameWithoutExtension($file.Name) 
	return $fileName + $file._Revision + ".pdf"
}

function Export-AdobePdf($OpenResult, [switch]$Profile = $false) {
    
    Write-Host "Starting export"
	$AdobePdfPrintDirectory = "C:\TEMP\AdobePdfPrints"
	$pdfFilename = Get-PdfFileName -File $file -Profile:$profile
	$localPdfFullPath = Join-Path $AdobePdfPrintDirectory $pdfFilename

	if(Test-Path $AdobePdfPrintDirectory) {
		Remove-Item -Path $AdobePdfPrintDirectory -Force -Recurse
    }
	$null = New-Item -Path $AdobePdfPrintDirectory -ItemType directory
	$Application = $openResult.Application.Instance
	$Document = $openResult.Document.Instance
	
	$printManager = $Document.PrintManager
    $printManager.Printer = "Adobe PDF"
    Write-Host "Using printer '$($printManager.Printer)' for export"
	$printManager.ScaleMode = [Inventor.PrintScaleModeEnum]::kPrintBestFitScale
	$printManager.PrintRange = [Inventor.PrintRangeEnum]::kPrintAllSheets
	$printManager.AllColorsAsBlack = $false
	$printManager.Orientation = [Inventor.PrintOrientationEnum]::kDefaultOrientation
	$printManager.SubmitPrint()
    
    Write-Host "Print submitted waiting for result.."
	Start-Sleep -Seconds 10
	$localPdf = Get-ChildItem -Path $AdobePdfPrintDirectory
	Rename-Item $localPdf.FullName $localPdfFullPath
	Get-Item $localPdfFullPath
}

function Get-VaultWhereUsedFiles($File) {
    $rootFile = Get-VaultFile -File $File
    $assocs = $vault.DocumentService.GetLatestFileAssociationsByMasterIds(@($rootFile.MasterId), "All", $false, "None", $false, $false, $false, $false)
    $assocs | select -First 1 -ExpandProperty "FileAssocs" | foreach {
        Get-VaultFile -FileId $_.ParFile.Id
    }
}
