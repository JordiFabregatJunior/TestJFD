function get-vALUE ($SearchValue){
     if($SearchValue){
        if($SearchValue.contains("*")){
            $SearchValue.Replace("*","")
        }
    }
    $searchOperCode = 1
    $SearchValue = "*" + $SearchValue + "*"
    return $SearchValue
}

foreach($value in @("*Value*","Value*","Value","*Value")){
    get-vALUE -SearchValue $value
}