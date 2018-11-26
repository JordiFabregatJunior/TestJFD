$Properties = $Properties | sort IsNestedXmlTag,@{ expression= {
    if ($_.Value -and $_.Value.GetType().IsArray) {
        $IsNestedXmlTag=”1” 
    } else {
        $IsNestedXmlTag=”0” 
    }
    add-member noteproperty “IsNestedXmlTag” $IsNestedXmlTag -InputObject $_
} }



$Properties = @{
	"0" = @{"Property_Name" = "numero_de_piece"; "Property_Value" = "6131"}
	"4" = @{"Property_Name" = "compression_lat"; "Property_Value" = "Shortcut"}
	"1" = @{"Property_Name" = "revision"; "Property_Value" = "SX"}
	"2" = @{"Property_Name" = "description"; "Property_Value" = "Parlo"}
	"3" = @{"Property_Name" = "sens"; "Property_Value" = "Zenza"}
    "Engineering" = @(
					@{"Property_Name" = 11; "Property_Value" = "PRC-9009.idw 999SX"}
					@{"Property_Name" = 12; "Property_Value" = "PRC-1001.ipt 999SX"}
					@{"Property_Name" = 13; "Property_Value" = "Other Dependency.ipt 999SX"}
					@{"Property_Name" = 14; "Property_Value" = "Other Dependency2.png 999SX"}
				    )
    }

$Properties.GetEnumerator() | sort -Property Name | foreach {
    Write-Host "Key (position): $($_.Key) and value (PropertyValue): $($_.Value["Property_Value"])"
    }

PS C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU> $Properties.GetEnumerator() | sort -Property Name | foreach {
Write-Host "Key (position): $($_.Key) and value (PropertyValue): $($_.Value["Property_Value"])"
}
Key (position): 0 and value (PropertyValue): 6131
Key (position): 1 and value (PropertyValue): SX
Key (position): 2 and value (PropertyValue): Parlo
Key (position): 3 and value (PropertyValue): Zenza
Key (position): 4 and value (PropertyValue): Shortcut
Key (position): Engineering and value (PropertyValue): 


$Properties = @{
	"0" = @{"Property_Name" = "numero_de_piece"; "Property_Value" = "6131"}
	"4" = @{"Property_Name" = "compression_lat"; "Property_Value" = "Shortcut"}
	"1" = @{"Property_Name" = "revision"; "Property_Value" = "SX"}
	"2" = @{"Property_Name" = "description"; "Property_Value" = "Parlo"}
	"3" = @{"Property_Name" = "sens"; "Property_Value" = "Zenza"}
    "Engineering" = @(
					@{"Property_Name" = 11; "Property_Value" = "PRC-9009.idw 999SX"}
					@{"Property_Name" = 12; "Property_Value" = "PRC-1001.ipt 999SX"}
					@{"Property_Name" = 13; "Property_Value" = "Other Dependency.ipt 999SX"}
					@{"Property_Name" = 14; "Property_Value" = "Other Dependency2.png 999SX"}
				    )
    }

$Properties.GetEnumerator() | sort -Property Name | foreach {
    Write-Host "Key (position): $($_.Key) (with key.type: $($_.Key.GetType()) and value (PropertyValue): $($_.Value["Property_Value"])"
    }

PS C:\Users\JordiFabregatJunior.DESKTOP-1T6O2OU> $Properties.GetEnumerator() | sort -Property Name | foreach {
Write-Host "Key (position): $($_.Key) and value (PropertyValue): $($_.Value["Property_Value"])"
}
Key (position): 0 and value (PropertyValue): 6131
Key (position): 1 and value (PropertyValue): SX
Key (position): 2 and value (PropertyValue): Parlo
Key (position): 3 and value (PropertyValue): Zenza
Key (position): 4 and value (PropertyValue): Shortcut
Key (position): Engineering and value (PropertyValue): 


