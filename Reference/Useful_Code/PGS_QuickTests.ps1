function Add-VaultItem {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ItemNumber,
        [string]$Category
    )
    if($Category){
        $categoryId = $vault.CategoryService.GetCategoriesByEntityClassId("ITEM", $false) | where { $_.Name -ieq $Category} | select -ExpandProperty Id
    } else {
        $categoryId = $vault.CategoryService.GetCategoriesByEntityClassId("ITEM", $true) |  select -First 1 -ExpandProperty Id
    }
    if(-not $categoryId) {
        throw "Error in $($MyInvocation.MyCommand.Name). Could not find an ITEM Category $Category"
    }
    $addedItem = $vault.ItemService.AddItemRevision($categoryId)
    $edited = Edit-VaultItem -Number $addedItem._Number -EditOperation {
        param($EditedItem)
        $numberingSchemeId = $vault.ItemService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated) | where { $_.SysName -eq "Mapped" } | Select -ExpandProperty SchmID
        $numberingSchemeArgs = New-Object Autodesk.Connectivity.WebServices.StringArray
        $numberingSchemeArgs.Items += $ItemNumber

        [Autodesk.Connectivity.WebServices.ProductRestric[]]$restrictions = @()
        $newNumber = $vault.ItemService.AddItemNumbers(@($EditedItem.MasterId), @($numberingSchemeId), $numberingSchemeArgs, [ref]$restrictions) | Select -First 1 | Select -ExpandProperty ItemNum1
        $EditedItem.NumSchmId = $numberingSchemeId
        $EditedItem.ItemNum = $newNumber
        $vault.ItemService.CommitItemNumbers(@($EditedItem.MasterId),@($newNumber))
    }
    return $vault.ItemService.GetLatestItemByItemMasterId($addedItem.MasterId)
}

function Search-EntitiesByPropertyValue {
    param(
        [string]$PropertyName,
        [string]$SearchValue,
        [ValidateSet('FLDR', 'FILE', 'CUSTENT', 'ITEM', 'ITEMRDES', 'CO', 'ROOT', 'LINK', 'FRMMSG')][string]$EntityClassId,
        [ValidateSet("Contains","IsExactly")]$SearchOperation
    )

    <#
        .SYNOPSIS
        Returns a array of objects matching search conditions
        .DESCRIPTION
        Returns a property definition based on its display name. If EntityClassId is passed in the commandlet retrieves a list of all available definitions by itself befor filtering.
        .PARAMETER PropertyName
        The name of the property definition that will be searched
        .PARAMETER EntityClassId
        The entity class the property definition belongs to
        .PARAMETER SearchValue
        Value the search where the search will be applied
        .PARAMETER SearchOperation
        Operations available: Contains, isExactly. If contains, '*' needs to be set.
        .EXAMPLE
        Search-EntitiesByPropertyValue -PropertyName 'Number' -SearchValue 'M-000000*' -EntityClassId 'ITEM' -SearchOperation 'Contains'
    #>
    
    switch($SearchOperation)
    {
        'Contains'
        {
            $searchOperCode = 1
        }
        'IsExactly'
        {
            $searchOperCode = 3
        }
    }

    $propDefs = Get-PropertyDefinitions -EntityClassId $EntityClassId
    $prop = Get-PropertyDefinitionByName -PropertyName $PropertyName -EntityClassId $EntityClassId -PropDefs $propDefs
    	
	$searchcond = New-Object Autodesk.Connectivity.WebServices.SrchCond
    $searchcond.PropDefId = $prop.Id
    $searchcond.SrchOper = $searchOperCode
	$searchcond.SrchTxt = $SearchValue
	$searchcond.SrchRule = "Must"
	$searchcond.PropTyp = "SingleProperty"
	$bookmark = ""
	$searchStatus = New-Object Autodesk.Connectivity.WebServices.SrchStatus
    $items = $vault.ItemService.FindItemRevisionsBySearchConditions(@($searchcond),$null,$true, [ref]$bookmark, [ref]$searchStatus)
    
	return $items
}


function Get-PropertyDefinitionByName {
    [CmdletBinding()]
	param (
        [Parameter(Position=0)]
        $PropertyName, 
        [Parameter(Position=1,ParameterSetName="EntityClassId")]
        $EntityClassId,
        [Parameter(Position=1,ParameterSetName="PropDefs")]
        $PropDefs
	)
    
	if(-not $PropDefs) { 
        $PropDefs = Get-PropertyDefinitions -EntityClassId $EntityClassId
    }

	foreach($propDef in $PropDefs) {
		if(($propDef.SysName -eq $PropertyName) -or ($propDef.DispName -eq $PropertyName)) {
			return $propDef
		}
	}
}


