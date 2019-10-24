# [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12  
Import-Module powerGate
Import-Module "$($env:ProgramFiles)\coolorange\Modules\powerGate\connections_sap.psm1"

$user = 'COO'
$password = 'Cool0range#'
$gatewayURL = "http://sapdberdgw01.yardsresdomde.com:8000"

$plant = '4500'
$valArea = '4500'

Disconnect-ERP
Connect-ERP -Service "$gatewayURL/sap/opu/odata/arcona6/material_srv/"  -User $user -Password $password -OnConnect $global:extendedSapConnect
Connect-ERP -Service "$gatewayURL/sap/opu/odata/arcona6/BILL_OF_MATERIAL_SRV/" -User $user -Password $password -OnConnect $global:extendedSapConnect
Connect-ERP -Service "$gatewayURL/sap/opu/odata/arcona6/DOCUMENT_INFO_RECORD_SRV/" -User $user -Password $password -OnConnect $global:extendedSapConnect
#$global:extendedSapConnect
#$global:connected

#read
$number = '99010'
$material = Get-ERPObject -EntitySet "MaterialContextCollection" -Keys @{Material=$number;Plant=$plant;ValuationArea=$valArea;ValuationType=''} -Expand @("Description","PlantData","BasicData","ValuationData")

    #search - $expand darf angewendet werden
$runtime = Measure-Command {
    $materials = Get-ERPObjects -EntitySet "MaterialContextCollection" -Top 30 -Expand @("Description")
}
$erpMaterials = Get-ERPObjects -EntitySet "MaterialContextCollection" -Filter "substringof(Material, '990') eq true"
# $materials = Get-ERPObjects -EntitySet "MaterialContextCollection" -Top 20 -Filter "endswith(Material, '10') eq true" -> prüfen
$material = Get-ERPObjects -EntitySet "MaterialContextCollection" -Top 3 -Filter "substringof(Material, '990') eq true" #=> ! FEHLER, Prüfen
$material.Count

#Create
# *** EVERY TIME USE NEW MATERIAL NUMBER!!! ***
$number = '99100'
$plant = '4500'
$valArea = '4500'
$materialType = 'ERSA'
$descriptions =@()
$descriptions += New-ERPObject -EntityType "material_srv.Description" -Properties @{Material=$number;Langu='D';MatlDesc='test coolOrange DE' }
$descriptions += New-ERPObject -EntityType "material_srv.Description" -Properties @{Material=$number;Langu='E';MatlDesc='test coolOrange EN' }
$basicData = New-ERPObject -EntityType "BasicData" -Properties @{Material=$number;BaseUom='ST';BaseUomIso='';IndSector='A';MatlGroup='PRODUNEED';MatlType=$materialType;PurchasingValueKey='FMD1'}
$plantData = New-ERPObject -EntityType "PlantData" -Properties @{Material=$number;Plant = $plant;Availcheck='02';PurGroup='';PurStatus='';Pvalidfrom=''}
$valuationData =@()
$valuationData = New-ERPObject -EntityType "ValuationData" -Properties @{Material=$number;ValArea=$valArea;ValType='';StdPrice='0.0000';PriceUnit='1';ValCategory='';PriceControl='V';MovingPrice='0.0000';ValClass='M404'}
$properties = New-ERPObject -EntityType "MaterialContext" -Properties @{Material=$number;Plant=$plant;ValuationArea=$valArea;ValuationType='';Description=$descriptions;BasicData=$basicData;ValuationData=$valuationData;PlantData=$plantData}
$material = Add-ERPObject -EntitySet "MATERIAL_SRV/MaterialContextCollection" -Properties $properties

# Update Material (BasicData)
    # Use REAL, CURRENT data (otherwise functional errors from SAP are returned)
$material = Get-ERPObject -EntitySet "MaterialContextCollection" -Keys @{Material=$number;Plant=$plant;ValuationArea=$valArea;ValuationType=''} -Expand @("BasicData")
$basicDataUpd = $material.BasicData
$update = Update-ERPObject -EntitySet "BasicDataCollection" -Keys @{Material=$basicDataUpd.Material} -Properties @{IndSector=$basicDataUpd.IndSector;MatlType=$basicDataUpd.MatlType;MatlGroup=$basicDataUpd.MatlGroup;BaseUom='ST';BaseUomIso='';PurchasingValueKey=$basicDataUpd.PurchasingValueKey}

# The following operation returns HTTP 200 OK but never delivers anything (this is by design so)
$BOMs = Get-ERPObjects -EntitySet "BOMContextCollection" -Top 3

