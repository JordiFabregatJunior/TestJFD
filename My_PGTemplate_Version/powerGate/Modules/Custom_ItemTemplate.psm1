$source = @"
public class MyKeyValue{
    public string Key { get; set; }
    public string Value { get; set; }
}
"@
Add-Type $source

function Show-MessageBox($message, $title = "powerGate ERP Integration", $icon = "Information") {
	#icons: Error, Exclamation, Hand, Information, Question, Stop, Warning
	$button = "OK"
	$null = [System.Windows.Forms.MessageBox]::Show($message, $title, $button, $icon)	
}

Function Format-XMLIndent
{
    [Cmdletbinding()]
    [Alias("IndentXML")]
    param
    (
        [xml]$Content,
        [int]$Indent
    )

    # String Writer and XML Writer objects to write XML to string
    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 

    # Default = None, change Formatting to Indented
    $xmlWriter.Formatting = "indented" 

    # Gets or sets how many IndentChars to write for each level in 
    # the hierarchy when Formatting is set to Formatting.Indented
    $xmlWriter.Indentation = $Indent
    
    $Content.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush();$StringWriter.Flush() 
    $StringWriter.ToString()
}

$global:ItemTemplateNameIsNotEditMode = $true
function ItemTemplateNameIsNotEditMode {
    return $global:ItemTemplateNameIsNotEditMode
}
function DeleteItemTemplate ($node) {
    Log -Message ">>> $($MyInvocation.MyCommand.Name) >>"
    if (-not $node){
        $node = $dsWindow.FindName("ItemTemplateList").selectedItem
    }
    $XMLSourcePath = 'C:\Temp\PGT_ItemTemplates.xml'
    Log -Message "> Deleting '$($node.Key)' from Item templates (see $XMLSourcePath)"
    [xml]$xml = Get-Content -Path $XMLSourcePath

    Log -Message ">Existing ItemTemplate Keys: '$($nodes.Entry.Key -Join "','")'"
    $item = $xml.ItemTemplateNumbers.ChildNodes | where {$_.Key -eq $node.Key}
    if($item){
        $item.ParentNode.RemoveChild($item)
        Log -Message ">Removed ItemTemplate: '$($item.Key)'"
    }

    (Format-XMLIndent -Content $xml -Indent 3) | Out-File $XMLSourcePath -Force | Out-Null
    $updatedItemList = @(GetItemTemplateList)
    Log -Message "> $myCommand Updated ItemTemplate Keys available: '$($updatedItemList.Key -Join "','")'"
    $dsWindow.FindName("ItemTemplateList").ItemsSource = $updatedItemList
}

function GetItemTemplateList {
    $XMLSourcePath = 'C:\Temp\PGT_ItemTemplates.xml'
    [xml]$xml = Get-Content -Path $XMLSourcePath
    $entries = Select-Xml -Xml $xml -XPath "//ItemTemplateNumbers" 
    $list = @()
    foreach ($entry in $entries.Node.ChildNodes) { 
        if ($entry.NodeType -eq "Comment") { continue }
        $list += New-Object MyKeyValue -Property @{Key = $entry.Key; Value = $entry.Value } 
    }
    return $list | Sort-Object -Property value   
}

function ExistItemTemplates {
    $list = GetItemTemplateList
    #Log -Message "$($list)"
    return (@($list).count -gt 0)
}

