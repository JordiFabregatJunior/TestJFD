<#
.SYNOPSIS
Checks if the items (Vault Files/Items) exists in ERP, or if the items are different. 

.DESCRIPTION
The function is called when pressing "Check" on the Item side in the BOM-Window.
All the items (Vault Files/Items) are passed to the function in order to check if the item exists in ERP.
It's also possible to throw exceptions. The BOM-Window will handle the exception and show the Error-Message on all remaining items.

.PARAMETER items
The list of items displayed in the BOM-Window.
#>
function Get-AdaptedDimension($Value){
    if ($Value -like "*.00*") {
        $adaptedValue = [Int] $Value
    } elseif ($Value -like "*.*" -and -not ($Value -like "*.00*")){
        $splittedStrings = $Value.split('.')
        [string]$adaptedValue = $splittedStrings[0] + '.' + $splittedStrings[1].Substring(0,2)
    } else {
        return $value
    }
    return $adaptedValue
}


function Check-Items($items) {
    foreach($item in $items) {
        $keys = (Get-ErpKey -VaultEntity $item -Type Item)
		if($item.BomType -eq "Virtual") {
	        $keys = @{$itemErpKey = $item.Bom_Number }
	    }
		$erpItem = Get-ERPObject -EntitySet $itemEntitySet -Keys $keys
		if($erpItem) {
			$toolTipMessage = 'Folgende Eigenschaften sind unterschiedlich:'
			foreach($vaultProp in $global:mappedPropertiesForCreation.Keys){
                $erpProp = [string]$global:mappedPropertiesForCreation[$vaultProp]
                if($erpProp -in @('ART_HOEHE','ART_BREITE','ART_LAENGE')){
                    $VaultAdaptedDimension = Get-AdaptedDimension -Value $item.$vaultProp
                    $ERPadaptedDimension = Get-AdaptedDimension -Value $erpItem.$erpProp
                    if( $VaultAdaptedDimension -ne $ERPadaptedDimension) {
                        $toolTipMessage += "`n'$vaultProp': Vault '$VaultAdaptedDimension' | ERP '$ERPadaptedDimension'"
                    } else {
                        if($item.$vaultProp -ne $erpItem.$erpProp) {
                            $toolTipMessage += "`n'$vaultProp': Vault '$($item.$vaultProp)' | ERP '$($erpItem.$erpProp)'"
                        }
                    }
                }
			}
			if($toolTipMessage -eq 'Folgende Eigenschaften sind unterschiedlich'){
				Update-BomWindowEntity -InputObject $item -Status 'Identical'
			} else {
				Update-BomWindowEntity -InputObject $item -Status 'Different' -ToolTip $toolTipMessage
			}
		} else {
			Update-BomWindowEntity -InputObject $item -Status 'New'
		}
	}
}

<#
.SYNOPSIS
Transfers the items (Vault Files/Items) to ERP.

.DESCRIPTION
The function is called when pressing "Transfer" on the Item side in the BOM-Window.
All the items (Vault Files/Items) are passed to the function in order to transfer them to ERP.
It's also possible to throw exceptions. The BOM-Window will handle the exception and show the Error-Message on all remaining items.

.PARAMETER items
The list of items displayed in the BOM-Window.
#>

