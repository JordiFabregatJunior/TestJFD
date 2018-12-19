#=============================================================================#
# PowerShell script sample for coolOrange powerEvents                         #
# Restricts the state to release, if the validation for some properties fails.#
#                                                                             #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#


$validateProperties = {
    param(
		$files = @(),
		$items = @(),
		$customObjects = @()
	)	
    $releasedEntities = @( ($files + $items + $customObjects) | where {
        $newLifecycleState = Get-VaultLifecycleState -LifecycleDefinition $_._NewLifeCycleDefinition -State $_._NewState
        $newLifecycleState.ReleasedState -eq $true
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