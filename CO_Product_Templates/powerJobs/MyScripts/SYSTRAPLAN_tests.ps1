####______WorkingProperlyVersion_____###
function New-ErpWildcardFilter($WildcardValue, $Property) {
    
    <#if(-not($WildcardValue.EndsWith('*'))){
        $WildcardValue += '*'
    }#>

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
###__________OtherScripts______###

Import-Module PowerVault
#Connect-Erp -Service "http://srv-vault-01:8080/coolorange/Cobus"

$itemForReadOperationEntitySet = "ItemRead"
$itemForReadOperationEntity = (Get-ERPEntitySets) | where { $_.Name -eq $itemForReadOperationEntitySet}


#$WildcardValue = $dsWindow.FindName("ArtikelBez").Text
$WildcardValue = "*K-G*00*"
$Property = "Artikel"
$wildcardQuery = New-ErpWildcardFilter -WildcardValue $WildcardValue -Property $Property
$results = Get-ErpObjects -EntitySet $itemForReadOperationEntity.Name -Filter $wildcardQuery
$hashResults = @{}
foreach ($result in $results){
    $hashResults[$result.Artikel] = $result.Kurztext
}
$hashResults | Format-Table


<#$kurztext = "Fl 10x8 St37-2*"
$KTXTFilter="substringof('$($kurztext.ToLower())',tolower(Kurztext)) eq true"
$artikelsContainSpecifcText = Get-ErpObjects -EntitySet $itemForReadOperationEntity.Name -Filter $KTXTFilter#>

function New-ErpWildcardFilter($WildcardValue, $Property) {
    
    if(-not($WildcardValue.EndsWith('*'))){
        $WildcardValue += '*'
    }
	$odataFilter = $null
	$wildcardSplitted = $WildcardValue -split "\*"

    if($wildcardSplitted.Length -eq 3 -and $WildcardValue.EndsWith("*") -and $WildcardValue.StartsWith("*"))  {
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