Import-Module PowerJobs
$hideSTEP = $false
$workingDirectory = 'C:\Users\JordiFabregatJunior\AppData\Local\Temp\LOGSTRUP\ROC30009.ipt'
#$iLogicScriptName = "1_InvTestExternalRule_SAVE_XMLFile"
#$iLogicAddInGuid = "{3BDD8D79-2179-4B11-8A5A-257B1C0263AC}"

$openResult = Open-Document -LocalFile $workingDirectory
$invApp = $openResult.Application.Instance
$oDoc = $invApp.ActiveDocument
$oDataIO = $oDoc.ComponentDefinition.DataIO
$sOut = "FLAT PATTERN DXF?AcadVersion=2018&OuterProfileLayer=0&TangentLayer=FlatPattern_TangentLines&BendUpLayer=FlatPattern_BendLines&ToolCenterLayer=FlatPattern_ToolCenters&ArcCentersLayer=FlatPattern_ArcCenters&FeatureProfilesLayer=0&InteriorProfilesLayer=0&FeatureProfilesDownLayer=0"
$sOut = "FLAT PATTERN DXF?AcadVersion=R12&OuterProfileLayer=Outer"
$exportedDXFPath = "C:\Users\JordiFabregatJunior\AppData\Local\Temp\LOGSTRUP\flatROC30009_mine.dxf"
$oDataIO.WriteDataToFile($sOut, $exportedDXFPath)
#DXF from inventor API


    ' Build the string that defines the format of the DXF file.
    Dim sOut As String
    sOut = "FLAT PATTERN DXF?AcadVersion=R12&OuterProfileLayer=Outer"

    ' Create the DXF file.
    oDataIO.WriteDataToFile sOut, "C:\temp\flat2.dxf"
End Sub


 
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