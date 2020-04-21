$global:XMLSourcePath = 'C:\Temp\test.xml'

<# EXAMPLE XML
<?xml version="1.0" encoding="utf-8"?>
<company>
    <category>
        <category1 name="Office1">
            <category2 name="Project1">
                <category3 name="Test1"/>
                <category3 name="Test2"/>
            </category2>
            <category2 name="Project2">
                <category3 name="Test1"/>
                <category3 name="Test2"/>
                <category3 name="Test3"/>
            </category2>
         </category1>

         <category1 name="Office2">
            <category2 name="Project1">
                <category3 name="Test1"/>
                <category3 name="Test2"/>
            </category2>
            <category2 name="Project2">
                <category3 name="Test1"/>
                <category3 name="Test2"/>
                <category3 name="Test3"/>
            </category2>
          </category1>
    </category>  
</company>
#>

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


(Format-XMLIndent -Content $xml -Indent 3) | Out-File $XMLSourcePath -Force | Out-Null

### Playing with nodes/elements (example on top)
$target = (($xml.company.category.category1|where {$_.name -eq "Office2"}).category2|where {$_.name -eq "Project2"})
[xml]$xml = Get-Content -Path $XMLSourcePath
$xml.Load($XMLSourcePath)
$target = $xml.ItemTemplateNumbers
$addElem = $xml.CreateElement("Entry")
$addKey = $xml.CreateAttribute("Key")
$addKey.Value = "10009"
$addValue = $xml.CreateAttribute("Value")
$addValue.Value = "10009"
$addElem.Attributes.Append($addKey)
$addElem.Attributes.Append($addValue)
$target.AppendChild($addElem)
