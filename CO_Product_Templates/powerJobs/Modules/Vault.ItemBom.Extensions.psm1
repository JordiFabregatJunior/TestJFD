
function Edit-VaultItem {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Number,
        [scriptblock]$EditOperation,
        [Switch]$UseCurrentRev
    )
    if($UseCurrentRev) { }
    $vaultItem = Get-VaultItem -Number $Number
    $vaultItem = $vault.ItemService.GetItemsByIds(@($vaultItem.Id)) | select -First 1
    try {
        $editedItem = $vault.ItemService.EditItems(@($vaultItem.RevId)) | select -First 1
        $result = Invoke-Command -Command $EditOperation -ArgumentList @($editedItem)
        $vault.ItemService.UpdateAndCommitItems(@($editedItem))
    } catch {
        if($editedItem) {
            $vault.ItemService.UndoEditItems(@($vaultItem.id))
        }
        throw $_
    } 
    finally {
        $vault.ItemService.DeleteUncommittedItems($true)
    }
    return $result
}

function New-VaulItemBomRow {
        param(
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][int]$BomRowId,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][int]$BOMOrder,
            [string]$Position,
            [double]$Quantity = 0,
            [AllowNull()][System.Nullable[int]]$InstanceCount,
            [long]$UnitID = 1,
            [AllowNull()][System.Nullable[double]]$UnitSize,
            [Autodesk.Connectivity.WebServices.BOMEditAction]$BOMEditAction = "Add",
            [switch]$IncludeChildren = $true,
            [switch]$Static = $true
        )
    $newBomRow = New-Object Autodesk.Connectivity.WebServices.ItemAssocParam
    $newBomRow.BOMOrder = $BOMOrder
    $newBomRow.PositionNum = $Position
    $newBomRow.CldItemID = $BomRowId
    $newBomRow.EditAct = $BOMEditAction
    $newBomRow.InstCount = $InstanceCount
    $newBomRow.IsIncluded = $IncludeChildren
    $newBomRow.IsStatic = $Static
    $newBomRow.Quant = $Quantity
    $newBomRow.UnitID = $UnitID
    $newBomRow.UnitSize = $UnitSize
    return $newBomRow
}

function Get-PropertyDefinitionByName {
    param(
        $PropertyName,
        [Parameter(Mandatory=$true)] [ValidateSet('CO', 'CUSTENT', 'FILE', 'FLDR', 'FRMMSG', 'ITEMRDES', 'LINK', 'ROOT', 'ItemBOMAssoc','ChangeOrderItem')]
        [string]$EntityClassId
    )
    if($EntityClassId -eq "ChangeOrderItem" -or $EntityClassId -eq  "ItemBOMAssoc") {
        $allPropDefs = $vault.PropertyService.GetAssociationPropertyDefinitionsByType($EntityClassId)    
    } else {
        $allPropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId($EntityClassId)
    }
	$propDef = $allPropDefs | ? { $_.SysName -eq $PropertyName }
	if(-not $propDef) {
		$propDef = $allPropDefs | ? { $_.DispName -eq $PropertyName }
	}
	return $propDef
}

