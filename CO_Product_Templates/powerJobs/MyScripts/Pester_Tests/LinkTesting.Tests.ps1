#cd "C:\ProgramData\coolOrange\powerJobs\MyScripts\Pester_Tests"
#Invoke-Pester -PassThru -TestName "Testing mocking" | Format-Pester -Path "C:\ProgramData\coolOrange\powerJobs\MyScripts\Pester_Tests" -Format "html"
$testsBaseDirectory = (Get-Item $PSCommandPath).Directory.Parent.Parent.FullName
Import-Module "C:\ProgramData\coolOrange\powerJobs\MyScripts\Pester_Tests\PesterTestModule.psm1"
Import-Module PesterTestModule
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
#. "$($env:POWERJOBS_JOBSDIR)\$jobName.ps1"
$jobName = "linktesting" 



function Add-Link($Number, $Folder){
    $pvItem = Get-VaultItem -Number $Number
    $linksOnFolder = $vault.DocumentService.GetLinksByParentIds($Folder.Id, "ITEM")
    [array]$vaultFilesIdsWithLinks= @()
    foreach ($link in $linksOnFolder){
	    $vaultFilesIdsWithLinks += $link.ToEntId
    }
    if ($pvItem.Id -notin $vaultFilesIdsWithLinks){
        $link = $vault.DocumentService.AddLink($Folder.Id,"ITEM",$pvItem.Id,"")
    }
    else {Add-log "Verknüpfung zum Artikel schon im Ordner $($folder.Name)"}
}
function Add-Numbers($a, $b) {
    return $a + $b
}

Describe "Testing Links" {
    Context "Testing Function" {      
        mock -CommandName "Link-Testing" -Verifiable
        . ".\$($jobName).ps1"

        It "Test returning parent id" {
            $sum = Link-Testing -Number "100002" -Folder $vault.DocumentService.GetFolderByPath("$/Designs/Inventor/Test-Related-IDW")
            $sum | Should Be 2392
        }
    }
}

Describe -Tag 'este' "Import job"{
    It "adds positive numbers" {
        $sum = Add-Numbers 2 3
        $sum | Should Be 5
    }

}

Describe "Testing mocking"{
    it "Mock test"{
        $package = New-Object Mock
        $expected = $package.OutputToOverwrite()
        $expected | should BeExactly "mystring"
    }
}