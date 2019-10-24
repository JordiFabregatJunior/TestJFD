<# 
 $registryPath = 'HKCU:\Software\coolOrange s.r.l.\Unlock_ItemChange_Number'
 
 New-ItemProperty -Path $registryPath -Name $name -Value $value `


 $date = Get-Date -f yyMMdd_HHmmss


 Get-ChildItem -path 'HKCU:\Software\coolOrange s.r.l.'
 Get-ChildItem -path 'HKCU:\Software\coolOrange s.r.l.\Unlock_ItemChange_Number'

 #set-location -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\
Remove-Item –Path "HKCU:\Software\coolOrange s.r.l.\Unlock_ItemChange_Number"
New-Item –Path "HKCU:\Software\coolOrange s.r.l.\Unlock_ItemChange_Number"
$newReg = New-ItemProperty -Path "HKCU:\Software\coolOrange s.r.l.\Unlock_ItemChange_Number" -Name "TestProp" -Value $timeStamp -PropertyType "string"
Remove-Item –Path "HKCU:\Software\coolOrange s.r.l.\Unlock_ItemChange_Number"
$newTimeStamp = Get-Date -f yyMMdd_HHmmss
Set-Itemproperty -path $registryPath -Name 'TestProp' -value $newTimeStamp
 
New-Item –Path "HKCU:\Software\coolOrange s.r.l." –Name Unlock_ItemChange_Number

$regProp = 'Unlock_ItemChange_Number'
$timeStamp = Get-Date -f yyMMdd_HHmmss
$numberReg = Get-ChildItem -path 'HKCU:\Software\coolOrange s.r.l.' | where { $_.Name -like "*$($regProp)*" }
if($numberReg){
    $updatedReg = Set-Itemproperty -path $registryPath -Name 'TestProp' -value $timeStamp

} else {
    $newReg = New-ItemProperty -Path "HKCU:\Software\coolOrange s.r.l." -Name $regProp -Value $timeStamp -PropertyType "string"
}

'HKEY_CURRENT_USER\Software\coolOrange s.r.l.\Unlock_ItemChange_Number'
'Unlock_ItemChange_Number'
#>

function Resolve-ItemRelatedRegistryKeys {
	param(
		$ItemNumber,
		[ValidateSet('Set', 'Remove')]$OperationType
	)
	
	$registryKeyPath = 'HKCU:\Software\coolOrange s.r.l.'
	$numberReg = (Get-ItemProperty -path $registryKeyPath)
	$keyNames =  @('Unlock_ItemChange_Number','Unlock_ItemChange_Timestamp')

	foreach($regProp in $keyNames){
		switch($OperationType) 
		{
			'Set' 
			{
				if($regProp -eq 'Unlock_ItemChange_Timestamp'){
					$value =  Get-Date -f yyMMdd_HHmmss
				} else {
					$value = $ItemNumber
				}
		
				if($numberReg.PSObject.Properties[$regProp]){
					$reg = Set-Itemproperty -path $registryKeyPath -Name $regProp -value $value
				} else {
					$reg = New-ItemProperty -Path $registryKeyPath -Name $regProp -Value $value -PropertyType "string"
				}
			}
			'Remove'
			{
				if($numberReg.PSObject.Properties[$regProp]){
					$regPropFullPath = Join-Path $registryKeyPath $regProp
                    it will crash everything....
					$reg = Set-Itemproperty -path $registryKeyPath -Name $regProp -value ""
				}
			}
		}
	}
} 


function Test-Function {
    try{
        Resolve-ItemRelatedRegistryKeys -ItemNumber $itemNumber -OperationType 'Set'
        Resolve-ItemRelatedRegistryKeys -ItemNumber $itemNumber -OperationType 'Remove'
    } catch {
        Write-host "Item '$VaultEntity._Number' properties could not be updated in Vault. Error message:'$($_.Exception.Message)'"
    }
}

Test-Function