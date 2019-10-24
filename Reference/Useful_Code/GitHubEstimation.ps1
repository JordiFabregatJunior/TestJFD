[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Base64Token = [System.Convert]::ToBase64String([char[]]$Token)
$Headers = @{Authorization= 'Basic {0}' -f $Base64Token
Accept = "application/vnd.github.symmetra-preview+json"
}
$repoName = "Conti-Machinery"
$allIssuesURI = "https://api.github.com/repos/coolOrangeProjects/"+$repoName+"/issues?per_page=5"
$allClosedIssuesURI = "https://api.github.com/repos/coolOrangeProjects/"+$repoName+"/issues?state=closed&per_page=500"
$allIssues = Invoke-RestMethod -Header $Headers -Uri $allIssuesURI -Body $body -Method Get
$allClosedIssues = Invoke-RestMethod -Header $Headers -Uri $allClosedIssuesURI -Body $body -Method Get

$destinationPath = 'C:\Temp\issuesEstimation.csv'
$csvContent = @()
foreach($issue in $allIssues){
    $issueNumber = [int]$issue.number
    $issueEstimation = $issue.labels[0].name
    $issueUrl = $issue.url
    $csvContent += [PSCustomObject]@{'Issue' = $issueNumber; 'Label' = $issueEstimation; 'URL' = $issueUrl }
}
foreach($issue in $allClosedIssues){
    $issueNumber = [int]($issue.number)
    $issueEstimation = $issue.labels[0].name
    $issueUrl = $issue.url
    $csvContent += [PSCustomObject]@{'Issue' = $issueNumber; 'Label' = $issueEstimation; 'URL' = $issueUrl }
}
$csvContent | Sort-Object -Property Issue -Descending | Export-Csv -Path $destinationPath -Delimiter ';' -NoTypeInformation -ErrorAction SilentlyContinue
explorer.exe $destinationPath