function Transfer-Items($items) {
	foreach($item in $items) {
		$number = $item."$itemNumberPropName"
		if($item.BomType -eq "Virtual") {
			$number = $item.Bom_Number
		}
		
		if($item._Status -eq 'New'){
			$material = New-ErpMaterial -VaultEntity $item
			$material."$itemErpKey" = $number
			
			try {
				$createdMaterial = Create-ErpMaterial -VaultEntity $item -ErpMaterial $material -Link:$false
				if($createdMaterial) {
					Update-BomWindowEntity -InputObject $item -Status 'Identical' -ToolTip 'Erfolgreich erstellten und verknüpften Artikel'
				}else{
					Update-BomWindowEntity -InputObject $item -Status 'Error' -ToolTip "Fehler beim Ertsellen des Artikels: '$(Get-PowerGateError)'"
				}
			} catch {
				Update-BomWindowEntity -InputObject $item -Status 'Error' -ToolTip "$($_.Exception.Message)"
			}
		}
		elseif($item._Status -eq 'Different'){
			if((Update-ERPObject -EntitySet $global:itemEntitySet -Keys (Get-ErpKey -VaultEntity $item -Type Item) -Properties @{ Description=$item.Bezeichnung })){
				Update-BomWindowEntity -InputObject $item -Status 'Identical' -ToolTip 'Erfolgreich aktualisierter Artikel'
			}else{
				Update-BomWindowEntity -InputObject $item -Status 'Error' -ToolTip "Fehler beim Aktualisieren des Artikels: '$(Get-PowerGateError)'"
			}
		}
		elseif($item._Status -eq 'Remove'){
			$result = Remove-ERPObject -EntitySet $global:itemEntitySet -Keys (Get-ErpKey -VaultEntity $item -Type Item)
			if($result) {
				Remove-BomWindowEntity -InputObject $item
			}else{
				Update-BomWindowEntity -InputObject $item -Status 'Error' -ToolTip 'Fehler beim Entfernen von Elementen aufgetreten: ' + $result.Error
			}
		}
		elseif($item._Status -eq 'Identical') {
			Update-BomWindowEntity -InputObject $item -Status 'Identical'
		}
	}
}

<#
.SYNOPSIS
Checks if the BOM's (Vault File BOM/Item BOM) exists in ERP, or if the BOM's or its rows are different.

.DESCRIPTION
The function is called when pressing "Check" on the BOM side in the BOM-Window.
All the BOM's (Vault File BOM/Item BOM) are passed to the function in order to check if the BOM's or its rows exist in ERP.
It's also possible to throw exceptions. The BOM-Window will handle the exception and show the Error-Message on all remaining BOM's.

.PARAMETER boms
The list of BOM's displayed in the BOM-Window.
#>

function Check-Boms($boms) {
    foreach($vaultBom in $boms) {
           $vaultBomNumber = $vaultBom.Bom_Number
           if($vaultBom.Bom_Number -eq $null) {
                $vaultBomNumber = $vaultBom."$itemNumberPropName"
           }
           $erpBom = Get-ERPObject -EntitySet $bomEntitySet -Keys (Get-ErpKey -VaultEntity $vaultBom -Type Bom) -Expand "Children"
		   $bomRelatedErpItem = Get-ERPObject -EntitySet $global:itemEntitySet -Keys (Get-ErpKey -VaultEntity $vaultBom -Type Item)
			if(-not $bomRelatedErpItem) {
				throw "Der entsprechende Artikel für '$vaultBomNumber' ist noch nicht in R&S vorhanden, dieser muss bereits existieren um mit der Stückliste fortzufahren."
			}
		   
           # BomHeader Check
           if($erpBom -eq $null) {
                Update-BomWindowEntity -InputObject $vaultBom -Status New
           	} else {
				("Description","STLK_BEZ","STLK_FELD1") | foreach {if($erpBom.$_ -ne $vaultBom.Bezeichnung){$DifferentDescription = $true}}
				if($vaultBom.Basiseinheit -ne $erpBom.MEH_CD -or $DifferentDescription) {
                    if($vaultBom.Basiseinheit -ne $erpBom.MEH_CD) {
					    $toolTip = "'Basiseinheit' ist unterschiedlich: Vault '$($vaultBom.Basiseinheit)' / ERP '$($erpBom.MEH_CD)'"
                    }
					if($DifferentDescription) {
						$toolTip += "`n 'Bezeichnung' in Vault ('$($vaultBom.Bezeichnung)') unterscheidet sich von einer oder mehr der folgenden Eigenschaften in R&S: 'Description','STLK_BEZ','STLK_FELD1'"
					}
					Update-BomWindowEntity -InputObject $vaultBom -Status "Different" -ToolTip $toolTip 
				} else {
					Update-BomWindowEntity -InputObject $vaultBom -Status Identical
				}
			}
		    
           # BomRows Check
           if($erpBom.Children) {
               foreach($erpBomRow in $erpBom.Children) {
                   $vaultBomRow = $vaultBom.Children | Where-Object { $_."$($global:filePartNumberPropName)" -eq $erpBomRow.ChildNumber -and $_.Bom_PositionNumber -eq $erpBomRow.Position } | select -First 1
                   if( $vaultBomRow -eq $null) {
                        $bomRow = Add-BomWindowEntity -Type BomRow -Parent $vaultBom -Properties @{
							"Bom_Number"=$erpBomRow.ChildNumber
							"Artikelnummer"=$erpBomRow.ChildNumber
							"Bom_PositionNumber"=$erpBomRow.Position
							"Bom_Quantity"=$erpBomRow.Quantity
						}
                        Update-BomWindowEntity -InputObject $bomRow -Status Remove
                   } else {
                        if($vaultBomRow.Bom_Quantity -cne $erpBomRow.Quantity -or $vaultBomRow.Basiseinheit -ne $erpBomRow.STLP_MEH_CD1) {
                            Update-BomWindowEntity -InputObject $vaultBomRow -Status Different -Tooltip "'Quantity': Vault: '$($vaultBomRow.Bom_Quantity)' / ERP: '$($erpBomRow.Quantity)'`n'Basiseinheit': Vault: '$($vaultBomRow.Basiseinheit)' / ERP: '$($erpBomRow.STLP_MEH_CD1)'`n "
                        } else {
                            Update-BomWindowEntity -InputObject $vaultBomRow -Status Identical
                        } 
                   }
               }
            }            
            if($vaultBom.Children) {
               foreach($vaultBomRow in $vaultBom.Children) {
                  $erpBomRow = $erpBom.Children | Where-Object { $_.ChildNumber -eq $vaultBomRow."$($global:filePartNumberPropName)" -and $_.Position -eq $vaultBomRow.Bom_PositionNumber } | select -First 1
                  if( $erpBomRow -eq $null) {
                      Update-BomWindowEntity -InputObject $vaultBomRow -Status New
                  }
    	       }
           }
    }
}

