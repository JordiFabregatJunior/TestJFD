Import-Module powerGate -Global
Import-Module powerVault -Global
Get-ChildItem -path ($env:ProgramData+'\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules') -Filter Vault.*.psm1 | foreach { 
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension('Vault.BOMMapping.Helpers.psm1')
    Remove-Module -Name $moduleName -Force
}
Remove-Module SAP.Release.Helpers	
Import-Module 'C:\ProgramData\coolOrange\powerEvents\Modules\SAP.Release.Helpers.psm1'
Get-ChildItem -path ($env:ProgramData+'\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules') -Filter Vault.*.psm1 | foreach { Import-Module -Name $_.FullName -Global -Force}	
Import-Module "$($env:ProgramFiles)\coolorange\Modules\powerGate\powerGate_Connections.psm1"
Connect-ToErpServer
Open-VaultConnection -Server "hscmas07" -Vault "CM-01" -user "coolOrangeAdmin " -Password "12345"

### DATA INITIALIZATION
$plant = "GEHM"
$EKGRP = "43Z"
$language = "E"
$languageISO = "EN"
$global:itemEntitySet = "Materials"
$global:itemEntityType = "MaterialEntity"
$global:itemErpKey = "Number"
$global:bomEntitySet = "Boms"
$global:bomEntityType = "BomEntity"
$global:bomRowEntityType = "BomRowEntity"
$global:bomErpKey = "ParentNumber"
$global:itemNumberPropName = "01 SAP-No."
$global:bomNumberPropName = "01 SAP-No."
$global:filePartNumberPropName = "01 SAP-No."
$global:pgStandardKeyProps = @{
	"ITEMNumber" = '01 SAP-No.'
	"ITEMDescription" = '02 Short Desc. German'
	"ITEMUnitOfMeasure" = '15 Order Unit'
}

function Reset-ItemsWithWorkingProperties ($Items){
    
    $resetProperties = @{
        '02 Short Desc. German' = "NewDescription"
        '15 Order Unit' = "PC"
    }

    $returnItems = @()

    foreach($item in $items){
        if($item._Number -eq 'M-000002'){
            $resetProperties.Add( "01 SAP-No.",'')
        }
        $resetItem = Update-VaultItem -Number $item._Number -Properties $resetProperties
        $returnItems += $resetItem
    }

    return $returnItems
}

Describe "Worklfow on item transition to Released " {

    $itemHeader = Get-VaultItem -Number 'M-000002'
    $itemRow = Get-VaultItem -Number 'M-000003'

    $resetItems = Reset-ItemsWithWorkingProperties -Items @($itemRow,$itemHeader)
    $resetItemRow = $resetItems | where { $_.Number -eq 'M-000003'}
    $resetItemHeader = $resetItems | where { $_.Number -eq 'M-000002'}

    Context "Checking test data is prepared for tests"{
        $resetItemRow._State | Should -Be "Released"
        $resetItemRow.'01 SAP-No.' | Should -BeTrue
        $resetItemRow.'15 Order Unit' | Shoulde -Be "PC"
        
        $resetItemHeader.'01 SAP-No.' | Should -BeFalse
        $resetItemHeader.'15 Order Unit' | Shoulde -Be "PC"
    }

    Context "Material and BOM creation (BomHeader)"{
        Add-Member -InputObject $resetItemHeader -Name _NewState -Value "Released" -MemberType NoteProperty -Force
        # NOTE: USER INTERACTION REQUIRED!!!
        Invoke-ReleaseProcess -Item $resetItemHeader

        $latestVersionItemHeader = Get-VaultItem -Number 'M-000002'
        $parentNumber = Get-SAPNumber -VaultEntity $latestVersionItemHeader
        $ChildNumber = Get-SAPNumber -VaultEntity $resetItemRow

        $sapHeader = Get-ERPObject -EntitySet $global:itemEntitySet -Keys @{ "Number" = $parentNumber }
        $bom = Get-ERPObject -EntitySet "BOMS" -Keys @{ "ParentNumber" = $ParentNumber } -Expand "Children"        

        $sapHeader | Should -BeTrue
        $parentNumber | Should -Be $sapHeader.Number
        $bom | Should -BeTrue

        $bom.Children.count | Should -Be 1
        $bom.Children.ChildNumber | Should -Be $childNumber
    }
}

<# ORIGINAL TESTS

### TESTS

$itemHeader = Get-VaultItem -Number 'M-000002'
$itemRow = Get-VaultItem -Number 'M-000003'

$newMaterialROW = New-ErpMaterial -VaultEntity $itemRow -VaultEntityType $itemRow._EntityTypeID 
$addedItemRow = Create-ErpMaterial -VaultEntity $itemRow -ErpMaterial $newMaterialROW

$newMaterialHeader = New-ErpMaterial -VaultEntity $itemHeader -VaultEntityType $itemHeader._EntityTypeID 
$addedItemHeader = Create-ErpMaterial -VaultEntity $itemHeader -ErpMaterial $newMaterialHeader

if(-not($addedItemRow) -or -not($addedItemHeader)){
    Write-Host "ITEM CREATION FAILED"
}

$sapItem = Get-ERPObject -EntitySet $global:itemEntitySet -Keys @{ "Number" = $addedItemRow.Number }
$sapHeader = Get-ERPObject -EntitySet $global:itemEntitySet -Keys @{ "Number" = $addedItemRow.Number }

if(-not($sapItem) -or -not($sapHeader)){
    Write-Host "ITEM QUERY FAILED"
}

$addedBOM = Add-ErpBom -BomHeader $itemHeader
if(-not($addedBOM)){
    Write-Host "BOM CREATION FAILED"
}

#>