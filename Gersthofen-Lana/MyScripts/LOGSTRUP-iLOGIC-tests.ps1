Import-Module PowerJobs
$hideSTEP = $false
$workingDirectory = 'C:\Temp\PART-iLogicTest-000.ipt\PART-iLogicTest-000.ipt'
$iLogicScriptName = "1_InvTestExternalRule_SAVE_XMLFile"
$iLogicAddInGuid = "{3BDD8D79-2179-4B11-8A5A-257B1C0263AC}"

$openResult = Open-Document -LocalFile $workingDirectory
 
$invApp = $openResult.Application.Instance
$invDoc = $openResult.Document.Instance
$iLogicAddIn = Activate-AddIn -invApp $invApp -addinName "iLogic" -addinGuid $iLogicAddInGuid
$iLogicAutomation = $iLogicAddIn.Automation
$iLogicAutomation.RunRule($invDoc, $scriptName)

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


Run-iLogicScript -iLogicAddIn $iLogicAddIn -invDoc $invDoc -scriptName $iLogicScriptName

$closeResult = Close-Document