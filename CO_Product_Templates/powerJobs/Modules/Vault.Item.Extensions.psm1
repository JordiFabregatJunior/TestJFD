function Add-VaultItem {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ItemNumber,
        [string]$Category
    )
    if($Category){
        $categoryId = $vault.CategoryService.GetCategoriesByEntityClassId("ITEM", $false) | where { $_.Name -ieq $Category} | select -ExpandProperty Id
    } else {
        $categoryId = $vault.CategoryService.GetCategoriesByEntityClassId("ITEM", $true) |  select -First 1 -ExpandProperty Id
    }
    if(-not $categoryId) {
        throw "Error in $($MyInvocation.MyCommand.Name). Could not find an ITEM Category $Category"
    }
    $item = $vault.ItemService.AddItemRevision($categoryId)
    try {
        $numberingSchemeId = $vault.ItemService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated) | where { $_.SysName -eq "Mapped" } | Select -ExpandProperty SchmID

        $numberingSchemeArgs = New-Object Autodesk.Connectivity.WebServices.StringArray
        $numberingSchemeArgs.Items += $ItemNumber

        [Autodesk.Connectivity.WebServices.ProductRestric[]]$restrictions = @()
        $newNumber = $vault.ItemService.AddItemNumbers(@($item.MasterId), @($numberingSchemeId), $numberingSchemeArgs, [ref]$restrictions) | Select -First 1 | Select -ExpandProperty ItemNum1

        $item.NumSchmId = $numberingSchemeId
        $item.ItemNum = $newNumber

        $vault.ItemService.CommitItemNumbers(@($item.MasterId),@($newNumber))
        $vault.ItemService.UpdateAndCommitItems(@($item))
    }
    catch {
        if($item) {
            $vault.ItemService.UndoEditItems(@($item.id))
        }
    } 
    finally {
        $vault.ItemService.DeleteUncommittedItems($false)
    }
    return $vault.ItemService.GetLatestItemByItemMasterId($item.MasterId)
}

function Add-VaultItemIfNotExists {
    param(
        $ItemNumber
    )
    $existingItem = Get-VaultItem -Number $ItemNumber
    if(-not $existingItem) {
        Add-Log "Artikel '$ItemNumber' wurde in Vault nicht gefunden und wird jetzt erstellt."
        if(-not (Add-VaultItem -ItemNumber $ItemNumber -Category "AbasAuftragsPos")) { 
            throw "Erstellung des Artikels '$ItemNumber' ist fehlgeschlagen!"
        }
    }
}

function Copy-VaultItemProperties($SourceItemNumber, $DestinationItemNumber, [string[]]$Properties) {
    $sourceItem = Get-VaultItem -Number $SourceItemNumber
    if(-not $sourceItem) {
        Add-Log "Could not find Item with number $sourceItemNumber for copying Vault Properties"
        return
    }
    $copiedProperties = @{}
    $Properties | foreach {
        $newValue = $sourceItem."$_"
        if($null -eq $newValue) {
            $newValue = ""
        }
        $copiedProperties.Add($_, $newValue)
    }
    Add-Log "Startet kopieren der Properies von $SourceItemNumber zu $DestinationItemNumber für $([string]::Join(', ', $Properties))"
    $updatedDestinationItem = Update-VaultItem -Number $DestinationItemNumber -Properties $copiedProperties
}