function Update-VaultItemBomRow {
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$ParentNumber,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$BomRowNumber,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][hashtable]$Properties
    )
    try {
        $itemBom = Edit-VaultItem -Number $ParentNumber -EditOperation {
            param($EditedItem)
            $childItem = Get-VaultItem -Number $BomRowNumber

            $itemBom = $vault.ItemService.GetItemBOMByItemIdAndDate($EditedItem.Id, [DateTime]::MinValue, "Latest", [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::Defaults -bor [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::ReturnOccurrences -bor [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::OmitParents -bor [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::ReturnExcluded -bor [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::ReturnUnassignedComponents)
            if(-not $itemBom ){
                throw "No BOM for item number $ParentNumber"
            }
            $childItemBomAssociations = $itemBom.ItemAssocArray | where { $_.CldItemMasterID -eq $childItem.MasterId }
            foreach($childItemBomAssociation in $childItemBomAssociations) {
                $updatedProperties = New-Object -Type Autodesk.Connectivity.WebServices.ItemAssocPropArray
                $updatedProperties.Items = $Properties.GetEnumerator() | foreach {
                    $propertyDefinition = Get-PropertyDefinitionByName -PropertyName $_.Key -EntityClassId "ItemBOMAssoc"
                    if(-not $propertyDefinition) {
                        Add-Log "Update BOM Properties: Did not find BOM Property '$($_.Key)'"
                    } else {
                        $bomProperty = New-Object -Type Autodesk.Connectivity.WebServices.ItemAssocProp
                        $bomProperty.AssocId = $childItemBomAssociation.Id
                        $bomProperty.PropDefId = $propertyDefinition.Id
                        $bomProperty.Val = $_.Value
                        $bomProperty.ValTyp = $propertyDefinition.Typ.ToString()
                        $bomProperty
                    }
                }
                $vault.ItemService.UpdateItemBOMAssociationProperties($EditedItem.Id, @($childItemBomAssociation.Id), $updatedProperties)
            }
        }
    } catch {
        throw "Failed to update BOM of item $($ParentItem._Number): $($_.Exception.Message)"
    }
}

function Update-VaultItemBom {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ParentNumber,
        [Autodesk.Connectivity.WebServices.ItemAssocParam[]]$BomRows,
        [Autodesk.Connectivity.WebServices.BOMViewEditOptions]$BOMViewEditOptions = "Defaults"
    )
    try {
        $itemBom = Edit-VaultItem -Number $ParentNumber -EditOperation {
            param($EditedItem)
            return $vault.ItemService.UpdateItemBOMAssociations($editedItem.Id, $BomRows, $BOMViewEditOptions)
        }
    } catch {
        throw "Failed to update BOM of item $ParentNumber : $($_.Exception.Message)"
    }
    return $itemBom
}

function Add-VaultItemBomRow {
    param(
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$ParentNumber,
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]$BomRowNumber,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][int]$BOMOrder,
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [double]$Quantity,
        [string]$Position,
        [Autodesk.Connectivity.WebServices.BOMViewEditOptions]$BOMViewEditOptions = "Defaults"
    )
    $childItem = Get-VaultItem -Number $BomRowNumber
    $newBomRow = New-VaulItemBomRow -BomRowId $childItem.Id -Quantity $Quantity -UnitID 1 -BOMOrder $BOMOrder -Position $Position -IncludeChildren -Static
    try {
        return (Update-VaultItemBom -ParentNumber $ParentNumber -BomRows @($newBomRow) -BOMViewEditOptions $BOMViewEditOptions)
    } catch {
        throw "Failed to Add item with number '$BomRowNumber' to BOM of Item '$ParentNumber'"
    }
}

function Get-VaultItemBomProperties {
    param(
        $ParentNumber,
        $BomRowNumber
    )
    $bomRootItem = Get-VaultItem -Number $ParentNumber
    $bomRowItem = Get-VaultItem -Number $BomRowNumber
    $itemBom = $vault.ItemService.GetItemBOMByItemIdAndDate($bomRootItem.Id, [DateTime]::MinValue, "Latest", [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::Defaults -bor [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::ReturnOccurrences -bor [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::OmitParents -bor [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::ReturnExcluded -bor [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::ReturnUnassignedComponents)
    if(-not $itemBom ){
        throw "No BOM for item number $ParentNumber"
    }
    $childItemBomAssociation = $itemBom.ItemAssocArray | where { $_.CldItemMasterID -eq $bomRowItem.MasterId -and $_.ParItemMasterID -eq $bomRootItem.MasterId } | select -First 1
    $itemAssocProperties = $vault.ItemService.GetItemBOMAssociationProperties( @($childItemBomAssociation.Id), $null)
    $allBomPropertyDefinitions = $vault.PropertyService.GetAssociationPropertyDefinitionsByType("ItemBOMAssoc")
    $itemBomUdpProperties = @{}
    foreach($itemAssocProp in $itemAssocProperties) { 
        $propertyDefinition = $allBomPropertyDefinitions | where { $_.Id -eq $itemAssocProp.PropDefId }
        if(-not $propertyDefinition) { continue }
        $itemBomUdpProperties.Add("Bom_$($propertyDefinition.DispName)", $itemAssocProp.Val) 
    }
    return $itemBomUdpProperties
}