#read BOM - OK
$number = '99092'
$BOM = Get-ERPObject -EntitySet "BOMContextCollection" -Keys @{Material=$number;Plant=$plant;BOMUsage='1';Alternative='1'} -Expand @("BOMItemData","BOMHeaderData")
# Zahlen - Formatierung beachten, Leerzeichen entfernen

#create BOM - OK
#*** EVERY TIME USE NEW BOM NUMBER!!! ***
$number = "99100"# Formatierung, MaterialNr richtig formatieren
$plant = "4500"
$bomUsage = '1'
$alternative = '1'
$bomHeader = New-ERPObject -EntityType "BillOfMaterialHeaderData" -Properties @{Material=$number;Plant=$plant;BOMUsage=$bomUsage;Alternative=$alternative;HeaderGUID='';BOMStatus='01';BaseQuan='1';BaseUnit='ST';Laboratory=''}
$bomItems = @()
$childNumber = '99094'
$bomItems += New-ERPObject -EntityType "BillOfMaterialItemData" -Properties @{Material=$number;Plant=$plant;BOMUsage=$bomUsage;Alternative=$alternative;ItemCat='L';Component=$childNumber;ComponentQty='3';ComponentUnit='ST';ItemNo='0011';ItemGUID='';ItemID='';MaterialGroup=""}
$childNumber = '99097'
$bomItems += New-ERPObject -EntityType "BillOfMaterialItemData" -Properties @{Material=$number;Plant=$plant;BOMUsage=$bomUsage;Alternative=$alternative;ItemCat='L';Component=$childNumber;ComponentQty='3';ComponentUnit='ST';ItemNo='0012';ItemGUID='';ItemID='';MaterialGroup=""}
$properties = New-ERPObject -EntityType "BillOfMaterialContext" -Properties @{Material=$number;Plant=$plant;BOMUsage=$bomUsage;Alternative=$alternative;BOMItemData=$bomItems;BOMHeaderData=$bomHeader}
$BOM = Add-ERPObject -EntitySet "BOMContextCollection" -Properties $properties


# create BOM Item
$number = "99100"# Formatierung, MaterialNr richtig formatieren
$BOM = Get-ERPObject -EntitySet "BOMContextCollection" -Keys @{Material=$number;Plant=$plant;BOMUsage='1';Alternative='1'} -Expand @("BOMItemData")
$BOMItemDefaults = $BOM.BOMItemData[0]
$properties = New-ERPObject -EntityType "BillOfMaterialItemData" -Properties @{Material=$number;Plant=$BOMItemDefaults.Plant;BOMUsage=$BOMItemDefaults.BOMUsage;Alternative=$BOMItemDefaults.Alternative;ItemCat=$BOMItemDefaults.ItemCat;Component=$BOMItemDefaults.Component;ComponentQty=$BOMItemDefaults.ComponentQty + 3;ComponentUnit=$BOMItemDefaults.ComponentUnit;ItemNo='';ItemGUID='';ItemID='';MaterialGroup=""}
#Original one: $properties = New-ERPObject -EntityType "BillOfMaterialItemData" -Properties @{Material=$BOMItemDefaults.Material;Plant=$BOMItemDefaults.Plant;BOMUsage=$BOMItemDefaults.BOMUsage;Alternative=$BOMItemDefaults.Alternative;ItemCat=$BOMItemDefaults.ItemCat;Component=$BOMItemDefaults.Component;ComponentQty=$BOMItemDefaults.ComponentQty + 3;ComponentUnit=$BOMItemDefaults.ComponentUnit;ItemNo='';ItemGUID='';ItemID='';MaterialGroup=""}
$BOMItem = Add-ERPObject -EntitySet "BOMItemDataCollection" -Properties $properties

#update BOM Item
$number = "99100"# Formatierung, MaterialNr richtig formatieren
$BOM = Get-ERPObject -EntitySet "BOMContextCollection" -Keys @{Material=$number;Plant=$plant;BOMUsage='1';Alternative='1'} -Expand @("BOMItemData")
$BOMItemUpd = $BOM.BOMItemData[1]
$update = Update-ERPObject -EntitySet "BOMItemDataCollection" -Keys @{ItemGUID=$BOMItemUpd.ItemGUID;Plant=$BOMItemUpd.Plant;BOMUsage=$BOMItemUpd.BOMUsage;Material=$BOMItemUpd.Material;Alternative=$BOMItemUpd.Alternative} -Properties @{ItemCat=$BOMItemUpd.ItemCat;Component=$BOMItemUpd.Component;ComponentQty='10';ComponentUnit=$BOMItemUpd.ComponentUnit;ItemNo='0014';ItemID=$BOMItemUpd.ItemID;MaterialGroup=$BOMItemUpd.MaterialGroup}

