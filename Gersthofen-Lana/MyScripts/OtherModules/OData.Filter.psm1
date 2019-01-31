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

Export-ModuleMember -Function "New-ODataFilter"