function New-ErpBomRow($ParentNumber, $VaultBomRow) {
	$bomrow = New-ERPObject -EntityType $global:bomRowEntityType -Properties @{
		'ParentNumber' = $ParentNumber
		'ChildNumber' = $VaultBomRow.Artikelnummer
		'STLP_TEXT' = $VaultBomRow.Bezeichnung
		'Position' = [int]($VaultBomRow.Bom_PositionNumber)
		'Quantity' = $VaultBomRow.Bom_Quantity
		"STLP_MEH_CD1" = $VaultBomRow.Basiseinheit
		"MEH_CD" = "CM"
		"STLP_TYP" = "0"
	}
	$bomrow.AID2_CD = $bomrow.AID1_CD = $bomrow.STLP_AID1_CD = $bomrow.STLP_AID2_CD = "*"
	return $bomrow
}

function New-DefaultErpBom($ParentNumber, $VaultBOM, $Children) {
	$bom = New-ERPObject -EntityType "Bom" -Properties @{
		"ParentNumber" = $ParentNumber
		"Description" = $VaultBOM.Bezeichnung
		"STLK_BEZ" = $VaultBOM.Bezeichnung
		"STLK_FELD1" = $VaultBOM.Bezeichnung
		"MEH_CD" = $VaultBOM.Basiseinheit
		"STLK_FELD2" = "CAD"
		"STLK_BASISMENGE" = "1"
	}
	$bom.AID2_CD = $bom.AID1_CD = "*"
	$bom.Children = $Children
	return $bom
}

<#
.SYNOPSIS
Transfers the BOM's (Vault File BOM/Item BOM) to ERP.

.DESCRIPTION
The function is called when pressing "Transfer" on the BOM side in the BOM-Window.
All the BOM's (Vault File BOM/Item BOM) are passed to the function in order to transfer them to ERP.
It's also possible to throw exceptions. The BOM-Window will handle the exception and show the Error-Message on all remaining BOM's.

.PARAMETER items
The list of BOM's displayed in the BOM-Window.
#>