###___PesterTests
					"1" = @{"Property_Name" = "numero_de_piece"; "Property_Value" = "6131"}
					"2" = @{"Property_Name" = "revision"; "Property_Value" = "SX"}
					"3" = @{"Property_Name" = "description"; "Property_Value" = "Parlo"}
					"4" = @{"Property_Name" = "sens"; "Property_Value" = "Zenza"}
					"5" = @{"Property_Name" = "compression_lat"; "Property_Value" = "Shortcut"}
					"6" = @{"Property_Name" = "penetration"; "Property_Value" = "specialz"}
					"7" = @{"Property_Name" = "profondeur_matrix"; "Property_Value" = "matrix"}
					"8" = @{"Property_Name" = "cote_client_min"; "Property_Value" = "cotepièce"}
					"9" = @{"Property_Name" = "conge"; "Property_Value" = "jaw`´ol"}
					"10" = @{"Property_Name" = "part_number_revision"; "Property_Value" = "6131SX"}
					"11" = @{"Property_Name" = "pdf_file_name"; "Property_Value" = "STA_6131SX.pdf"}
					
					"numero_de_piece" = @{"Position" = 0; "Property_Value" = "6131"}
					"revision" = @{"Position" = 1; "Property_Value" = "SX"}
					"description" = @{"Position" = 2; "Property_Value" = "Parlo"}
					"sens" = @{"Position" = 3; "Property_Value" = "Zenza"}
					"compression_lat" = @{"Position" = 4; "Property_Value" = "Shortcut"}
					"penetration" = @{"Position" = 5; "Property_Value" = "specialz"}
					"profondeur_matrix" = @{"Position" = 6; "Property_Value" = "matrix"}
					"cote_client_min" = @{"Position" = 7; "Property_Value" = "cotepièce"}
					"conge" = @{"Position" = 8; "Property_Value" = "jaw`´ol"}
					"part_number_revision" = @{"Position" = 9; "Property_Value" = "6131SX"}
					"pdf_file_name" = @{"Position" = 10; "Property_Value" = "STA_6131SX.pdf"}
					
					
					
					
					
					
					$Properties = $Properties.GetEnumerator() | sort IsNestedXmlTag,@{ expression= {
    if ($_.Value -and $_.Value.GetType().IsArray) {
        $IsNestedXmlTag=”0” 
    } else {
        $IsNestedXmlTag=”1” 
    }
    add-member noteproperty “IsNestedXmlTag” $IsNestedXmlTag -InputObject $_
} } -Descending

$a = @{"numero_de_piece" = "6131"}
$b = @{"revision" = "SX"}
$d = @{"description" = "Parlo"}
$c = @{"Profils_Standards" = @(
		"PRC-9009.idw 999SX"
		"PRC-1001.ipt 999SX"
		"Other Dependency.ipt 999SX"
		"Other Dependency2.png 999SX"
		)}

$a,$b,$c,$d | sort IsNestedXmlTag,@{ expression = {
        if ($_.Value -and $_.Value.GetType().IsArray) {
            $IsNestedXmlTag= 1  
        } else {
            $IsNestedXmlTag= 0  
        }
        add-member noteproperty “IsNestedXmlTag” $IsNestedXmlTag -InputObject $_
    }
}

$Properties = @{
	"numero_de_piece" = "6131"
	"revision" = "SX"
	"description" = "Parlo"
	"sens" = "Zenza"
    "Profils_Standards" = @(
		"PRC-9009.idw 999SX"
		"PRC-1001.ipt 999SX"
		"Other Dependency.ipt 999SX"
		"Other Dependency2.png 999SX"
		)
	"compression_lat" = "Shortcut"
	"penetration" = "specialz"
	"profondeur_matrix" = "matrix"
	"cote_client_min" = "cotepièce"
	"conge" = "jaw`´ol"
	"part_number_revision" = "6131SX"
	"pdf_file_name" = "STA_6131SX.pdf"
	}
