function Convert-ODataValueForFilter {
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Property,
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Value,
        [Parameter(Mandatory=$false)]$ErpEntityType
    )
    if($ErpEntityType) {
        $erpProperty = @($ErpEntityType.Properties + $ErpEntityType.Keys) | where { "$_" -eq $Property }
        if($erpProperty.Type -eq [string]) {
            $Value = "'$Value'"
        }
    } else {
        $Value = "'$Value'"
    }
    return $Value
}

function New-ODataFilterOperation {
        param(
            [Parameter(Mandatory=$true)][ValidateSet("substringof", "endswith", "startswith")]$Operation,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Property,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Value,
            [switch]$CaseSensitive = $false,
            [Parameter(Mandatory=$false)]$ErpEntityType
        )
    $Value = Convert-ODataValueForFilter -Property $Property -Value $Value -ErpEntityType $ErpEntityType
    if($CaseSensitive) {
        return "$Operation($Property, $Value) eq true"
    }
    return "$Operation(tolower($Property), $($Value.ToLower())) eq true"
}

function New-ODataFilter {
        param(
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$WildcardValue,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Property,
            [switch]$CaseSensitive = $false,
            [Parameter(Mandatory=$false)]$ErpEntityType
        )
	$odataFilter = $null

    if ($WildcardValue.Contains("*")) {
        $wildcardSplitted = $WildcardValue -split "\*"
		$startWithValue = ($wildcardSplitted | select -First 1)
		if(-not [string]::IsNullOrEmpty($startWithValue)) {
            $odataFilter = New-ODataFilterOperation -Operation startswith -Value $startWithValue -Property $Property -CaseSensitive:$CaseSensitive -ErpEntityType $ErpEntityType
		}
		$endsWithValue = ($wildcardSplitted | select -Last 1)
		if(-not [string]::IsNullOrEmpty($endsWithValue)) {
			if($odataFilter -ne $null) {
				$odataFilter += " and "
            }
            $odataFilter += New-ODataFilterOperation -Operation endswith -Value $endsWithValue -Property $Property -CaseSensitive:$CaseSensitive -ErpEntityType $ErpEntityType
		}
        
        # Generates all 'substringof' for every segment except first and last one
        $wildcardSplitted | select -First ($wildcardSplitted.Length-2) -Skip 1 | foreach {
            if($odataFilter -ne $null) {
                $odataFilter += " and "
            }
            $odataFilter += New-ODataFilterOperation -Operation substringof -Value $_ -Property $Property -CaseSensitive:$CaseSensitive -ErpEntityType $ErpEntityType
        }
    } else {    
        $WildcardValue = Convert-ODataValueForFilter -Property $Property -Value $WildcardValue -ErpEntityType $ErpEntityType
        if(-not $CaseSensitive) {
            $WildcardValue = $WildcardValue.ToLower()
            $Property = "tolower($Property)"
        }
        $odataFilter ="$WildcardValue eq $Property"
    }
    $odataFilter
}

function New-ErpWildcardFilter{
        param(
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$WildcardValue,
            [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Property
        )    
	$odataFilter = $null
	$wildcardSplitted = $WildcardValue -split "\*"
    if ($wildcardSplitted.Length -eq 1 -and -not[string]::IsNullOrEmpty($wildcardSplitted) -and -not($wildcardSplitted -eq '*')){
        $odataFilter ="substringof('$($WildcardValue.ToLower())', tolower($Property)) eq true"
    } elseif($wildcardSplitted.Length -eq 3 -and $WildcardValue.EndsWith("*") -and $WildcardValue.StartsWith("*"))  {
        $odataFilter ="substringof('$($WildcardValue.ToLower())', tolower($Property)) eq true"
    } elseif($WildcardValue.StartsWith("*") -and $wildcardSplitted.Length -eq 2) {
        $odataFilter = "endswith(tolower($Property), '$($WildcardValue.ToLower())') eq true"
    } elseif ($WildcardValue.EndsWith("*") -and $wildcardSplitted.Length -eq 2) {
        $odataFilter ="startswith(tolower($Property), '$($WildcardValue.ToLower())') eq true"
    } elseif ($WildcardValue.Contains("*")) {
		
		$startWithValue = ($wildcardSplitted | select -First 1)
		if(-not [string]::IsNullOrEmpty($startWithValue)) {
			$odataFilter = "startswith(tolower($Property), '$($startWithValue.ToLower())') eq true"
		}
		$endsWithValue = ($wildcardSplitted | select -Last 1)
		if(-not [string]::IsNullOrEmpty($endsWithValue)) {
			if($odataFilter -ne $null) {
				$odataFilter += " and "
			} 
			$odataFilter += "endswith(tolower($Property), '$($endsWithValue.ToLower())') eq true"
		}
        if($wildcardSplitted.Length -ge 3) {
            $wildcardSplitted | select -First ($wildcardSplitted.Length-2) -Skip 1 | foreach {
				if($odataFilter -ne $null) {
					$odataFilter += " and "
				}
                $odataFilter += "substringof('$($_.ToLower())', tolower($Property)) eq true"
            }
        }
    } else {
        $odataFilter ="$($WildcardValue.ToLower()) eq tolower($Property))"
    }
    $odataFilter -replace "\*", ""
}

Export-ModuleMember -Function "New-ODataFilter"
Export-ModuleMember -Function "New-ErpWildcardFilter"