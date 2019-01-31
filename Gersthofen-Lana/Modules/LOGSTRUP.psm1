$NetworkPath = "C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU\Documents\PROJECTS\Logstrup\MockedNetwork\"


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
    [Parameter(Mandatory = $true)]$scriptName,
    [Parameter(Mandatory = $true)]$RuleScope
    )

    Add-Log "Executing iLogic rule '$scriptName'"
    $iLogicAutomation = $iLogicAddIn.Automation
    if($RuleScope -eq 'internal'){
        $iLogicAutomation.RunRule($invDoc, $scriptName)
    } elseif ($ruleScope -eq 'external') {
        $iLogicAutomation.RunExternalRule($invDoc, $scriptName)
    }
    Add-Log "Successfully executed iLogic rule!"
}

Function AddUpdate-VaultFiles {
    param(
    [Parameter(Mandatory = $true)]$vaultFileName,
    [Parameter(Mandatory = $true)]$localFileName
    )
    $vaultFile = Get-VaultFile -File $vaultFileName
    if ($vaultFile) {
        Add-Log "Adding new version of Vault file '$vaultFileName' ..."
        $vaultedFile = Add-VaultFile -From $localFileName -To $vaultFileName -FileClassification "None" -Comment "Updated by powerJobs custom job"
        $updated = Update-VaultFile -File $vaultFileName -Properties @{Description = 'Updated during job'} 
        Add-Log "Successfully added new version of Vault file!"
    } else {
        Add-Log "NOT ADDED new version!"
    }
}


<#Function AddUpdate-VaultFiles {
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
}#>



function New-LocalFile {
    param (
        $FromPath,
        $FilePath 
    )
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($FromPath)
    $fileExtension = [System.IO.Path]::GetExtension($FromPath)
    $filename = $filename + $fileExtension
    $NetPathSctructure = Join-Path $NetworkPath $FilePath.Substring(2)
    $destinationFile = Join-Path $NetPathSctructure $filename
    if(-not (Test-Path $NetPathSctructure))
    {
        New-Item -Path $NetPathSctructure -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $FromPath -Destination $destinationFile
}

function Convert-NetworkPathFromFolder {
    param (
        $folder
    )
    Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
    $customerName = Get-CustomerName $folder
    $series = Get-Series $folder
    $partnumber = Get-PartNr $folder
    return $Global:NetworkPath -replace "<customer>", $customerName -replace "<series>",$series -replace "<partnumber>",$partnumber
}

function Export-DocumentToSAT {
    param (
        [Parameter(Mandatory=$true)]$To,
        [Parameter(Mandatory=$true)]$Application
    )
    try{
        Write-Host ">> $($MyInvocation.MyCommand.Name) >>"
        $InvApp = $Application.Instance
        if($InvApp.Caption -like "*Inventor*"){
            $SATAddin = $InvApp.ApplicationAddIns | Where-Object { $_.ClassIdString -eq "{89162634-02B6-11D5-8E80-0010B541CD80}"}
            $SourceObject = $InvApp.ActiveDocument
            $Context = $InvApp.TransientObjects.CreateTranslationContext()
            $Options = $InvApp.TransientObjects.CreateNameValueMap()
            $oData = $InvApp.TransientObjects.CreateDataMedium()
            $Context.Type = 13059       #kFileBrowseIOMechanism
            $oData.MediumType = 56577   #kFileNameMedium
            $oData.FileName = $To
            $SATAddin.SaveCopyAs($SourceObject, $Context, $Options, $oData)
            return $true
        }
    } catch {
        throw("Export error. Inventor failed to export SAT document to $($To)")
    }
}