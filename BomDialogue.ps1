<###___DEBUGGING
Import-Module powerGate -Global
Import-Module powerVault -Global
$connected = Connect-erp "http://16llt_cad1:8080/R&S/SQL/"
Get-ChildItem -path ($env:ProgramData+'\Autodesk\Vault 2019\Extensions\DataStandard\powerGate\Modules') -Filter Vault.*.psm1 | foreach { Import-Module -Name $_.FullName -Global }	
Open-VaultConnection -Server 16llt_cad1 -Vault Hera -User Administrator -Password AutodeskVault@26200
#$global:selectedEntity = Get-VaultFile -File "$/CAD_Projekte/1 Boxen/02 BasicBox/00 BasicBox Allgemein/ENG000000103.ipt"
$global:selectedEntity = Get-VaultFile -File "$/CAD_Projekte/Test/ENG000011909.iam"
#$global:selectedEntity = Get-VaultFile -File "$/CAD_Projekte/Lieferantennormteile/LogicLine Profile/ENG000007551.ipt"
#>


function Get-LatestReleaseVersion ($VaultEntity){
	$fileVersions = $vault.DocumentService.GetFilesByMasterId($VaultEntity.MasterId) | Sort-Object -Property VerNum -Descending
	foreach($Id in $fileVersions.Id){
		$specificVersion = Get-VaultFile -FileId $Id
		if($specificVersion.'_State(Ver)' -eq 'Freigegeben' -and $specificVersion.Revision -eq $VaultEntity.Revision){
			return $specificVersion
		}
	}
}

function Get-LatestReleaseCheckInDate ($VaultEntity){
	$LatestReleasedVersion = Get-LatestReleaseVersion -VaultEntity $VaultEntity
    if($LatestReleasedVersion){
	    return ($LatestReleasedVersion._CheckInDate).ToString('ddMMyyyy')
    } else {
        return ""
    }
}

function Get-AdaptedDimension($Value){
    if ($Value -like "*,*") {
        $splittedStrings = $Value -split ","
        if ($Value -like "*,00*") {
            [string]$adaptedValue = $splittedStrings | select -First 1
        } else {
            [string]$adaptedValue = $splittedStrings[0] + ',' + $splittedStrings[1].Substring(0,2)
        }
        return $adaptedValue
    } else {
        return $Value
    }
}

function Get-DerivedParts ($VaultEntity){
	$assocs = Get-VaultFileAssociations -File $VaultEntity._FullPath -Dependencies
	return $assocs | where {$_._Extension -eq 'ipt'}
}

function Test-IfExistingDerivedParts ($VaultEntity){
	return $VaultEntity._Extension -eq 'ipt' -and @(Get-DerivedParts -VaultEntity $VaultEntity).Count -gt 0
}

function Get-CorrectDerivedPart ($VaultProfileEntity){
	$bomRows = @()
	if($VaultProfileEntity.'RohmaterialAktualisieren' -contains 'True'){
		$derivedParts = Get-DerivedParts -VaultEntity $VaultProfileEntity
		if($derivedParts.count -gt 1){
			$rawMaterialVaultEntity = ($derivedParts | where {$_.Artikelnummer -eq $VaultProfileEntity.'RohmaterialArtikelnummer'}) | Select -First 1
			$latestVersion = $vault.DocumentService.GetLatestFileByMasterId($rawMaterialVaultEntity.Masterid)
            $latestVersionRawMaterial = Get-VaultFile -FileId $latestVersion.Id
            $bomRows += $latestVersionRawMaterial
		} else {
			$bomRows += $derivedParts | select -First 1
		}
	}
	return $bomRows
}

function Get-RowMengeAndMEH ($VaultBomHeader, $VaultBomRow){
	if($VaultBomRow.Basiseinheit -eq 'STK'){
		$STLP_MENGE = 1
		$STLP_MEH_CD1 = $VaultBomHeader.Basiseinheit 
	} elseif ($VaultBomRow.Basiseinheit -in @('M','MM')){
		$STLP_MENGE = $VaultBomHeader.G_L_Value 
		$STLP_MEH_CD1 = $VaultBomHeader.G_L_Unit 
	} elseif ($VaultBomRow.Basiseinheit -in @('M2','MM2')){
		$STLP_MENGE = $VaultBomHeader.G_A_Value 
		$STLP_MEH_CD1 = $VaultBomHeader.G_A_Unit 
	}
	return @{"Menge" = $STLP_MENGE; "MEH" = $STLP_MEH_CD1}
}

