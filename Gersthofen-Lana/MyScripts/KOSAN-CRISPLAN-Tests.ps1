#To access in real machine
import-Module PowerGate
import-Module PowerVault
$partnumber = 138764
$IfsPart = Get-ERPObject -EntitySet "Parts" -Key @{ partNumber=$partNumber } -Expand @('documentLinks')
$IfsPart.documentlinks
function IfsConnect
{
	Disconnect-ERP
	<#$jobVault = GetJobVault
	if($jobVault -eq "KC-Vault") { 
		$ifsServer = "http://w7-coolorajob:8080/coolOrange/IFS"
	}
	else { 
		$ifsServer = "http://w7-adesk2016:8080/coolOrange/IFS" 
	}#>
    $ifsServer = "http://w7-adesk2016:8080/coolOrange/IFS" 
	Write-host "Connecting to IFS '$ifsServer'"
	Connect-ERP -Service $ifsServer -OnConnect {
	param($settings)
		$settings.AfterResponse = [System.Delegate]::Combine([Action[System.Net.Http.HttpResponseMessage]] {
		param($response)
			$global:powerGate_lastResponse = New-Object PSObject @{
				'RequestUri'=$response.RequestMessage.RequestUri
				'Code'=[int]$response.StatusCode
				'Status'=$response.StatusCode.ToString()
				'Protocol'= 'HTTP/'+$response.Version
				'Headers'= @{}
				'Body' = $null
			} 
			$response.Headers | foreach { $powerGate_lastResponse.Headers[$_.Key] = $_.Value }
			if($response.Content -ne $null) {
				$body = $response.Content.ReadAsStringAsync().Result
				try {
					$powerGate_lastResponse.Body = $body | ConvertFrom-Json
				} catch {
					$powerGate_lastResponse.Body = [xml]$body
				}
				$response.Content.Headers  | foreach { $powerGate_lastResponse.Headers[$_.Key] = $_.Value }
			}
		}, $settings.AfterResponse)
	} 
}
