###############  FILE APPROACH - PARTE 1
Import-Module 'C:\ProgramData\coolOrange\powerJobs\Modules\cO.Logging.psm1'

$vaultContext.ForceRefresh = $true
$fileIds= $vaultContext.CurrentSelectionSet.Id
#Log -Message "FileIds=$($fileIds)"
if($fileIds){
    foreach($fileId in $fileIds){
        #Log -Message "Within FileId = $fileId"
        $addedJob = Add-VaultJob -Name "Sample.CreateSTEP" -Parameters @{"EntityId"="$($fileId)";"EntityClassId"="FILE"} -Description "Creación manual STEP" 
    }
}


############### FOLDER APPROACH - PARTE 2
Import-Module 'C:\ProgramData\coolOrange\powerJobs\Modules\cO.Logging.psm1'
$dsDialog.Clear()
$dsDiag.Trace("Empezando ejecución del script ps1...")
$dsDiag.ShowLog()
$dsDiag.Inspect()
#Show-Inspector vaultContext

#ShowRunspaceID
$vaultContext.ForceRefresh = $true
$selectedEntities = $vaultContext.CurrentSelectionSet
#Log -Message "SelectedEntities: $($SelectedEntities)"
foreach($entity in $selectedEntities){
    #Log -Message "Within entity >>> EntityClassId: $($entity.EntityClassId) | Entity ID: $($entity.Id) "
    if ($entity.TypeId.EntityClassId -eq "FILE"){
        #Log -Message "Adding job for fileId = $($entity.Id)"
        $addedJob = Add-VaultJob -Name "Sample.CreateSTEP" -Parameters @{"EntityId"="$($entity.iD)";"EntityClassId"="FILE"} -Description "Creación manual STEP" 
    } 
    elseif ($entity.TypeId.EntityClassId -eq "FLDR") 
    {
        #Log -Message "Within FOlder scope. FolderId = $($entity.Id)"
        $folder = $vault.DocumentService.GetFolderById($entity.Id)
        $filesInFolder = Get-VaultFiles -Folder $folder.Fullname
        #Log -Message "Files in folder: '$($filesInFolder._Name)'"
        foreach($file in $filesInFolder){
            if($file._Extension -in @('ipt','iam')){
                $addedJob = Add-VaultJob -Name "Sample.CreateSTEP" -Parameters @{"EntityId"="$($file.iD)";"EntityClassId"="FILE"} -Description "Creación manual STEP" 
            }
        }
    }
} 