function Test-MengeAndMEHSetProperly ($VaultBomHeader, $VaultBomRow){
	$rowMengeAndMEH = Get-RowMengeAndMEH -VaultBomHeader $VaultBomHeader -VaultBomRow $VaultBomRow
    return -not([string]::IsNullOrEmpty($rowMengeAndMEH["Menge"]))  -and $rowMengeAndMEH["Menge"] -ne '0' -and $VaultBomRow.Basiseinheit -in @('STK','M','MM','M2','MM2')
}

function Get-BomRows($bomHeader) {
	if($bomHeader._EntityType.Id -eq "FILE") {
		if($bomHeader.Bom_Structure -eq 'Purchased') {
			$bomRows = @()
		} else {
			$isPartWithDerived = Test-IfExistingDerivedParts -VaultEntity $bomHeader
			if($isPartWithDerived){
				$bomRows = Get-CorrectDerivedPart -VaultProfileEntity $bomHeader
				foreach($bomRow in $bomRows){
					$rowMengeAndMEH = Get-RowMengeAndMEH -VaultBomHeader $bomHeader -VaultBomRow $bomRow
					$STLP_MENGE = $rowMengeAndMEH["Menge"]
					$STLP_MEH_CD1 = $rowMengeAndMEH["MEH"]				
					Add-Member -InputObject $bomRow -Name Bom_PositionNumber -Value '1' -MemberType NoteProperty -Force
					Add-Member -InputObject $bomRow -Name Bom_Quantity -Value $STLP_MENGE -MemberType NoteProperty -Force
					Add-Member -InputObject $bomRow -Name BasiseinheitDerivedRow -Value $STLP_MEH_CD1 -MemberType NoteProperty -Force
				}
			} else {
				$bomRows = Get-VaultFileBom -File $bomHeader._FullPath -GetChildrenBy LatestVersion
			}
		}
	} elseif($bomHeader._EntityType.Id -eq "ITEM"){
		$bomRows = Get-VaultItemBom -Number $bomHeader._Number
	} else {
		$bomRows = @()
	}
	$bomRows | foreach {
		if($_._EntityType.Id -eq $null) {
			Add-Member -InputObject $_ -Name "BomType" -Value "Virtual" -MemberType NoteProperty -Force
		}
		if($bomHeader.Bom_RowOrder) {
			Add-Member -InputObject $_ -Name Bom_RowOrder -Value ("{0}.{1}" -f $bomHeader.Bom_RowOrder,$_.Bom_RowOrder) -MemberType NoteProperty -Force
		}
	}
	return $bomRows
 }

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
					} 
				} else {
					if($item.$vaultProp -ne $erpItem.$erpProp) {
						$toolTipMessage += "`n'$vaultProp': Vault '$($item.$vaultProp)' | ERP '$($erpItem.$erpProp)'"
					}
                }
			}
			$needsRevision = Test-IfRevisionNeeded -VaultEntity $item
			if($needsRevision){
				$currentFourDigitsRevision = Get-FileRevisionWithFourDigits -VaultEntity $item
				if($currentFourDigitsRevision -ne $erpItem.XART_MERKMAL40){
					$toolTipMessage += "`n'Revision': Vault '$currentFourDigitsRevision' | ERP '$($erpItem.XART_MERKMAL40)'"
				}
			}	
			if($toolTipMessage -eq 'Folgende Eigenschaften sind unterschiedlich:'){
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
			$keys = (Get-ErpKey -VaultEntity $item -Type Item)
			$erpItem = Get-ERPObject -EntitySet $itemEntitySet -Keys $keys
			if(Update-ErpMaterial -ErpMaterial $erpItem -VaultEntity $item -FromBOMWindow){
				Update-BomWindowEntity -InputObject $item -Status 'Identical' -ToolTip 'Erfolgreich aktualisierter Artikel'
			}else{
				Update-BomWindowEntity -InputObject $item -Status 'Error' -ToolTip "Fehler beim Aktualisieren des Artikels: '$(Get-PowerGateError)'"
			}
		}
		elseif($item._Status -eq 'Remove'){
			$result = Remove-ERPObject -EntitySet $global:itemEntitySet -Keys (Get-ErpKey -VaultEntity $item -Type Item)
			if($result) {
				Remove-BomWindowEntity -InputObject $item
			} else {
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
		$isPartWithDerivedParts = Test-IfExistingDerivedParts -VaultEntity $vaultBom
		$vaultBomNumber = $vaultBom.Bom_Number
		if($vaultBom.Bom_Number -eq $null) {
			$vaultBomNumber = $vaultBom."$itemNumberPropName"
		}
		$bomRelatedErpItem = Get-ERPObject -EntitySet $global:itemEntitySet -Keys (Get-ErpKey -VaultEntity $vaultBom -Type Item)
		if(-not $bomRelatedErpItem) {
			throw "Der entsprechende Artikel für '$vaultBomNumber' ist noch nicht in R&S vorhanden, dieser muss bereits existieren um mit der Stückliste fortzufahren."
		}
		
		$erpBom = Get-ERPObject -EntitySet $bomEntitySet -Keys (Get-ErpKey -VaultEntity $vaultBom -Type Bom) -Expand "Children"
		# BomHeader Check
		if($erpBom -eq $null) {
			Update-BomWindowEntity -InputObject $vaultBom -Status New
            if($isPartWithDerivedParts){
                foreach($VaultBomRow in $vaultBom.Children){
                    if(-not(Test-MengeAndMEHSetProperly -VaultBomHeader $vaultBom -VaultBomRow $VaultBomRow)){
			            Update-BomWindowEntity -InputObject $vaultBomRow -Status Error -ToolTip "Menge hat keinen gültigen Wert oder ist leer. Stellen Sie sicher, dass sowohl Menge als auch Basiseinheit korrekt ausgefüllt sind."
                    }
                }
            }   
		} else {
			$BOMHeaderArtikelAndRevision = Get-NumberAndRevision -VaultEntity $vaultBom   
			$BOMLatestReleasedCheckInDate = Get-LatestReleaseCheckInDate -VaultEntity $vaultBom
			("Description","STLK_BEZ","STLK_FELD1") | foreach {if($erpBom.$_ -ne $vaultBom.Bezeichnung){$DifferentDescription = $true}}
			if($vaultBom.Basiseinheit -ne $erpBom.MEH_CD -or $DifferentDescription -or $BOMHeaderArtikelAndRevision -ne $erpBom.STLK_NR -or $BOMLatestReleasedCheckInDate -ne $erpBom.STLK_FELD3) {
				if($vaultBom.Basiseinheit -ne $erpBom.MEH_CD) { $toolTip = "'Basiseinheit' ist unterschiedlich: Vault '$($vaultBom.Basiseinheit)' / ERP '$($erpBom.MEH_CD)'" }
				if($BOMHeaderArtikelAndRevision -ne $erpBom.STLK_NR) { $toolTip += "`n 'ArtikelNummer#Revision': Vault: '$($BOMHeaderArtikelAndRevision)' / ERP: '$($erpBom.STLK_NR)'" }
				if($DifferentDescription) { $toolTip += "`n 'Bezeichnung' in Vault ('$($vaultBom.Bezeichnung)') unterscheidet sich von einer oder mehr der folgenden Eigenschaften in R&S: 'Description','STLK_BEZ','STLK_FELD1'" }
				if($BOMLatestReleasedCheckInDate -ne $erpBom.STLK_FELD3) { $toolTip += "`n 'CheckedIn_Datum(Letzte Freigegebene Version)': Vault: '$($BOMLatestReleasedCheckInDate)' / ERP: '$($erpBom.STLK_FELD3)'" }
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
					$tooltip = ""
					#'Basiseinheit' check: 
					if($isPartWithDerivedParts) {
						if(-not(Test-MengeAndMEHSetProperly -VaultBomHeader $vaultBom -VaultBomRow $VaultBomRow)){
							Update-BomWindowEntity -InputObject $vaultBomRow -Status Error -Tooltip "Die Eigenschaft 'Basiseinheit' ist nicht gültig. Stellen Sie sicher, dass es nicht Null ist und dass es einen der folgenden Werte annimmt: 'STK','M','MM','M2','MM2'"
							continue
						} elseif($vaultBomRow.BasiseinheitDerivedRow -ne $erpBomRow.STLP_MEH_CD1) {
							$toolTip += "`n'Basiseinheit': Vault: '$($vaultBomRow.BasiseinheitDerivedRow)' / ERP: '$($erpBomRow.STLP_MEH_CD1)'"
						}
					} else {
						if($vaultBomRow.Basiseinheit -ne $erpBomRow.STLP_MEH_CD1){
							$toolTip += "`n'Basiseinheit': Vault: '$($vaultBomRow.Basiseinheit)' / ERP: '$($erpBomRow.STLP_MEH_CD1)'"
						}
					}
					# Common properties check:
					if ($vaultBomRow.Bezeichnung -ne $erpBomRow.Description -or $BOMHeaderArtikelAndRevision -ne $erpBomRow.STLK_NR -or $vaultBomRow.Bom_Quantity -cne $erpBomRow.Quantity) {
						Update-BomWindowEntity -InputObject $vaultBomRow -Status Different -Tooltip "'Bezeichnung': Vault: '$($vaultBomRow.Bezeichnung)' / ERP: '$($erpBomRow.Description)'`n'ArtikelNummer#Revision': Vault: '$($BOMHeaderArtikelAndRevision)' / ERP: '$($erpBomRow.STLK_NR)'`n'Quantity': Vault: '$($vaultBomRow.Bom_Quantity)' / ERP: '$($erpBomRow.Quantity)'"
					} 
					if([string]::IsNullOrEmpty($toolTip)) {
						Update-BomWindowEntity -InputObject $vaultBomRow -Status Identical
					} else {
						Update-BomWindowEntity -InputObject $vaultBomRow -Status Different -Tooltip $tooltip
					}
				}
			}
		}            
		if($vaultBom.Children) {
			foreach($vaultBomRow in $vaultBom.Children) {
				$erpBomRow = $erpBom.Children | Where-Object { $_.ChildNumber -eq $vaultBomRow."$($global:filePartNumberPropName)" -and $_.Position -eq $vaultBomRow.Bom_PositionNumber } | select -First 1
				if( $erpBomRow -eq $null -and $vaultBomRow._Status -ne "Error") {
					Update-BomWindowEntity -InputObject $vaultBomRow -Status New
				}
			}
		}
    }
}

