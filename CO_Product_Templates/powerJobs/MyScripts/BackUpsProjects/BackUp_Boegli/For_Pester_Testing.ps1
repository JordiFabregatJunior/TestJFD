<#
$vaultFile = New-PSVaultFile -Name "PRC-9009.iam"
$PropertiesAfterIAM = New-ProfileXml -Directory "C:\temp\export" -File $vaultFile
Compare-Object -ReferenceObject $PropertiesAfterIAM["Profils_Standards"] -DifferenceObject $expectedProperties -SyncWindow 0 -CaseSensitive)| Should -BeNullOrEmpty) -eq $null
$mapping["Profils Standards"]
Compare-Hashtable $expectedProperties $Properties
#((Compare-Hashtable $expectedProperties $Properties) | Should -BeNullOrEmpty) -eq $null
#>

$expectedProperties = @(
	"PRC-9009.idw 999"
	"PRC-1001.ipt 999"
	"Other Dependency.ipt 999"
	"Other Dependency2.png 999"
)

function New-BoegliXml{
    return "success"
}
#function New-ProfileXml($Directory, $File) {
    $Directory = "C:\temp\export"
    $File = $vaultFile
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
    $PropertiesBeforeIAM = $Properties
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
#    return @($Properties, $PropertiesBeforeIAM,)
#}

function Get-VaultFileAssociations($File, [switch]$Attachments, [switch]$Dependencies) { 

    $VaultDpendencies = @(
		(New-PSVaultFile -Name "PRC-9009.idw")
		(New-PSVaultFile -Name "PRC-1001.ipt")
		(New-PSVaultFile -Name "Other Dependency.ipt")
		(New-PSVaultFile -Name "Other Dependency2.png")
	)
    return $VaultDpendencies
}

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

function New-PSVaultFile($Name) {
    $vaultRootDirectory = "$/Designs"
    New-Object PSObject -Property @{
        "_Name" = $Name
        "_FullPath" = "$vaultRootDirectory/$Name"
        "_Extension" = [System.IO.Path]::GetExtension($Name).SubString(1)
        "_PartNumber" = "$Name 999"
        "_CategoryName" = "Profils Standards"
        "Description" = "Parlo"
        "Sens" = "Zenza"
        "Profondeur Matrix" = "matrix"
        "N° de pièce" = "6131"
        "_Revision" = "SX"
        "Revision" = "SX"
        "Compression latérale" = "Shortcut"
        "Pénétration" = "specialz"
        "Congé" = "jaw`´ol"
        "(Largeur de pointe minimale)" = "largeur_de_pointe_minimale"
        "Cote client minimale" = "cotepièce"
    }
}

# Source https://gist.github.com/dbroeglin/c6ce3e4639979fa250cf#file-compare-hashtable-ps1
function Compare-Hashtable {	
    [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [Hashtable]$Left,
    
            [Parameter(Mandatory = $true)]
            [Hashtable]$Right		
        )
        
        function New-Result($Key, $LValue, $Side, $RValue) {
            New-Object -Type PSObject -Property @{
                        key    = $Key
                        lvalue = $LValue
                        rvalue = $RValue
                        side   = $Side
                }
        }
        [Object[]]$Results = $Left.Keys | % {
            if ($Left.ContainsKey($_) -and !$Right.ContainsKey($_)) {
                New-Result $_ $Left[$_] "<=" $Null
            } else {
                $LValue, $RValue = $Left[$_], $Right[$_]
                if ($LValue -ne $RValue) {
                    New-Result $_ $LValue "!=" $RValue
                }
            }
        }
        $Results += $Right.Keys | % {
            if (!$Left.ContainsKey($_) -and $Right.ContainsKey($_)) {
                New-Result $_ $Null "=>" $Right[$_]
            } 
        }
        $Results 
    }