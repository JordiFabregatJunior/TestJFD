#Register-VaultEvent -EventName AddFile_Restrictions -Action 'RestrictAddFile'
 
function RestrictAddFile($file, $parentFolder, $dependencies, $attachments, $fileBom) {
    $filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file._Fullpath)
    $numberingSchemes = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
    if ($file._Extension -in @('xlsx','xls','doc','docx')){
        $DesiredNumScheme = "Office_Scheme"
        #Like: "OFFICE-doc(x)-001"
        $RegexOfficeScheme = [regex]"OFFICE\-[A-Z]{3,4}-\d{3}"
        $OfficeScheme = $numberingSchemes | where { $_.Name -eq $DesiredNumScheme} | select -First 1
        if($filenameWithoutExtension -match $RegexOfficeScheme){
            $message = "The file $($file.Name) can not be created since is not following the proper name/numbering scheme"
            Add-VaultRestriction -EntityName ($file.Name) -Message $message
        }
    }
}