try
{
Import-Module WebAdministration
$LogFilePath = 'c:\temp\'
$flagCheck = 'false';
$PathYear = Get-Date -UFormat "%Y"
$PathMonth = Get-Date -UFormat "%m"
$PathDate = Get-Date -UFormat "%d"
$LogFilePath = $LogFilePath + $PathYear + $PathMonth + $PathDate + "_Monitoring.txt"
$pList = get-process
foreach($lp in $pList)
{
    if($lp.ProcessName -eq 'w3wp') 
    {
        $flagCheck = 'true';
    }
}
if($flagCheck -eq 'true')
{
$list = get-process w3wp
$lineitems = @()
   foreach($p in $list)
   {
                $linestr = New-Object PSObject                
                $filter = 'Handle=' + $p.Id + ''
                $wmip = get-WmiObject Win32_Process -filter $filter
                $PoolName = ''
                $cmdline = C:\Windows\System32\inetsrv\appcmd.exe list wp      
                foreach($appPoolName in $cmdline)
                {                    
                    $pos = $appPoolName.indexOf($p.Id.ToString())
                    if($pos -gt 0)
                    {                        
                        $appPoolNamePos = $appPoolName.indexOf(":")
                        $PoolNameWithB = $appPoolName.Substring($appPoolNamePos + 1)
                        $PoolName = $PoolNameWithB.Substring(0, $PoolNameWithB.Length - 1);
                    }
                }                                                    
                $VirtualMemorySize = $p.VM / (1024 * 1024)
                $PagedMemorySize = $p.PM / (1024 * 1024)
                $WorkingSetSize = $p.WS / (1024 * 1024)
                $VirtualMemorySize64 = $p.VirtualMemorySize64 / (1024 * 1024)
                $PagedMemorySize64 = $p.PagedMemorySize64 / (1024 * 1024)
                $WorkingSetSize64 = $p.WorkingSet64 / (1024 * 1024)
                $PoolNameComplete = "IIS:\AppPools\" + $PoolName
                $requestDetails = Get-Item $PoolNameComplete | Get-WebRequest
    $TimeNow = Get-Date
                $linestr | add-member NoteProperty "Date Time" $TimeNow
                $linestr | add-member NoteProperty "AppPoolName" $PoolName
                $linestr | add-member NoteProperty "Request Served" $requestDetails.url
                $linestr | add-member NoteProperty "Allocated Virtual Memory(MB)" $VirtualMemorySize
                $linestr | add-member NoteProperty "Allocated Virtual Memory 64(MB)" $VirtualMemorySize64
                $linestr | add-member NoteProperty "Allocated Paged Memory(MB)"  $PagedMemorySize
                $linestr | add-member NoteProperty "Allocated Paged Memory 64(MB)"  $PagedMemorySize64
                $linestr | add-member NoteProperty "Working Set(MB)"  $WorkingSetSize
                $linestr | add-member NoteProperty "Working Set 64(MB)"  $WorkingSetSize64
                $linestr | add-member NoteProperty "CPU Time(secs)"  $p.CPU                               
                $OSDetails = Get-WmiObject -Class win32_operatingsystem 
                $TotVirtMemory = $OSDetails.TotalVirtualMemorySize / 1024
                $FreeVirtMemory = $OSDetails.FreeVirtualMemory / 1024
                $TotVisMemory = $OSDetails.TotalVisibleMemorySize / 1024
                $FreeRAM = $OSDetails.FreePhysicalMemory / 1024
                $linestr | add-member NoteProperty "Total Virtual Memory(MB)" $TotVirtMemory
                $linestr | add-member NoteProperty "Free Virtual Memory(MB)" $FreeVirtMemory
                $linestr | add-member NoteProperty "Total Physical Memory(MB)" $TotVisMemory
                $linestr | add-member NoteProperty "Free Physical Memory(MB)" $FreeRAM
                $lineitems += $linestr                
   }
Add-Content $LogFilePath $lineitems | Format-Table * -AutoSize 
}
}
catch
{
  Add-Content $LogFilePath $PSItem.InvocationInfo | Format-List *
} 