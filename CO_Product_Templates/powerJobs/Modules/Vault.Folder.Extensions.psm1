function ConvertTo-VaultPath([string[]]$Folders) {

	$vaultPath = ""
	foreach($folder in $Folders) {
		$vaultPath += "{0}/" -f $folder
	}
	return $vaultPath.TrimEnd('/')
}

function Get-VaultFolder {
	param(
        [Parameter(Mandatory=$true)]
        $Path
	)
    $vaultFolder = ($vault.DocumentService.FindFoldersByPaths( @($Path) )) | select -First 1
    if($vaultFolder.Id -ge 0) {
        return $vaultFolder
    }
}

function Add-VaultFolder {
	param(
        [Parameter(Mandatory=$true)]
        $Path,
        [switch]$IsLibrary = $false,
        [switch]$Force = $false
    )
	$folder = ($vault.DocumentService.FindFoldersByPaths( @($Path) )) | select -First 1
	if($folder.Id -ge 0) {
        if($Force) { 
            return $folder 
        }
        else {
            throw "Folder already exists: $($folder.FullName)"
        }
    }
	$folders = $Path -split '/' | Where-Object { -not [string]::IsNullOrEmpty($_) }
    
	$ParentFolder = Add-VaultFolder -Path (ConvertTo-VaultPath ($folders | Select-Object -First ($folders.Length - 1))) -IsLibrary:$isLibrary -Force:$Force
	$name = $Path | Split-Path -Leaf
    Add-Log "Adding Vault Folder $Path as Library $IsLibrary"
	return $vault.DocumentService.AddFolder($name, $ParentFolder.Id, $isLibrary)
}


function Add-VaultFolderWithCategory($Path, $Category) {
    $addedVaultFolder = Add-VaultFolder -Path $Path -Force
    if($addedVaultFolder) {            
        $updatedVaultFoldersCategory = Update-VaultFolder -Folder $addedVaultFolder -Properties @{ "Category" = $Category }
        if(-not $updatedVaultFoldersCategory) {
            Add-Log "Aktualiseren der Kategorie auf '$Category' ist fehlgeschlagen für folgenden Vault Ordner: $Path"    
        }
        return $updatedVaultFoldersCategory
    } else {
        Add-Log "Erstellen des Vault Ordner ist fehlgeschlagen: $Path"    
    }
}

function Get-PropertyDefinitions([string]$EntityClassId) {
	return $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($EntityClassId)
}

function Update-VaultFolder($Folder, [hashtable]$Properties) {
	$newProperties = New-Object Autodesk.Connectivity.WebServices.PropInstParamArray
	$newPropertiesItems = @()
	$folderPropertyDefintions = Get-PropertyDefinitions "FLDR"
	
	$categoryProperty = $null
	$udproperties = @{}
	$Properties.GetEnumerator() | foreach {
			if ($_.Key -eq "Category" -or $_.Key -eq "Kategorie") {
				$categoryProperty = $_.Value
			} else {
				$udproperties[$_.Key] = $_.Value
			}
		}
	foreach ($propertyDefinitionName in $udproperties.Keys) {
		$newProperty = New-Object Autodesk.Connectivity.WebServices.PropInstParam
		$folderPropertyDefinition = $folderPropertyDefintions | where { $_.DispName -eq $propertyDefinitionName -or $_.SysName -eq $propertyDefinitionName }
		if(-not $folderPropertyDefinition) {
			throw "Vault Property '$propertyDefinitionName' wurde als SystemName und DisplayName für Folders nicht gefunden!"
		}
		$newProperty.PropDefId = $folderPropertyDefinition.Id
		$newProperty.Val = $udproperties[$propertyDefinitionName]
		$newPropertiesItems += $newProperty
	}
    $newProperties.Items = $newPropertiesItems
	$vault.DocumentServiceExtensions.UpdateFolderProperties(@($Folder.Id), @($newProperties))	
	if($categoryProperty) {	
		$newFolderCategory = $vault.CategoryService.GetCategoriesByEntityClassId("FLDR", $true) | where { $_.Name -eq $categoryProperty -or $_.SysName -eq $categoryProperty }		
		if(-not $newFolderCategory) {
			throw "Vault Kategorie '$categoryProperty' wurde als SystemName und DisplayName für Folders nicht gefunden!"
        }
		($vault.DocumentServiceExtensions.UpdateFolderCategories(@($Folder.Id), @($newFolderCategory.Id))) | select -First 1
	}
}