#delete BOM Item
$number = "99100"
$BOM = Get-ERPObject -EntitySet "BOMContextCollection" -Keys @{Material=$number;Plant=$plant;BOMUsage='1';Alternative='1'} -Expand @("BOMItemData")
$BOMItemDel = $BOM.BOMItemData[0]
$delete = Remove-ERPObject -EntitySet "BOMItemDataCollection" -Keys @{ItemGUID=$BOMItemDel.ItemGUID;Plant=$BOMItemDel.Plant;BOMUsage=$BOMItemDel.BOMUsage;Material=$BOMItemDel.Material;Alternative=$BOMItemDel.Alternative}

#read DIR - OK
$number = '30000000'
$revision = '00'
$documentPart = '000'
$documentType = 'ZBP'
$dir = Get-ERPObject -EntitySet "DocumentInfoRecordContextCollection" -Keys @{Documentnumber=$number;Documentversion=$revision;Documenttype=$documentType;Documentpart=$documentPart} -Expand @("DocumentInfoRecordDescription","DocumentInfoRecordData","DocumentInfoRecordObjectLinks") #"DocumentInfoRecordOriginals"

#create DIR - OK
$number = ''
$revision = '00'
$documentPart = '000'
$documentType = 'ZBP'
$poPos = '450000000100010'
$descriptions = @()
$descriptions += New-ERPObject -EntityType "DocumentInfoRecordDescription" -Properties @{Documentnumber=$number;Documentversion=$revision;Documenttype=$documentType;Documentpart=$documentPart;Langu='D';Description="test DE"}
$descriptions += New-ERPObject -EntityType "DocumentInfoRecordDescription" -Properties @{Documentnumber=$number;Documentversion=$revision;Documenttype=$documentType;Documentpart=$documentPart;Langu='E';Description="test EN"}
$links = @()
$links += New-ERPObject -EntityType "DocumentInfoRecordObjectLink" -Properties @{Documentnumber=$number;Documentversion=$revision;Documenttype=$documentType;Documentpart=$documentPart;ObjectKey=$poPos;ObjectType='EKPO'}
$DocInfoRecordData = New-ERPObject -EntityType "DOCUMENT_INFO_RECORD_SRV.DocumentInfoRecordData" -Properties @{Documentnumber=$number;Documentversion=$revision;Documenttype=$documentType;Documentpart=$documentPart;Description="test 123";StatusIntern='{0'}
$properties = New-ERPObject -EntityType "DocumentInfoRecordContext" -Properties @{Documentnumber=$number;Documentversion=$revision;Documenttype=$documentType;Documentpart=$documentPart;DocumentInfoRecordData=$DocInfoRecordData;DocumentInfoRecordDescription=$descriptions;DocumentInfoRecordObjectLinks=$links}
$dir = Add-ERPObject -EntitySet "DocumentInfoRecordContextCollection" -Properties $properties

#update DIR
$number = '30000004'
$dir = Get-ERPObject -EntitySet "DocumentInfoRecordContextCollection" -Keys @{Documentnumber=$number;Documentversion=$revision;Documenttype=$documentType;Documentpart=$documentPart} -Expand @("DocumentInfoRecordDescription","DocumentInfoRecordData","DocumentInfoRecordObjectLinks") #"DocumentInfoRecordOriginals"
$dirData = $dir.DocumentInfoRecordData
$update = Update-ERPObject -EntitySet "DOCUMENT_INFO_RECORD_SRV/DocumentInfoRecordDataCollection" -Keys @{Documenttype=$dirData.Documenttype;Documentnumber=$dirData.Documentnumber;Documentversion=$dirData.Documentversion;Documentpart=$dirData.Documentpart} -Properties @{Description='test 33';StatusIntern=$dirData.StatusIntern}

#upload file
#! Remeber to put a valid PDF in the path denoted as -File down below!
$newfile = Add-ERPMedia -EntitySet "DocumentInfoRecordOriginalCollection" -File "C:\temp\test.pdf" -ContentType "application/pdf" -Properties @{Documentversion=$revision;Documenttype=$documentType;Documentpart=$documentPart;Documentnumber=$number}

#update file
$dir = Get-ERPObject -EntitySet "DocumentInfoRecordContextCollection" -Keys @{Documentnumber=$number;Documentversion=$revision;Documenttype=$documentType;Documentpart=$documentPart} -Expand @("DocumentInfoRecordOriginals")
$original = $dir.DocumentInfoRecordOriginals[0]
$pdf2 = Update-ERPMedia -EntitySet "DocumentInfoRecordOriginalCollection" -File "c:\temp\test2.pdf" -Keys @{Documentnumber=$original.Documentnumber;Documentversion=$original.Documentversion;Documenttype=$original.Documenttype;Documentpart=$original.Documentpart;Description=$original.Description}
