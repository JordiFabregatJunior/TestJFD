

<#
Import-Module powerVault
Import-Module PowerGate
$connected = Connect-ERP -Service "http://w10-2019-demo:8080/coolOrange/Navision"
<#Open-VaultConnection -Server "localhost" -Vault "Vault" -user "Administrator"

$entity = Get-VaultItem -Number 'NAV-0380'
$entity = Get-VaultFile -File '$/Designs/DEMOs/D_Exhaust Assembly.iam'
#$file = Get-VaultFile -File "$/Designs/Suspension/100001.iam"
#Remove-Module BomWindow
#Import-Module 'C:\ProgramData\Autodesk\Vault 2019\Extensions\DataStandard\Vault\addinVault\BomWindow.psm1'
#>
#supported states: Different, Error, Identical, New, Remove, Unknown



function Get-BomRows($entity) {
    
    $etype = $entity._EntityTypeID
    if($etype -eq $null) { return @() }
    if($etype -eq "File"){
        if($entity._FullPath -eq $null) { return @() } #due to a bug in the beta version.
        if($entity._Extension -eq 'ipt') { 
            if($entity.'Raw Quantity' -gt 0 -and $entity.'Raw Number' -ne "")
            {
                $rawMaterial = New-Object PsObject -Property @{'Part Number'= $entity.'Raw Number';'_PartNumber'= $entity.'Raw Number';'Name'= $entity.'Raw Number';'_Name'= $entity.'Raw Number';'Number'= $entity.'Raw Number';'_Number'= $entity.'Raw Number';'Bom_Number'= $entity.'Raw Number';'Bom_Quantity'= $entity.'Raw Quantity';'Bom_Position'='1';'Bom_PositionNumber'='1'}
                return @($rawMaterial)
            }
            return @()
        }
        $bomRows = Get-VaultFileBom -File $entity._FullPath -GetChildrenBy LatestVersion
    }
    else{
        if($entity._Category -eq 'Part') { return @() }
        $bomRows = Get-VaultItemBom -Number $entity._Number
    }
    
    foreach($bomRow in $bomRows){
        if($bomRow.Bom_XrefTyp -eq "Internal"){ #virtual component
            Add-Member -InputObject $bomRow -Name "_Name" -Value $bomRow.'Bom_Part Number' -MemberType NoteProperty -Force
            Add-Member -InputObject $bomRow -Name "Part Number" -Value $bomRow.'Bom_Part Number' -MemberType NoteProperty -Force
            Add-Member -InputObject $bomRow -Name "_PartNumber" -Value $bomRow.'Bom_Part Number' -MemberType NoteProperty -Force
        }
    }
    return $bomRows
}									

function Get-VaultPropValue {
    param(
        [ValidateSet('Number','Description')]$Property,
        $entity        
    )
    $etype = $entity._EntityTypeID
    if($etype -eq "File"){
        if($Property -eq 'Description'){
            return $entity.Title
        } else {
            return $entity._PartNumber 
        }            
    } else {
        if($Property -eq 'Description'){
            return $entity.'_Description(Item,CO)'
        } else {
            return $entity._Number 
        }     
    }
}

function Check-Items($entities) {
	foreach($entity in $entities) {

        $number = Get-VaultPropValue -Property 'Number' -entity $entity
        $vDescription = Get-VaultPropValue -Property 'Description' -entity $entity            

        $material = Get-ERPObject -EntitySet "ItemMethod" -Key @{"No"=$number.toUpper()}
        if($material -eq $null) 
        {
	    	Update-BomWindowEntity $entity -Status "New" -Tooltip "Item does not exist in ERP. Will be created."
		}
		else
		{
            Update-BomWindowEntity $entity -Status "Identical" -Tooltip ""
            if($vDescription -eq $null) {$vDescription = ""} 
            $eDescription = $material.Description
            if($eDescription -eq $null) {$eDescription = ""} 
            if($vDescription -eq $eDescription) {
	    	    Update-BomWindowEntity $entity -Status "Identical" -Tooltip ""
            }
            else {
                Update-BomWindowEntity $entity -Status "Different" -Tooltip "Vault Description '$vDescription' - ERP Description '$eDescription'"
            }
		}
	}
}
function Transfer-Items($entities) {
	foreach($entity in $entities) {
        $number = Get-VaultPropValue -Property 'Number' -entity $entity
        $vDescription = Get-VaultPropValue -Property 'Description' -entity $entity            

        if($entity._Status -eq "New") {
            $material = New-ERPObject -EntityType "ItemEntity" -Properties @{
                No=$number
                Description=$vDescription
                BaseUnitOfMeasure="PCS"
            }
            Add-ERPObject -EntitySet "ItemMethod" -Properties $material 
            Update-BomWindowEntity $entity -Status "Identical"
        }
        if($entity._Status -eq "Different") {
            $material = Update-ERPObject -EntitySet "ItemMethod" -Keys @{No=$number} -Properties @{Description=$vDescription}
            Update-BomWindowEntity $entity -Status "Identical"
        }
        if($entity._Status -eq "Identical"){
            Update-BomWindowEntity $entity -Status "Identical"
        }
	}
}
									
