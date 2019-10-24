#cd 'C:\Users\uib06819\Desktop\COrange\CO_JFD\Tests'
<### READ ME!

The tests require user intereaction (MessageBoxes)

Also the Vault data needs to be prepared (can not be set easily since a huge number of restrictions)
There are some data preparation tests; good to look at them to see which requirements needed

###>


Import-Module powerGate -Global
Import-Module powerVault -Global
Import-Module 'C:\ProgramData\coolOrange\powerEvents\Modules\SAP.Release.Helpers.psm1'
Import-Module "$($env:ProgramFiles)\coolorange\Modules\powerGate\powerGate_Connections.psm1"
Get-ChildItem -path ($env:ProgramData+'\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules') -Filter Vault.*.psm1 | foreach { Import-Module -Name $_.FullName -Global -Force}	
Connect-ToErpServer
Open-VaultConnection -Server "hscmas07" -Vault "CM-01" -user "coolOrangeAdmin " -Password "12345"

### DATA INITIALIZATION
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
        if($item._Number -eq 'M-0000002'){
            $resetProperties.Add( "01 SAP-No.",'')
        }
        $resetItem = Update-VaultItem -Number $item._Number -Properties $resetProperties
        $returnItems += $resetItem
    }

    return $returnItems
}

### TESTS

Describe "Worklfow on item transition to Released " {

    $itemHeader = Get-VaultItem -Number 'M-0000002'
    $itemRow = Get-VaultItem -Number 'M-0000003'

    $resetItems = Reset-ItemsWithWorkingProperties -Items @($itemRow,$itemHeader)
    
    $resetItemHeader = Get-VaultItem -Number 'M-0000002'
    $resetItemRow = Get-VaultItem -Number 'M-0000003'

    Context "Checking test data is prepared for tests"{

        It "Row is ready for the tests" {
            $resetItemRow._State | Should -Be "Released"
            $resetItemRow.'01 SAP-No.' | Should -BeTrue
            $resetItemRow.'15 Order Unit' | Should -Be "PC"
        }
        
        It "Header is ready for the tests" {
            $resetItemHeader.'01 SAP-No.' | Should -BeFalse
            $resetItemHeader.'15 Order Unit' | Should -Be "PC"
        }
    }

    Context "Material and BOM creation (BomHeader)"{
        Add-Member -InputObject $resetItemHeader -Name _NewState -Value "Released" -MemberType NoteProperty -Force
        # NOTE: USER INTERACTION REQUIRED!!!
        Invoke-ReleaseProcess -Item $resetItemHeader

        $latestVersionItemHeader = Get-VaultItem -Number 'M-0000002'
        $parentNumber = Get-SAPNumber -VaultEntity $latestVersionItemHeader
        $ChildNumber = Get-SAPNumber -VaultEntity $resetItemRow

        $sapHeader = Get-ERPObject -EntitySet $global:itemEntitySet -Keys @{ "Number" = $parentNumber }
        $bom = Get-ERPObject -EntitySet "BOMS" -Keys @{ "ParentNumber" = $ParentNumber } -Expand "Children"        

        It "Header exists in SAP" {
            $sapHeader | Should -BeTrue
            $parentNumber | Should -Be $sapHeader.Number
            $bom | Should -BeTrue
        }

        It "Children properly set in SAP" {
            $bom.Children.count | Should -Be 1
            $bom.Children.ChildNumber | Should -Be $childNumber
        }
    }
}

<# ORIGINAL TESTS

### TESTS

$itemHeader = Get-VaultItem -Number 'M-0000002'
$itemRow = Get-VaultItem -Number 'M-0000003'

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