Using NameSpace System.Management.Automation
Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Move-DryADComputer{
    [CmdletBinding(DefaultParameterSetName = 'Local')] 
    param(
        [Parameter(Mandatory)]
        [string]
        $ComputerName,

        [Parameter(Mandatory)]
        [string]
        $TargetOU,

        [Parameter(HelpMessage = "Only test, and return true or false")]
        [Switch]
        $Test,

        [Parameter(Mandatory, ParameterSetName = 'Remote',
        HelpMessage = "PSSession to run the script blocks in")]
        [System.Management.Automation.Runspaces.PSSession] 
        $PSSession,

        [Parameter(Mandatory, ParameterSetName = 'Local',
        HelpMessage = "For 'Local' sessions, specify the Domain Controller to use")]
        [string] 
        $DomainController
    )
    olad v @("Moving: '$ComputerName' to OU", "$TargetOU")

    # Is the Object already in place??
    try{
        if($PSCmdlet.ParameterSetName -eq 'Remote'){
            $Server = 'localhost'
            $ExecutionType = 'Remote'
            olad v @('Session Type', 'Remote')
            olad v @('Remoting to Domain Controller', $PSSession.ComputerName)
        }
        else{
            $Server = $DomainController
            $ExecutionType = 'Local'
            olad v @('Session Type', 'Local')
            olad v @('Using Domain Controller', $Server)
        }

        $GetArgumentList = @($ComputerName, $TargetOU, $Server)
        $InvokeGetParams = @{
            ScriptBlock  = $DryAD_SB_MoveComputer_Get
            ArgumentList = $GetArgumentList
        }
        if($ExecutionType -eq 'Remote'){
            $InvokeGetParams += @{
                Session = $PSSession
            }
        }
        $GetResult = Invoke-Command @InvokeGetParams 

        switch($GetResult){
            $true{
                olad v "'$ComputerName' is already in OU '$TargetOU'"
            }
            $false{
                olad v "'$ComputerName' is not in OU '$TargetOU' - trying to move it"
            }
           { $GetResult -is [System.Management.Automation.ErrorRecord] }{
                $PSCmdlet.ThrowTerminatingError($GetResult)
            }
            default{
                throw "An Error occured $($GetResult.ToString())"
            }
        }
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }

    if($Test){
        return $GetResult
    }
    elseif($GetResult -eq $false){
        try{     
            
            $SetArgumentList = @($ComputerName, $TargetOU, $Server)
            $InvokeSetParams = @{
                ScriptBlock  = $DryAD_SB_MoveComputer_Set
                ArgumentList = $SetArgumentList
            }
            if($ExecutionType -eq 'Remote'){
                $InvokeSetParams += @{
                    Session = $PSSession
                }
            }
            $SetResult = Invoke-Command @InvokeSetParams

            switch($SetResult){
                $true{
                    olad v "'$ComputerName' was moved into OU '$TargetOU'"
                }
               { $SetResult -is [System.Management.Automation.ErrorRecord] }{
                    $PSCmdlet.ThrowTerminatingError($SetResult)
                }
                default{
                    throw "An Error occured $($SetResult.ToString())"
                }
            }
        }
        catch{
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
