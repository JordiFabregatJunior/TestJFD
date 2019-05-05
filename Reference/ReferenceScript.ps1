Function ParameterValidation 
{ 
    Param( 
        [ValidateSet(“Tom”,”Dick”,”Jane”)] 
        [String] 
        $Name 
    , 
        [ValidateRange(21,65)] 
        [Int] 
        $Age 
    , 
        [ValidateScript({Test-Path $_ -PathType ‘Container’})] 
        [string] 
        $Path = "Default Path"
    ,
        [Parameter(Mandatory=$True, ParameterSetName="Computer")][ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName
    ,
        [ValidateLength(10,10)][ValidatePattern("[D][V][-]\d{7}")]
        [string]
        $pattern
    ,
        [ValidateCount(1,5)]
        [string[]]
        $Counting
    ) 

    Process 
    { 
        write-host “Nice Validation” 
    } 
}

function SwitchCommand {

    switch -Wildcard ($file._Extension){

        #Confitioins which would make if cry
        "ipt" {$jobType = "Autodesk.Vault.DWF.Create.ipt"}
        "iam" {$jobType = "Autodesk.Vault.DWF.Create.iam"}
        3 {"It is three."}
        3 {"This is three again."; Break}
        "i*" {$jobType = "this would be a mess, not able to distnguish"}

        #...Oh...
        default {
            "Write this if any prvious condition matched"
        }
    }
}

function SwitchParameterType {
    #Using within a parameter
    param(
    [Parameter()]
    [Switch]$Force
    )

    if($Force.IsPresent){
        Write-Host "better to use this than Force as bool anc checking 'if ($Force -eq $true) {...}'"
    }
    # When calling function:
    # SwitchParameterType            => Force = $false
    # SwitchParameterType -Force     => Force = $true
}

<#NOT UNDERSTOOD 7WORKING EXAMPLE
Function Begin_Process_Ending
{
    Param ($Parameter1)
    Begin{"Starting"}
    Process{"Paraemter = $($Parameter1)"}
    End{"Ending"}
}

$list = @("hey","hello")
$list | foreach {test -Parameter1 $_}
#>