$pesterModule = Get-Module -ListAvailable | Where {$_.Name -like "*Pester*"}
$pesterMajorVersion = $pesterModule.Version.Major
$message = "Attention! Current version of Pester-Module is '$($pesterMajorVersion)'. There are some syntax errors which maybe will not allow the proper tests running. TESTS PREPARED FOR VERSION 3!!!`nMajor change: Version3 > Should Be `nMajor change: Version3 > Should -Be "
$title = "Pester Version Alert"
$button = [System.Windows.Forms.MessageBoxButtons]::OK
$icon = [System.Windows.Forms.MessageBoxIcon]$icon = [System.Windows.Forms.MessageBoxIcon]::Information
[System.Windows.Forms.MessageBox]::Show($message, $title, $button, $icon)