function UseItemTemplate {
    Log -Message ">>> $($MyInvocation.MyCommand.Name) >>"
    $selectedItemTemplate = $dsWindow.FindName("ItemTemplateList").selectedItem
    if($selectedItemTemplate){
        $number = $selectedItemTemplate.Key
        Log -message "Selected item with number-key: $($number)"
        $customMaterial = GetErpMaterial -Number $number
        if($customMaterial){
            Log -message "Found template erp material for number-key: $($number)"
            $materialFed = $dswindow.FindName("DataGrid").DataContext
            if($materialFed.IsCreate){
                Log -message "Fed erp material for Number $($materialFed.Number) - status: 'IsCreate'"
                $entity = GetSelectedObject
                $vaultNumber = GetEntityNumber -entity $entity       
                $customMaterial.Number =$vaultNumber
                $customMaterial.IsCreate =$true
                $customMaterial.IsUpdate =$false  
                $dswindow.FindName("DataGrid").DataContext = $customMaterial                   
            } elseif($materialFed.IsUpdate) {
                Log -message "Fed erp material for Number $($materialFed.Number) - status: 'IsUpdate'"
                $materialFed.Description = $customMaterial.Description
                $materialFed.Dimensions = $customMaterial.Dimensions
                $materialFed.Weight = $customMaterial.Weight
                $materialFed.Shelf = $customMaterial.Shelf
                $dswindow.FindName("DataGrid").DataContext = $materialFed
            }       
        } else {
            Log -message "NOT found erp material for number-key: $($number)"
            Show-MessageBox -message "Se esta intentando utilizar la plantilla '$($selectedItemTemplate.Value)', pero su articulo asociado ya no existe en el ERP (parametro clave ERP: '$($selectedItemTemplate.Key)'). Asegurese de escoger una plantilla valida. Se procede a borrar plantilla '$($selectedItemTemplate.Value)'." -icon "Error"
            DeleteItemTemplate -Node $selectedItemTemplate
        }
    }
}

function EditItemTemplate {

    Log -Message ">>> $($MyInvocation.MyCommand.Name) >>"

    $global:ItemTemplateNameIsNotEditMode = $false
    $dsWindow.FindName("ItemTemplateNameGrid").Visibility = "Visible"
    
    $selectedItem = $dsWindow.FindName("ItemTemplateList").selectedItem
    Log -Message "> selectedItem: $($selectedItem)-- SelectedValue: $($selectedItem.Value)"
    if($selectedItem){
        $dsWindow.FindName("TxtBxNewItemTemplateName").Text = $selectedItem.Value
    }

}
function SaveItemTemplateName {

    Log -Message ">>> $($MyInvocation.MyCommand.Name) >>"
    $global:ItemTemplateNameIsNotEditMode = $true
    $inputName = $dsWindow.FindName("TxtBxNewItemTemplateName").Text
    Log -Message "> New Item Template input name: $($inputName)"

    $nodeKey = $dsWindow.FindName("ItemTemplateList").selectedItem.Key
    Edit-ItemTemplateXML -Key $nodeKey -Value $inputName -UpdateTemplateListSource

    $dsWindow.FindName("ItemTemplateNameGrid").Visibility = "Collapsed"
    $dsWindow.FindName("GridItemTemplate").IsEnabled = "True"

}

function AddItemTemplate {
	$erpMaterial = OpenErpSearchWindow
    if ($erpMaterial) {
        Edit-ItemTemplateXML -Key $erpMaterial.Number -Value $erpMaterial.Number -UpdateTemplateListSource
    }
}

function Edit-ItemTemplateXML {
    Param(
        [Parameter(Mandatory=$true)]$Key,
        [Parameter(Mandatory=$true)]$Value,
        [String]$XMLSourcePath="C:\Temp\PGT_ItemTemplates.xml",
        [switch]$UpdateTemplateListSource
    )

    [xml]$xml = Get-Content -Path $XMLSourcePath
    $xml.Load($XMLSourcePath)
    $existingNode = $xml.ItemTemplateNumbers.ChildNodes | where {$_.Key -eq $key}

    if($existingNode)
    {
        $existingNode.SetAttribute("Value", $Value)     
    } 
    else
    {
        $target = $xml.ItemTemplateNumbers
        $addElem = $xml.CreateElement("Entry")
        $addKey = $xml.CreateAttribute("Key")
        $addKey.Value = $key
        $addValue = $xml.CreateAttribute("Value")
        $addValue.Value = $Value
        $addElem.Attributes.Append($addKey)
        $addElem.Attributes.Append($addValue)
        $target.AppendChild($addElem)
    }
    
    (Format-XMLIndent -Content $xml -Indent 3) | Out-File $XMLSourcePath -Force | Out-Null

    if($UpdateTemplateListSource.IsPresent)
    {
        $updatedItemList = @(GetItemTemplateList)
        $dsWindow.FindName("ItemTemplateList").ItemsSource = $updatedItemList    
    }
}
