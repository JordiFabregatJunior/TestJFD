Describe "New-ODataFilter" {

    $currentFolder  = Split-Path -Parent $PSCommandPath
    $parentFolder = Split-Path -Parent $currentFolder
    $moduleName = "OData.Filter"
    $scriptPath = "$parentFolder\$moduleName.psm1"
    Import-Module $scriptPath

    Context "Generate OData filter for input:  '*This Is The END'" {
        
        it "Module exposes only New-ODataFilter function" {
            (Get-Module $moduleName).ExportedCommands.Count | Should -Be 2
            (Get-Module $moduleName).ExportedCommands.Keys | Should -Contain "New-ODataFilter"
            (Get-Module $moduleName).ExportedCommands.Keys | Should -Contain "New-ErpWildcardFilter"
        }
    }

    Context "Generate OData filter for input:  'This Is The END'" {
        $odataFilter = New-ODataFilter -WildcardValue "This Is The END" -Property "Description"
        it "Creates one EndsWith() with the passed text and property" {
            $odataFilter | Should -Be "'this is the end' eq tolower(Description)"
        }
    }
    Context "Generate OData filter for input:  '*This Is The END'" {
        $odataFilter = New-ODataFilter -WildcardValue "*This Is The END" -Property "Description"
        it "Creates one EndsWith() with the passed text and property" {
            $odataFilter | Should -Be "endswith(tolower(Description), 'this is the end') eq true"
        }
    }
    Context "Generate OData filter for input:  '*This Is The END' with -CaseSensitive" {
        $odataFilter = New-ODataFilter -WildcardValue "*This Is The END" -Property "Description" -CaseSensitive
        it "Creates one EndsWith() with the passed text tolower and property to lower" {
            $odataFilter | Should -Be "endswith(Description, 'This Is The END') eq true"
        }
    }

    Context "Generate OData filter for input:  'Lets start*'" {
        $odataFilter = New-ODataFilter -WildcardValue "Lets start*" -Property "Po*el"
        it "Creates one StartsWith() with the passed text tolower and property tolower" {
            $odataFilter | Should -Be "startswith(tolower(Po*el), 'lets start') eq true"
            
        }
    }
    Context "Generate OData filter for input:  'Lets start*' with -CaseSensitive" {
        $odataFilter = New-ODataFilter -WildcardValue "Lets start*" -Property "MyP12" -CaseSensitive
        it "Creates one StartsWith() with the passed text tolower and property to lower" {
            $odataFilter | Should -Be "startswith(MyP12, 'Lets start') eq true"
        }
    }

    Context "Generate OData filter for input:  '*The^ ^Riddle*'" {
        $odataFilter = New-ODataFilter -WildcardValue "*The^ ^Riddle*" -Property "Pro"
        it "Creates one SubstringOf() with the passed text tolower and property tolower" {
            $odataFilter | Should -Be "substringof(tolower(Pro), 'the^ ^riddle') eq true"
        }
    }

    Context "Generate OData filter for input:  '*The^ ^Riddle*' with -CaseSensitive" {
        $odataFilter = New-ODataFilter -WildcardValue "*The^ ^Riddle*" -Property "Pro" -CaseSensitive
        it "Creates one SubstringOf() with the passed text  and property" {
            $odataFilter | Should -Be "substringof(Pro, 'The^ ^Riddle') eq true"
        }
    }

    Context "Generate OData filter for input:  'Start * End'" {
        $odataFilter = New-ODataFilter -WildcardValue "Start * End" -Property "Everr"
        it "Creates one StartsWith() and one EndsWith with the passed text tolower and property tolower" {
            $odataFilter | Should -Be "startswith(tolower(Everr), 'start ') eq true and endswith(tolower(Everr), ' end') eq true"
        }
    }
    Context "Generate OData filter for input:  'Lets start*' with -CaseSensitive" {
        $odataFilter = New-ODataFilter -WildcardValue "Start * End" -Property "Everr" -CaseSensitive
        it "Creates one StartsWith() and one EndsWith with the passed text and property" {
            $odataFilter | Should -Be "startswith(Everr, 'Start ') eq true and endswith(Everr, ' End') eq true"
        }
    }

    Context "Generate OData filter for input:  'BeGiNNNN * ridddly * finiSHH'" {
        $odataFilter = New-ODataFilter -WildcardValue "BeGiNNNN * ridddly *finiSHH" -Property "Compy"
        it "Creates one StartsWith() one EndsWith and one substringof with the passed text tolower and property tolower" {
            $odataFilter | Should -Be "startswith(tolower(Compy), 'beginnnn ') eq true and endswith(tolower(Compy), 'finishh') eq true and substringof(tolower(Compy), ' ridddly ') eq true"
        }
    }
    Context "Generate OData filter for input:  'BeGiNNNN * ridddly * finiSHH' with -CaseSensitive" {
        $odataFilter = New-ODataFilter -WildcardValue "BeGiNNNN * ridddly *finiSHH" -Property "Compy" -CaseSensitive
        it "Creates one StartsWith() one EndsWith and on substringof with the passed text and property" {
            $odataFilter | Should -Be "startswith(Compy, 'BeGiNNNN ') eq true and endswith(Compy, 'finiSHH') eq true and substringof(Compy, ' ridddly ') eq true"
        }
    }

    Context "Generate OData filter for input: '*starT*part1*pArt2*Part3*part4!*End*'" {
        $odataFilter = New-ODataFilter -WildcardValue "*starT*part1*pArt2*Part3*part4!*End*" -Property "This"
        it "Creates one StartsWith() and one EndsWith with the passed text tolower and property tolower" {
            $odataFilter | Should -Be "substringof(tolower(This), 'start') eq true and substringof(tolower(This), 'part1') eq true and substringof(tolower(This), 'part2') eq true and substringof(tolower(This), 'part3') eq true and substringof(tolower(This), 'part4!') eq true and substringof(tolower(This), 'end') eq true"
        }
    }
    Context "Generate OData filter for input: '*starT*part1*pArt2*Part3*part4!*End*' with -CaseSensitive" {
        $odataFilter = New-ODataFilter -WildcardValue "*starT*part1*pArt2*Part3*part4!*End*" -Property "This" -CaseSensitive
        it "Creates one StartsWith() and one EndsWith with the passed text and property" {
            $odataFilter | Should -Be "substringof(This, 'start') eq true and substringof(This, 'part1') eq true and substringof(This, 'pArt2') eq true and substringof(This, 'Part3') eq true and substringof(This, 'part4!') eq true and substringof(This, 'End') eq true"
        }
    }
    Context "Generate New-WildCard  filter for input:  'Start*End'" {
        $odataFilter = New-ErpWildcardFilter -WildcardValue "Start*End" -Property "Prop"
        it "Creates one StartsWith() and one EndsWith() with the passed text tolower and property tolower" {
            $odataFilter | Should -Be "startswith(tolower(Prop), 'start') eq true and endswith(tolower(Prop), 'end') eq true"
        }
    }
    Context "Generate New-WildCard filter for input:  'Start*Mid*End'" {
        $odataFilter = New-ErpWildcardFilter -WildcardValue "Start*Mid*End" -Property "Prop"
        it "Creates one StartsWith() and one EndsWith() and substringof() with the passed text tolower and property tolower" {
            $odataFilter | Should -Be "startswith(tolower(Prop), 'start') eq true and endswith(tolower(Prop), 'end') eq true and substringof('mid', tolower(Prop)) eq true"
        }
    }
    Context "Generate New-WildCard  filter for input: 'ExceptionNoWildcards'" {
        $odataFilter = New-ErpWildcardFilter -WildcardValue "ExceptionNoWildcards" -Property "Prop"
        it "Creates a substringof() with the passed text and property" {
            $odataFilter | Should -Be "substringof('exceptionnowildcards', tolower(Prop)) eq true"
        }
    }

    function New-ErpProperty([string]$Name, [type]$Type) {
        Add-Type -TypeDefinition @"
        public class ErpProperty
        {
            public System.Type Type {get; set; }
            string _name;
            public ErpProperty(string name) 
            {
                _name = name;
            }
            public override string ToString()
            {
                return _name;
            }
        }
"@
        $erpProperty = New-Object ErpProperty -ArgumentList @($Name) -Property @{
                "Type" = $Type
        }
        return $erpProperty
    }
    $erpEntityType = New-Object psobject -Property @{
        "Keys" = @(
            (New-ErpProperty -Name "Age" -Type "int"),
            (New-ErpProperty -Name "Name" -Type "string")
        )
        "Properties" = @(
            (New-ErpProperty -Name "Location" -Type "string")
        )
    }

    Context "-ErpEntityType has key property as string defined" {
        $odataFilter = New-ODataFilter -WildcardValue "ASDF" -Property "Name" -ErpEntityType $erpEntityType -CaseSensitive
        it "Creates equal operation with string sytax" {
            $odataFilter | Should -Be "'ASDF' eq Name"
        }
    }
    Context "-ErpEntityType has key property as integer defined" {
        $odataFilter = New-ODataFilter -WildcardValue "123*" -Property "Age" -ErpEntityType $erpEntityType -CaseSensitive
        it "Creates equal operation with integer sytax (without quotes)" {
            $odataFilter | Should -Be "startswith(Age, 123) eq true"
        }
    }
    Context "-ErpEntityType has normal property as string defined" {
        $odataFilter = New-ODataFilter -WildcardValue "*123" -Property "Location" -ErpEntityType $erpEntityType -CaseSensitive
        it "Creates equal operation with string sytax (with quotes)" {
            $odataFilter | Should -Be "endswith(Location, '123') eq true"
        }
    }
}
