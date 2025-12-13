Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function New-DryADWmiFilter{
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param(
        [Parameter(Mandatory, HelpMessage = 'The Name of the WMI Query')]
        [string]
        $Name,

        [Parameter(HelpMessage = 'Optional Description of the WMI Query')]
        [string]
        $Description,
    
        [Parameter(Mandatory, HelpMessage = 'The WMI Query itself')]
        [String[]]
        $Query,
    
        [Parameter(Mandatory, ParameterSetName = 'Remote', HelpMessage = "PSSession 
        to run the script blocks in if Remote execution")]
        [PSSession] 
        $PSSession,

        [Parameter(Mandatory, ParameterSetName = 'Local', HelpMessage = "Specify the 
        Domain Controller to target in Local Session")]
        [string] 
        $DomainController
    )
    
    if($PSCmdlet.ParameterSetName -eq 'Remote'){
        $Server = 'localhost'
        olad v @('Session Type', 'Remote')
        olad v @('Remoting to Domain Controller', $PSSession.ComputerName)
    }
    else{
        $Server = $DomainController
        olad v @('Session Type', 'Local')
        olad v @('Using Domain Controller', $Server)
    }
   
    # Test if object exists. Currently does not  
    # test the content, only if it exists or not
    try{
        $GetArgumentList = @($Name, $Server)
        $InvokeGetParams = @{
            ScriptBlock  = $DryAD_SB_WMIFilter_Get
            ArgumentList = $GetArgumentList
        }
        if($PSCmdlet.ParameterSetName -eq 'Remote'){
            $InvokeGetParams += @{
                Session = $PSSession
            }
        }
        $GetResult = Invoke-Command @InvokeGetParams

        switch($GetResult){
            $true{
                olad v "The WMIFilter '$Name' exists already"
            }
            $false{
                olad v "The WMIFilter '$Name' does not exist, must be created"
            }
            default{
                olad w "Error trying to get WMIFilter '$Name'"
                throw $GetResult.ToString()
            }
        } 
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }  

    if($GetResult -eq $false){
        try{
            $SetArgumentList = @($Name, $Description, $Query, $Server)
            $InvokeSetParams = @{
                ScriptBlock  = $DryAD_SB_WMIFilter_Set
                ArgumentList = $SetArgumentList
                ErrorAction  = 'Stop'
            }
            if($PSCmdlet.ParameterSetName -eq 'Remote'){
                $InvokeSetParams += @{
                    Session = $PSSession
                }
            }
            $SetResult = Invoke-Command @InvokeSetParams
            switch($SetResult){
                $true{
                    olad v "WMIFilter '$Name' was created"
                }
                default{
                    olad d "WMIFilter was not created"
                    throw $SetResult
                }
            } 
        }
        catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
