# [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12  
Import-Module "$($env:ProgramFiles)\coolorange\Modules\powerGate\connections_sap.psm1"
Import-Module powerGate

### ENSURE CREDENTIALS UP TO DATE!!!
#connect -TestQ

function Connect-ToErpServer {
	$user = 'COO'							# Test system
	#$password = 'Mvwerft@1' 								    # Enwicklungs (development) systemm
	#$gatewayURL = "http://sapdberdgw01.yardsresdomde.com:8000"  # Enwicklungs (development) systemm
	$gatewayURL = "http://sapdbqrdgw01.yardsresdomde.com:8000" # Test system
	$password = 'Cool0range#'		
	$global:connected = Connect-ERP -Service "$gatewayURL/sap/opu/odata/arcona6/material_srv/" -OnConnect $global:extendedSapConnect -User $user -Password $password 
	$global:connected = (Connect-ERP -Service "$gatewayURL/sap/opu/odata/arcona6/BILL_OF_MATERIAL_SRV/" -User $user -Password $password -OnConnect $global:extendedSapConnect) -and $global:connected
	$global:connected = (Connect-ERP -Service "$gatewayURL/sap/opu/odata/arcona6/DOCUMENT_INFO_RECORD_SRV/" -User $user -Password $password -OnConnect $global:extendedSapConnect) -and $global:connected
}
Connect-ToErpServer

$plant = '4500'
$valArea = '4500'

<#read
$number = '000000000000900010'
$material = Get-ERPObject -EntitySet "MaterialContextCollection" -Keys @{Material=$number;Plant=$plant;ValuationArea=$valArea;ValuationType=''} -Expand @("Description","PlantData","BasicData","ValuationData")

#search
$materials = Get-ERPObjects -EntitySet "MaterialContextCollection" -Top 3
# $materials = Get-ERPObjects -EntitySet "MaterialContextCollection" -Top 3 -Filter "endswith(Material, '10') eq true" -> prüfen
$material = Get-ERPObjects -EntitySet "MaterialContextCollection" -Top 3 -Filter "substringof(Material, '990') eq true" #=> ! FEHLER, Prüfen
$material.Count#>

<#Create
#
$number = ''#'000000000000099014'# Formatierung, MaterialNr richtig formatieren
$plant = '4500'
$valArea = '4500'
$materialType = 'ROH'
$ValuationClass = ''
$PurchasingValueKey = 'FMD1'
$descriptions =@()
$descriptions += New-ERPObject -EntityType "material_srv.Description" -Properties @{Material=$number;Langu='D';MatlDesc='test coolOrange DE' }
$descriptions += New-ERPObject -EntityType "material_srv.Description" -Properties @{Material=$number;Langu='E';MatlDesc='test coolOrange EN' }
$basicData = New-ERPObject -EntityType "BasicData" -Properties @{
    Material=$number
    BaseUom='ST'
    BaseUomIso=''
    IndSector='A'
    MatlGroup='PRODUNEED'
    MatlType=$materialType
    PurchasingValueKey = $PurchasingValueKey
}
$valuationData =@()
$valuationData = New-ERPObject -EntityType "ValuationData" -Properties @{
    Material=$number
    ValArea=$valArea
    ValType=''
    StdPrice='0.0000'
    PriceUnit='1'
    ValCategory=''
    PriceControl='V'
    MovingPrice='0.0000'
    ValClass=$ValuationClass
}
$properties = New-ERPObject -EntityType "MaterialContext" -Properties @{
    Material=$number
    Plant=$plant
    ValuationArea=$valArea
    ValuationType=''
    Description=$descriptions
    BasicData=$basicData
    ValuationData=$valuationData
}
$material = Add-ERPObject -EntitySet "MATERIAL_SRV/MaterialContextCollection" -Properties $properties

$number = $material.Material
$searchedMaterial = Get-ERPObject -EntitySet "MaterialContextCollection" -Keys @{Material=$number;Plant=$plant;ValuationArea=$valArea;ValuationType=''} -Expand @("Description","PlantData","BasicData","ValuationData")
#>


###TESTS WITH PRODUCTIVE FUNCTION

$userModifiedNewErpMaterial = New-ErpMaterial -VaultEntity $selectedEntity -MaterialType $MaterialType -IndustrySector $IndustrySector -UserModifiedMaterial $global:newErp_material -DocInfo


