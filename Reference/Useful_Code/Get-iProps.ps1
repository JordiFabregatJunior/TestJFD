$null = [System.Reflection.Assembly]::LoadWithPartialName("Autodesk.Inventor.Interop")
$invApp = New-Object Inventor.ApprenticeServerComponentClass
$localPath = 'C:\Vault_Arbeitsbereich\CAD\TEST\FMD-D028277.ipt'
$invDoc = $invApp.Open($localPath)
$allProps = @()
foreach($propSet in $invDoc.PropertySets){
    $allProps += $propSet
}
$allProps.count
#$UDPsInvProps = $invDoc.PropertySets.Item("Inventor User Defined Properties")
#$DesignInvProps = $invDoc.PropertySets.Item("Design Tracking Properties")