function New-ErpBomRow($VaultBomHeader, $VaultBomRow) {
	$ParentNumberWithRevision = Get-NumberAndRevision -VaultEntity $VaultBomHeader
	if(Test-IfExistingDerivedParts){
		$BasiseinheitBomRow = $VaultBomRow.BasiseinheitDerivedRow
	} else {
		$BasiseinheitBomRow = $VaultBomRow.Basiseinheit
	}
	$bomrow = New-ERPObject -EntityType $global:bomRowEntityType -Properties @{
		'ParentNumber' = $ParentNumberWithRevision
		'ChildNumber' = $VaultBomRow.Artikelnummer
		'Description' = $VaultBomRow.Bezeichnung
		'STLP_TEXT' = $VaultBomRow.Bezeichnung
		'Position' = [int]($VaultBomRow.Bom_PositionNumber)
		'Quantity' = $VaultBomRow.Bom_Quantity
		"STLP_MEH_CD1" = $BasiseinheitBomRow
		"STLP_TYP" = "0"
	}
	$bomrow.AID2_CD = $bomrow.AID1_CD = $bomrow.STLP_AID1_CD = $bomrow.STLP_AID2_CD = "*"
	return $bomrow
}

function New-DefaultErpBom($VaultBOM, $Children) {
	$
	$bom = New-ERPObject -EntityType "Bom" -Properties @{
		"ParentNumber" = Get-NumberAndRevision -VaultEntity $VaultBom
		"Description" = $VaultBOM.Bezeichnung
		"STLK_BEZ" = $VaultBOM.Bezeichnung
		"STLK_FELD1" = $VaultBOM.Bezeichnung
		"STLK_FELD3" = Get-LatestReleaseCheckInDate -VaultEntity $VaultBOM
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
        $bom.Children | foreach-object { if($_._Status -eq "Error"){ throw "Bitte stellen Sie sicher, dass alle Anforderungen, die in der Prüfung angegeben sind, korrekt eingestellt sind."}}
		if($bom._Status -eq 'New' -or $bom._Status -eq 'Different'){
			$newErpBomChildren = @( $bom.Children | foreach-object { 
				New-ErpBomRow -VaultBomHeader $bom -VaultBomRow $_
			})
			$newErpBom = New-DefaultErpBom -VaultBOM $bom -Children $newErpBomChildren
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
			if($bom.Children._Status -notcontains "Different" -and $bom.Children._Status -notcontains "New" -and $bom.Children._Status -notcontains "Error"){
				$bom.Children | foreach-object { Update-BomWindowEntity -InputObject $_ -Status 'Identical'	}
			} else {
				$newErpBomChildren = @( $bom.Children | foreach-object { New-ErpBomRow -VaultBomHeader $bom -VaultBomRow $_ })
				$newErpBom = New-DefaultErpBom -VaultBOM $bom -Children $newErpBomChildren
				$addedNewVersionErpBom = Add-ERPObject -EntitySet $global:bomEntitySet -Properties $newErpBom
				if($addedNewVersionErpBom){
					$bom.Children | foreach-object { Update-BomWindowEntity -InputObject $_ -Status 'Identical'	}
				}else{
					$bom.Children | foreach-object { Update-BomWindowEntity -InputObject "Error" -ToolTip "Error creating BOM row: '$(Get-PowerGateError)'"	}
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