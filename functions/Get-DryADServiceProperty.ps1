Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Get-DryADServiceProperty{
    [CmdletBinding(DefaultParameterSetName = 'Local')] 
    param( 
        [Parameter(Mandatory, HelpMessage = "The property to get")]
        [string] 
        $Property,

        [Parameter(Mandatory, HelpMessage = "Tells which function to run; Get-ADDomain, Get-ADForest or Get-ADRootDse")]
        [ValidateSet('domain', 'forest', 'rootdse')]
        [string] 
        $Service,

        [Parameter(Mandatory, ParameterSetName = 'Remote',
            HelpMessage = "PSSession to run the script blocks in")]
        [PSSession] 
        $PSSession,

        [Parameter(Mandatory, ParameterSetName = 'Local',
            HelpMessage = "For 'Local' sessions, specify the Domain Controller to use")]
        [string] 
        $DomainController
    )

    try{
        if($PSCmdlet.ParameterSetName -eq 'Remote'){
            $Server = 'localhost'
        }
        else{
            $Server = $DomainController
        }

        switch($Service){
            'domain'{
                $ScriptBlock = $DryAD_SB_ADDomainProperty_Get
            }
            'forest'{
                $ScriptBlock = $DryAD_SB_ADForestProperty_Get
            } 
            'rootdse'{
                $ScriptBlock = $DryAD_SB_ADRootDseProperty_Get
            }
        }
        
        $ArgumentList = @($Property, $Server)
        $InvokeParams = @{
            ScriptBlock  = $ScriptBlock
            ArgumentList = $ArgumentList
        }
        if($PSCmdlet.ParameterSetName -eq 'Remote'){
            $InvokeParams += @{
                Session = $PSSession
            }
        }
        $return = $null; 
        $return = Invoke-Command @InvokeParams

        if($return -is [ErrorRecord]){
            throw $Return
        }
        else{
            return $Return
        }
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
