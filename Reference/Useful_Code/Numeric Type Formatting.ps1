function Get-AdaptedSTRINGDimension($Value, $NumberOfDecimalsForRounding=1){
    if([string]::IsNullOrEmpty($Value)){ 
        return $Value
    } else {
        $standardStringForDecimal = ([string]$Value).Replace(',','.')
        $roundedDecimal = [math]::round([decimal]($standardStringForDecimal),$NumberOfDecimalsForRounding)
        $toStringWithDesiredStructure = $roundedDecimal.ToString("#.#")
        if($toStringWithDesiredStructure -notlike '*,*'){ #For $value like integer or string without decimals
             $toStringWithDesiredStructure += ",0"
        }
        return $toStringWithDesiredStructure
    }
}

function Get-AdaptedDECIMALDimension($Value, $NumberOfDecimalsForRounding=1){
    if([string]::IsNullOrEmpty($Value)){ 
        return $Value
    } else {
        $standardStringForDecimal = ([string]$Value).Replace(',','.')
        $roundedDecimal = [math]::round([decimal]($standardStringForDecimal),$NumberOfDecimalsForRounding)
    }
}

#STRING Tests
foreach($value in @(26.100, 24.1, '24,1', '25,200')){
    $adaptedValue = Get-AdaptedSTRINGDimension -Value $Value
    Write-host $adaptedValue
}

#DECIMAL Tests
foreach($value in @(26.100, 24.1, '24,1', '25,200')){
    $adaptedValue = Get-AdaptedDECIMALDimension -Value $Value
    Write-host $adaptedValue
}