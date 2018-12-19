
$validateProperties = {
    param(
		$files = @(),
		$items = @(),
		$customObjects = @()
	)	
    $releasedEntities = @( ($files + $items + $customObjects) | where {
        $newLifecycleState = Get-VaultLifecycleState -LifecycleDefinition $_._NewLifeCycleDefinition -State $_._NewState
        $newLifecycleState.ReleasedState -eq $true
        Show-Inspector
    })

    foreach( $entity in $releasedEntities )  {
        $lastModifyUser = $null
        switch -regex ($entity._EntityType.ServerId) 
        { 
            "FILE|CUSTENT" { $lastModifyUser = $entity._CreateUserName } 
            "ITEM"      { $lastModifyUser = $entity._LastModifiedUserName } 
        }
		if($lastModifyUser -ne $vaultConnection.UserName){
            Add-VaultRestriction -EntityName ($entity._Name) -Message "The state can only be changed to '$($entity._NewState)' by the user who last modified the $($entity._EntityType) (User:  $lastModifyUser)."
        Show-inspector
        }
    }
}

$validatePropertiesForChangeOrder = {
    param(
		$changeOrder,
        $activity
	)
	$isChangeOrderClosing = (Get-VaultActivity $changeOrder $activity).Name -eq 'Set Effectivity'
	
	if($isChangeOrderClosing) {
		$lastModifyUser = $changeOrder._LastModifiedUserName
		if($lastModifyUser -ne $vaultConnection.UserName){
			Add-VaultRestriction -EntityName ($changeOrder._Name) -Message "The activity '$activity' can only be accomplished by the user who last modified the ChangeOrder (User:  $lastModifyUser)."
        }
	}
}

#Register-VaultEvent -EventName UpdateFileStates_Restrictions -Action $validateProperties
#Register-VaultEvent -EventName UpdateItemStates_Restrictions -Action $validateProperties
#Register-VaultEvent -EventName UpdateCustomEntityStates_Restrictions -Action $validateProperties
#Register-VaultEvent -EventName UpdateChangeOrderState_Restrictions -Action $validatePropertiesForChangeOrder