function Check-Boms($bomHeaders) {
	foreach($bomHeader in $bomHeaders) {
        if($entity._EntityTypeID -eq "FILE"){
            $number = $bomHeader._PartNumber
        }
        else{
            $number = $bomHeader._Number
        }
		$erpBom = Get-ERPObject -EntitySet "BOMMethod" -Key @{"No"=$number.ToUpper()} -Expand @("ProdBOMLine")
		if($erpBom -eq $null) {
	    	Update-BomWindowEntity $bomHeader -Status "New" -Tooltip "BOM does not exist in ERP. Will be created!"
            foreach ($bomRow in $bomHeader.Children) 
            {
                Update-BomWindowEntity $bomRow -Status "New" -Tooltip "Position will be added to ERP"
            }
		}
		else
		{
	    	Update-BomWindowEntity $bomHeader -Status "Identical" -Tooltip "BOM is identical between Vault and ERP"
            foreach ($bomRow in $bomHeader.Children) 
            {
                if($entity._EntityTypeID -eq "FILE"){
                    $number = $bomRow._PartNumber
                }
                else{
                    $number = $bomRow._Number
                }
                $erpRow = $erpBom.ProdBOMLine | Where-Object { 
                    $_.No -eq $number -and $_.Position -eq  $bomRow.Bom_PositionNumber 
                }
                if($null -ne $erpRow)
                {
                    if($bomRow.Bom_Quantity -eq $erpRow.Quantity_per)
                    {
                        Update-BomWindowEntity $bomRow -Status "Identical" -Tooltip "Position is identical"
                    }
                    else
                    {
                        Update-BomWindowEntity $bomRow -Status "Different" -Tooltip "Quantity is different: '$($bomRow.Bom_Quantity) <> $($erpRow.Quantity_per)'"
                        Update-BomWindowEntity $bomHeader -Status "Different" -Tooltip "BOMs are different between Vault and ERP!"
                    }
                }
                else
                {
                    Update-BomWindowEntity $bomRow -Status "New" -Tooltip "Position will be added to ERP"
                    Update-BomWindowEntity $bomHeader -Status "Different" -Tooltip "BOMs are different between Vault and ERP!"
                }
            }
            foreach ($erpRow in $erpBom.ProdBOMLine)
            {
                $bomRow = $bomHeader.Children | Where-Object { 
                    (Get-VaultPropValue -Property 'Number' -entity $_) -eq $erpRow.No -and $_.Bom_PositionNumber -eq  $erpRow.Position 
                }
                if($bomRow -eq $null)
                {
                    $remove = Add-BomWindowEntity -Type BomRow -Properties @{'Bom_Number'= $erpRow.No ;'Bom_Quantity'= $erpRow.Quantity_per; 'Bom_PositionNumber'=$erpRow.Position} -Parent $bomHeader
                    Update-BomWindowEntity $remove -Status "Remove" -Tooltip "Position will be deleted in ERP"
                    Update-BomWindowEntity $bomHeader -Status "Different" -Tooltip "BOMs are different between Vault and ERP!"
                }
            }
		}
	}
}

