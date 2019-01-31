Function Activate-AddIn {
    param(
    [Parameter(Mandatory = $true)]$invApp,
    [Parameter(Mandatory = $true)]$addinName,
    [Parameter(Mandatory = $true)]$addinGuid
    )

    Add-Log "Activating Inventor Add-In '$addinName'"
    $addIn = $invApp.ApplicationAddIns.ItemById($addinGuid)
    if(-not $addIn) { 
        Add-Log "Inventor Add-In '$addinName' not available";
        throw("Failed to activate Inventor Add-In '$addinName'")
    }

    if($addIn.Activated -ne $true){
        $addIn.Activate()
        Add-Log "Inventor Add-In '$addinName' activated"
    }else{
        Add-Log "Inventor Add-In '$addinName' was already activated"
    }

    return $addIn
}

Function Run-iLogicScript {
    param(
    [Parameter(Mandatory = $true)]$iLogicAddIn,
    [Parameter(Mandatory = $true)]$invDoc,
    [Parameter(Mandatory = $true)]$scriptName
    )

    Add-Log "Executing iLogic rule '$scriptName'"
    $iLogicAutomation = $iLogicAddIn.Automation
    $iLogicAutomation.RunRule($invDoc, $scriptName)
    Add-Log "Successfully executed iLogic rule!"
}

Function AddUpdate-VaultFiles {
    param(
    [Parameter(Mandatory = $true)]$localFolder,
    [Parameter(Mandatory = $true)]$dwgFile,
    [Parameter(Mandatory = $true)]$extension
    )

    $bimFiles = Get-ChildItem $localFolder | Where-Object { $_.Extension -eq $extension }

    foreach ($bimFile in $bimFiles) {
        $localFileName = $bimFile.FullName
        $vaultFileName = $dwgFile._EntityPath + "/" + $bimFile.Name

        $vaultFile = Get-VaultFile -File $vaultFileName
        if ($vaultFile) {
            Add-Log "Adding new version of Vault file '$vaultFileName' ..."
            $vaultedFile = Add-VaultFile -From $localFileName -To $vaultFileName -FileClassification "None" -Comment "Updated by powerJobs custom job SK.BIM"
            Add-Log "Successfully added new version of Vault file!"
        } else {
            Add-Log "Adding new Vault file '$vaultFileName' ..."
            $vaultedFile = Add-VaultFile -From $localFileName -To $vaultFileName -FileClassification "None" -Comment "Added by powerJobs custom job SK.BIM"
            if ($vaultedFile) {
                $vaultedFile = Update-VaultFile -File $vaultedFile.'Full Path' -Category $bimCategory
            }
            Add-Log "Successfully added new Vault file!"
        }
        if ($vaultedFile) {
            Add-Log "Updating status and revision of '$vaultFileName' ..."
            $vaultedFile = Update-VaultFile -File $vaultedFile.'Full Path' -LifecycleDefinition $bimLifecycleDefinition -Status $bimLockedState
            $vaultedFile = Update-VaultFile -File $vaultedFile.'Full Path' -Revision $dwgFile._Revision -RevisionDefinition $bimRevisionDefinition
            Add-Log "Successfully updated Vault file!"
        }    
    }
}