function Transfer-Boms($boms) {
    foreach($bom in $boms) {
		$parentNumber = $bom.Artikelnummer
		if($bom._Status -eq 'New'){
			$newErpBomChildren = @( $bom.Children | foreach-object { 
				New-ErpBomRow -ParentNumber $parentNumber -VaultBomRow $_	
			})
			$newErpBom = New-DefaultErpBom -ParentNumber $parentNumber -VaultBOM $bom -Children $newErpBomChildren
			$newErpBom.Flush = $true
			$result = Add-ERPObject -EntitySet $global:bomEntitySet -Properties $newErpBom

			if($result){
				Update-BomWindowEntity -InputObject $bom -Status 'Identical' -ToolTip 'Erfolgreich angelegte Stückliste!'
				$bom.Children | foreach {
					Update-BomWindowEntity -InputObject $_ -Status 'Identical' -ToolTip 'Erfolgreich angelegte Stücklistenzeile!'
				}
			}else{
				Update-BomWindowEntity -InputObject $bom -Status "Error" -ToolTip "Fehler beim Anlegen der Stückliste: '$(Get-PowerGateError)'"
			}
		} elseif($bom._Status -eq 'Identical'){
			$bom | Update-BomWindowEntity -Status 'Identical'
			foreach($bomRow in $bom.Children){
				$bomItem =  New-ErpBomRow -ParentNumber $parentNumber -VaultBomRow $bomRow
				$bomItem.Flush = $true
	            if($bomRow._Status -eq 'New'){
	    			if((Add-ERPObject -EntitySet 'BomRows' -Properties $bomItem)) {
	    				Update-BomWindowEntity -InputObject $bomRow -Status 'Identical' -ToolTip 'Erfolgreich angelegte Stücklistenzeile!'
	    			}else{
	    				Update-BomWindowEntity -InputObject $bomRow -Status "Error" -ToolTip "Fehler beim Anlegen der Stücklistenzeile: '$(Get-PowerGateError)'"
	    			}
	    		} elseif($bomRow._Status -eq 'Different'){
	    			if((Update-ERPObject -EntitySet 'BomRows' -Keys $bomItem._Keys -Properties $bomItem._Properties)){
	    				Update-BomWindowEntity -InputObject $bomRow -Status 'Identical' -ToolTip 'Stücklistenzeile erfolgreich aktualisiert!'
	    			}else{
	    				Update-BomWindowEntity -InputObject $bomRow -Status "Error" -ToolTip "Fehler beim Aktualisieren der Stücklistenzeile: '$(Get-PowerGateError)'"
	    			}
	    		} elseif($bomRow._Status -eq 'Remove'){
					#$bomItem.ChildNumber = $bomRow.ChildNumber
					$result = Remove-ERPObject -EntitySet 'BomRows' -Keys $bomItem._Keys
	    			if($result) {
	    				Remove-BomWindowEntity -InputObject $bomRow
	    			} else {
	    				Update-BomWindowEntity -InputObject $bomRow -Status 'Error' -ToolTip "Fehler beim Entfernen von Stücklistenzeile aufgetreten: '$(Get-PowerGateError)'"
	    			}
	    		} elseif($bomRow._Status -eq 'Identical') {
	    			Update-BomWindowEntity -InputObject $bomRow -Status 'Identical'
	    		}
	        }
		}
	}
}

Import-Module powerGate -Global
Import-Module powerVault -Global
Get-ChildItem -path ($env:ProgramData+'\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules') -Filter Vault.*.psm1 | foreach { Import-Module -Name $_.FullName -Global }	

$vaultContext.ForceRefresh = $true

$currentSelection = $vaultContext.CurrentSelectionSet[0]
$entityId = $currentSelection.Id
if($currentSelection.TypeId.EntityClassId -eq "FILE") {
	$global:selectedEntity = Get-VaultFile -FileId $entityId
} elseif($currentSelection.TypeId.EntityClassId -eq "ITEM") {
	$global:selectedEntity = Get-VaultItem -ItemId $entityId
} else {
	[System.Windows.Forms.MessageBox]::Show("Show Bom is not supported for EntityType $($currentSelection.TypeId.EntityClassId)!", "BOM Window: Not supported EntityType", "Ok") | Out-Null<
	return
}

Try-Operation {
	Show-BomWindow -Entity $selectedEntity
}