function Get-BomRow ($item, $bomRow, $bomHeader){
    $bomRowProps = @{
        Type="Item"
        Key=""
        HeaderNo= Get-VaultPropValue -Property 'Number' -entity $bomHeader
        No= Get-VaultPropValue -Property 'Number' -entity $bomRow
        Quantity_per=$bomRow.Bom_Quantity
        Description= Get-VaultPropValue -Property 'Description' -entity $item
        Position=$bomRow.Bom_PositionNumber.ToString()
        Length="0"
        Width="0"
        Depth="0"
        Weight="0"
        Unit_of_Measure_Code=$item.BaseUnitOfMeasure
        Scrap_Percent="0"
        Starting_Date="2016-01-01"
        Ending_Date="2016-01-01"
    }
    return $bomRowProps
}

function Transfer-Boms($bomHeaders) {
	foreach($bomHeader in $bomHeaders) {
        
        if($bomHeader._Status -eq "New")
        {
            $no = Get-VaultPropValue -Property 'Number' -entity $bomHeader
			$ProdBOMLine = @()
			foreach($bomRow in $bomHeader.Children)
            {
                $child = Get-VaultPropValue -Property 'Number' -entity $bomRow
                $item = Get-ERPObject -EntitySet "ItemMethod" -Key @{"No"=$child.toUpper()}
				$BOMrw = Get-BomRow -Item $item -BomRow $bomRow -BomHeader $bomHeader
				$ProdBOMLine += $BOMrw
			}
            $properties = @{
                "No"=$no.ToString()
                "Description"=$bomHeader.Title
                "Last_Date_Modified"=[DateTime]::Now
                Unit_of_Measure_Code="PCS"
                "ProdBOMLine"=$ProdBOMLine
            }
			Add-ERPObject -EntitySet "BOMMethod" -Properties $properties
		    Update-BomWindowEntity $bomHeader -Status "Identical"
            foreach ($bomRow in $bomHeader.Children) 
            {
                Update-BomWindowEntity $bomRow -Status "Identical" -Tooltip ""
            }
        }
        elseif($bomHeader._Status -eq "Different")
        {
            Remove-ERPObject -EntitySet "BOMMethod" -Keys @{No=$bomHeader._PartNumber}
            $no = $bomHeader._PartNumber
			$ProdBOMLine = @()
			foreach($bomRow in $bomHeader.Children)
            {
                if($bomRow._Status -ne "Remove")
                {
                    $child = $bomRow._PartNumber
                    $item = Get-ERPObject -EntitySet "ItemMethod" -Key @{"No"=$child}
                    $BOMrw = @{Type="Item";Key="";HeaderNo=$no.ToString();No=$child.ToString();Quantity_per=$bomRow.Bom_Quantity;Description=$bomRow.Title;Position=$bomRow.Bom_PositionNumber.ToString();Length="0";Width="0";Depth="0";Weight="0";Unit_of_Measure_Code=$item.BaseUnitOfMeasure;Scrap_Percent="0";Starting_Date="2016-01-01";Ending_Date="2016-01-01"}
                    $ProdBOMLine += $BOMrw
                }
                else {
                    Remove-BomWindowEntity $bomRow
                }
			}
			$properties = @{"No"=$no.ToString();"Description"=$bomHeader.Title;"Last_Date_Modified"=[DateTime]::Now;Unit_of_Measure_Code="PCS";"ProdBOMLine"=$ProdBOMLine}
			Add-ERPObject -EntitySet "BOMMethod" -Properties $properties
		    Update-BomWindowEntity $bomHeader -Status "Identical"
            foreach ($bomRow in $bomHeader.Children) 
            {
                Update-BomWindowEntity $bomRow -Status "Identical" -Tooltip ""
            }
            
        }
        else{
            Update-BomWindowEntity $bomHeader -Status $bomHeader._Status
            foreach ($bomRow in $bomHeader.Children) 
            {
                Update-BomWindowEntity $bomRow -Status $bomRow._Status
            }
        }
	}
}



$vaultContext.ForceRefresh = $true
$id=$vaultContext.CurrentSelectionSet[0].Id
if($vaultContext.CurrentSelectionSet[0].TypeId.EntityClassId -eq "FILE"){
    $entity = Get-VaultFile -FileId $id
}
else {
    $entity = Get-VaultItem -ItemId $id
}

try {
    Show-BomWindow -Entity $entity    
}
catch {
    $_.Exception | ConvertTo-Json | Out-File c:\temp\bomwindow.err
}


#>