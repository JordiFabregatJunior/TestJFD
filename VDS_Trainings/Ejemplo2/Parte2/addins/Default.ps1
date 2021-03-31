
Import-Module 'C:\ProgramData\coolOrange\powerJobs\Modules\cO.Logging.psm1'

$global:SpecificProcesses = @(
	New-Object PSObject -Property @{
		ProcessFamily = "Acabado"
		ProcessID = "QAA-110"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Acabado"
		ProcessID = "QAA-120"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Acabado"
		ProcessID = "QAA-121"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Acabado"
		ProcessID = "QAA-130"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Desbaste"
		ProcessID = "QAD-250"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Desbaste"
		ProcessID = "QAD-251"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Desbaste"
		ProcessID = "QAD-252"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Desbaste"
		ProcessID = "QAD-260"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Rectificado"
		ProcessID = "QAR-300"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Rectificado"
		ProcessID = "QAR-310"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Rectificado"
		ProcessID = "QAR-350"
	}
	New-Object PSObject -Property @{
		ProcessFamily = "Rectificado"
		ProcessID = "QAR-370"
	}
	New-Object PSObject -Property @{
		ProcessFamily = ""
		ProcessID = ""
	}

)

function InitializeWindow
{
	#begin rules applying commonly
    $dsWindow.Title = SetWindowTitle		
    InitializeCategory
    InitializeNumSchm
    InitializeBreadCrumb
	InitializeFileNameValidation
	InitializeProcesses
	#end rules applying commonly
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"InventorWindow"
		{
			#rules applying for Inventor
		}
		"AutoCADWindow"
		{
			#rules applying for AutoCAD
		}
	}
	$global:expandBreadCrumb = $true	
}

function InitializeProcesses {

	Log -Message "$($MyInvocation.MyCommand.Name)"

	$global:MainProcesses = @(
		"Desbaste"
		"Acabado"
		"Rectificado"
		""
	)
	$dsWindow.FindName("CmbxFamiliaProcesos").ItemsSource = $global:MainProcesses
	$dsWindow.FindName("CmbxFamiliaProcesos").SelectedIndex = "0"
	$dsWindow.FindName("CmbxFamiliaProcesos").add_SelectionChanged({
		$global:selectedIDProcesses = GetIDProcesses
		$dsWindow.FindName("CmbxIDProcesos").ItemsSource = $selectedIDProcesses
		$dsWindow.FindName("CmbxIDProcesos").SelectedIndex = "0"
	})
}

function GetIDProcesses {

	Log -Message "$($MyInvocation.MyCommand.Name)"

	$family =$dsWindow.FindName("CmbxFamiliaProcesos").SelectedItem

	if($family){
		$familyCode = $family[0]
	}
	Log -Message "$($MyInvocation.MyCommand.Name) >>> Selected family: '$family ' - FamilyCode: '$familyCode'"

	$selectedProcesses = $global:SpecificProcesses | where {
		$_.ProcessId[2] -like "*$familyCode*"
	}
	return @($selectedProcesses.ProcessId)
}


function InitializeCategory()
{
    if ($Prop["_CreateMode"].Value)
    {
		if (-not $Prop["_SaveCopyAsMode"].Value)
		{
			$Prop["_Category"].Value = $UIString["CAT1"]
        }
    }
}

function InitializeNumSchm()
{
	#Adopted from a DocumentService call, which always pulls FILE class numbering schemes
	$global:numSchems = @($vault.NumberingService.GetNumberingSchemes('FILE', 'Activated')) 
    if ($Prop["_CreateMode"].Value)
    {
		if (-not $Prop["_SaveCopyAsMode"].Value)
		{
			$Prop["_Category"].add_PropertyChanged({
				if ($_.PropertyName -eq "Value")
				{
					$numSchm = $numSchems | where {$_.Name -eq $Prop["_Category"].Value}
                    if($numSchm)
					{
                        $Prop["_NumSchm"].Value = $numSchm.Name
                    }
				}	
			})
        }
		else
        {
            $Prop["_NumSchm"].Value = "None"
        }
    }
}

function GetVaultRootFolder()
{
    $mappedRootPath = $Prop["_VaultVirtualPath"].Value + $Prop["_WorkspacePath"].Value
    $mappedRootPath = $mappedRootPath -replace "\\", "/" -replace "//", "/"
    if ($mappedRootPath -eq '')
    {
        $mappedRootPath = '$'
    }
    return $vault.DocumentService.GetFolderByPath($mappedRootPath)
}

function SetWindowTitle
{
	$mWindowName = $dsWindow.Name
    switch($mWindowName)
 	{
  		"InventorFrameWindow"
  		{
   			$windowTitle = $UIString["LBL54"]
  		}
  		"InventorDesignAcceleratorWindow"
  		{
   			$windowTitle = $UIString["LBL50"]
  		}
  		"InventorPipingWindow"
  		{
   			$windowTitle = $UIString["LBL39"]
  		}
  		"InventorHarnessWindow"
  		{
   			$windowTitle = $UIString["LBL44"]
  		}
  		default #applies to InventorWindow and AutoCADWindow
  		{
   			if ($Prop["_CreateMode"].Value)
   			{
    			if ($Prop["_CopyMode"].Value)
    			{
     				$windowTitle = "$($UIString["LBL60"]) - $($Prop["_OriginalFileName"].Value)"
    			}
    			elseif ($Prop["_SaveCopyAsMode"].Value)
    			{
     				$windowTitle = "$($UIString["LBL72"]) - $($Prop["_OriginalFileName"].Value)"
    			}else
    			{
     				$windowTitle = "$($UIString["LBL24"]) - $($Prop["_OriginalFileName"].Value)"
    			}
   			}
   			else
   			{
    			$windowTitle = "$($UIString["LBL25"]) - $($Prop["_FileName"].Value)"
   			} 
  		}
 	}
  	return $windowTitle
}

function GetNumSchms
{
	$specialFiles = @(".DWG",".IDW",".IPN")
    if ($specialFiles -contains $Prop["_FileExt"].Value -and !$Prop["_GenerateFileNumber4SpecialFiles"].Value)
    {
        return $null
    }
	if (-Not $Prop["_EditMode"].Value)
    {
        if ($numSchems.Count -gt 1)
		{
			$numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
		}
        if ($Prop["_SaveCopyAsMode"].Value)
        {
            $noneNumSchm = New-Object 'Autodesk.Connectivity.WebServices.NumSchm'
            $noneNumSchm.Name = $UIString["LBL77"]
            return $numSchems += $noneNumSchm
        }    
        return $numSchems
    }
}

function GetCategories
{
	return $Prop["_Category"].ListValues
}

function OnPostCloseDialog
{
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"InventorWindow"
		{
			#rules applying for Inventor
		}
		"AutoCADWindow"
		{
			#rules applying for AutoCAD
		}
		default
		{
			#rules applying commonly
		}
	}
}
