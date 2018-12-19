<<<<<<< Issue-#43
    $linkNotExists = $true
    foreach ($Id in $ItemIdsWithLinks){
        if ($pvItem.Id -eq $Id){
            $linkNotExists = $false
        }
    }
    if($linkNotExists){
        $addedLink = $vault.DocumentService.AddLink($Folder.Id,"ITEM",$pvItem.Id,"")
=======
    if (($vaultFilesIdsWithLinks | where { $pvItem.Id -eq $_ }) ){
        $link = $vault.DocumentService.AddLink($Folder.Id,"ITEM",$pvItem.Id,"")
>>>>>>> master


function Add-Link($Number, $Folder){
    $pvItem = Get-VaultItem -Number $Number
    $linksOnFolder = $vault.DocumentService.GetLinksByParentIds($Folder.Id, "ITEM")
    [array]$ItemIdsWithLinks= @()
    foreach ($link in $linksOnFolder){
	    $ItemIdsWithLinks += $link.ToEntId
    }
    $linkNotExists = $true
    foreach ($Id in $ItemIdsWithLinks){
        if ($pvItem.Id -eq $Id){
            $linkNotExists = $false
        }
    }
    if($linkNotExists){
        $addedLink = $vault.DocumentService.AddLink($Folder.Id,"ITEM",$pvItem.Id,"")
    }
}