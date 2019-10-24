


#Import-Module PowerVault
#Open-VaultConnection -Server "localhost" -Vault "VaultJFD" -user "Administrator"
$item = Get-VaultItem -Number '2557'
#$updatedItem = Update-VaultItem -Number $item._Number -LifecycleDefinition "Item Release Process" -Status "Quick-Change"

$lfcDefs = $vault.LifeCycleService.GetAllLifeCycleDefinitions()

$lfc = $lfcDefs | Where { 
    $_.SysName -eq $item._LifeCycleDefinition
}

$stateName = 'Quick-Change'
$existsQuickChangeState = $lfc.StateArray.Name -contains $stateName
if(-not($lfc.StateArray.Name -contains 'Quick-Change')){
    "Item cannot be set to Quick-Change state since state does not exist in lifecycle '$($lfc.Name)' definition."
}

$qcStateDef = $lfc.StateArray | where {$_.Name -eq $stateName}
$comment = ""


$latestItem = $vault.ItemService.GetLatestItemByItemNumber($item._Number)
$itemEntityClassProps = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId('ITEM')
$itemProps = $vault.PropertyService.GetPropertiesByEntityIds('ITEM', @($latestItem.Id))
$filterPending = $false
$vault.PropertyService.GetPropertyComplianceFailuresByEntityIds('ITEM',@($latestItem.Id),$filterPending)

try{
    $updateItemState = $vault.ItemService.UpdateItemLifeCycleStates(@($item.MasterId), @($qcStateDef.Id), $comment)
} catch {
    $_.Exception.Message
}