function New-ErpMaterial($VaultEntity, $MaterialType,$ValuationClass) {
    $PurchasingValueKey = 'FMD1'
    $IndustrySector = 'A'
	if ($VaultEntity._EntityTypeID -eq 'File' -or $FromInventor) {
		$material = ''
		if($UserModifiedMaterial){ #If two language possibilities, currently set as DE
			$germanDescription = $UserModifiedMaterial.germanDescription
			$englishDescription = $UserModifiedMaterial.englishDescription
			$purchaseOrderText = $UserModifiedMaterial.purchaseOrderTextDE
			$basicDataGrundDatenText = $UserModifiedMaterial.basicDataTextDE
			$oldMaterialNumber = $UserModifiedMaterial.BasicData.OldMaterialNumber
		} elseif($FromInventor){
			$basicDataGrundDatenText = $germanDescription = $englishDescription = $purchaseOrderText = $oldMaterialNumber = ""
		} else {
			$basicDataGrundDatenText = $VaultEntity.'00 BUILD NUMBER'
			$germanDescription = $VaultEntity.'04 DESCRIPTION GERMAN'
			$englishDescription = $VaultEntity.'03 DESCRIPTION ENGLISH'
			$purchaseOrderText = $VaultEntity.'14 MANUFACTURER'
			$oldMaterialNumber = $VaultEntity.'44 MANUFACTURER ITEM NUMBER'
		}

        $plant = '4500'
        $valArea = '4500'	

		#$plant = $global:PlantNumber
		#$valArea = $global:ValuationArea

		$descriptions =@()
		$descriptions += New-ERPObject -EntityType "material_srv.Description" -Properties @{Material=$material;Langu='D';MatlDesc=$germanDescription }
		$descriptions += New-ERPObject -EntityType "material_srv.Description" -Properties @{Material=$material;Langu='E';MatlDesc=$englishDescription }
		
		#BASIC_DATA_TEXT (afterwards included into BASIC_DATA (navigation property) )
		$basicDataText =@()
		$basicDataText += New-ERPObject -EntityType "material_srv.BasicDataText" -Properties @{Material=$material;LanguageISO='DE';Text= $basicDataGrundDatenText }
		$basicDataText += New-ERPObject -EntityType "material_srv.BasicDataText" -Properties @{Material=$material;LanguageISO='EN';Text= $basicDataGrundDatenText }

		#PURCHASE_ORDER_TEXT (afterwards included into BASIC_DATA (navigation property) )
		$purchaseOrder =@()
		$purchaseOrder += New-ERPObject -EntityType "material_srv.PurchaseOrderText" -Properties @{Material=$material;LanguageISO='DE'; Text= $purchaseOrderText }
		$purchaseOrder += New-ERPObject -EntityType "material_srv.PurchaseOrderText" -Properties @{Material=$material;LanguageISO='EN'; Text= $purchaseOrderText }

		#PLANT DATA
		$plantData = New-ERPObject -EntityType "PlantData" -Properties @{Material=$material;Plant = $plant;Availcheck='02';PurGroup='';PurStatus='';Pvalidfrom=''}

		#BASIC_DATA (#Doc Info here included!)
		$basicDataProps = @{
			Material=$material
			IndSector=$IndustrySector
			MatlType=$MaterialType
			MatlGroup='PRODUNEED'
			BaseUom='ST'
			BaseUomIso=''
			NetWeight = [decimal]$VaultEntity.'17 Weight'
			Size_Dimensions = $VaultEntity.'41 SIZE'
			OldMaterialNumber = $OldMaterialNumber
			PurchasingValueKey= $PurchasingValueKey
			BasicDataText=$basicDataText
			PurchaseOrder=$purchaseOrderText
		}
		if($DocInfo){
			$basicDataProps = Add-DocInfoToBasicData -VaultEntity $VaultEntity -BasicDataProps $basicDataProps
		}
		$basicData = New-ERPObject -EntityType "BasicData" -Properties $basicDataProps

		if($MaterialType -eq 'ROH'){
			$basicData.PurchasingValueKey = 'FMD1'
			#MATERIAL CONTEXT ROH:
			$MaterialContextProps = New-ERPObject -EntityType "MaterialContext" -Properties @{
				Material=$material
				Plant=$plant
				ValuationArea=''
				ValuationType=''
				Description=$descriptions
				BasicData=$basicData
				PlantData=$plantData
			} 
		} else {
			#VALUATION DATA
			if($MaterialType -eq 'HIBE'){
				$ValuationClass = 'M402'
			} else {
				$ValuationClass = ''
			}
			$valuationData =@()
			$valutaionDataProps = @{
				Material=$material
				ValArea=$valArea
				ValType=''
				StdPrice='0.0000'
				PriceUnit='1'
				ValCategory=''
				PriceControl='V'
				MovingPrice='0.0000'
				ValClass= $ValuationClass
			}
			$valuationData = New-ERPObject -EntityType "ValuationData" -Properties $valutaionDataProps
			#MATERIAL CONTEXT rest of materialTypes:
			$MaterialContextProps = @{
				Material=$material
				Plant=$plant
				ValuationArea=$valArea
				ValuationType=''
				Description=$descriptions
				BasicData=$basicData
				ValuationData=$valuationData
				PlantData=$plantData}
		}
		$materialContext = New-ERPObject -EntityType "MaterialContext" -Properties $MaterialContextProps
		return $materialContext
	}
}








<# Update Material (BasicData)
    # Use REAL, CURRENT data (otherwise functional errors from SAP are returned)
$material = Get-ERPObject -EntitySet "MaterialContextCollection" -Keys @{Material=$number;Plant=$plant;ValuationArea=$valArea;ValuationType=''} -Expand @("BasicData")
$basicDataUpd = $material.BasicData
$update = Update-ERPObject -EntitySet "BasicDataCollection" -Keys @{Material=$basicDataUpd.Material} -Properties @{IndSector=$basicDataUpd.IndSector;MatlType=$basicDataUpd.MatlType;MatlGroup=$basicDataUpd.MatlGroup;BaseUom='ST';BaseUomIso='';PurchasingValueKey=$basicDataUpd.PurchasingValueKey}
#>