Import-Module PowerVault

$Endung=$file._Extension

if ($Endung -eq "idw")
{
$path=$file._FullPath
$deps = Get-VaultFileAssociations -File $path -Attachments

    foreach ($dep in $deps)
    
    {
    #Show-Inspector
    if($dep._Extension -eq "pdf")
    {
        if($dep._CategoryName -eq "Sonstige")
        {
         Update-VaultFile -File $dep._FullPath -LifecycleDefinition "Einfacher Freigabeprozess" -Status "veraltet" -Comment "Achtung ungueltig !"
        }
        else
        { #Else
        Update-VaultFile -File $dep._FullPath -LifecycleDefinition "HTTNebendokumente Workflow" -Status "veraltet" -Comment "Achtung ungueltig !"
        }
    }
    
    }


}