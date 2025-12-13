Using Namespace System.Management.Automation
Using Namespace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

function Add-DryADGroupMember{
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param(
        [Parameter(Mandatory, HelpMessage = "The Group to add the Member to")]
        [string]$Group,

        [Parameter(Mandatory, HelpMessage = "The Member to add the Group")]
        [string]$Member,

        [Parameter(Mandatory, ParameterSetName = 'Remote')]
        [PSSession]$PSSession,

        [Parameter(Mandatory, ParameterSetName = 'Local',
            HelpMessage = "For 'Local' sessions, specify the Domain Controller to use")]
        [string]$DomainController
    )
    olad d @("Adding: $Member to", $Group)
    
    <#
        If executing on a remote session to a DC, use localhost as  
        server. If not, the $DomainController param is required
    #>
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

    try{     
        $GetArgumentList = @($Group, $Member, $Server)
        $GetParams = @{
            ScriptBlock  = $DryAD_SB_GroupMember_Get
            ArgumentList = $GetArgumentList
        }
        if($PSCmdlet.ParameterSetName -eq 'Remote'){
            $GetParams += @{
                Session = $PSSession
            }
        }
        $GetResult = Invoke-Command @GetParams

        switch($GetResult){
            $true{
                olad v @("$Member is already member of", "$Group")
                return
            }
            $false{
                olad v @("$Member will be added to", "$Group")
            }
           { $GetResult -is [System.Management.Automation.ErrorRecord] }{
                $PSCmdlet.ThrowTerminatingError($GetResult)
            }
            default{
                throw "GetResult in Add-DryADGroupMember failed: $($GetResult.ToString())"
            }
        }
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
 
    try{     
        $SetArgumentList = @($Group, $Member, $Server)
        $SetParams = @{
            ScriptBlock  = $DryAD_SB_GroupMember_Set
            ArgumentList = $SetArgumentList
        }
        if($PSCmdlet.ParameterSetName -eq 'Remote'){
            $SetParams += @{
                Session = $PSSession
            }
        }
        $SetResult = Invoke-Command @SetParams 

        switch($SetResult){
            $true{
                olad v @("$Member was added to Group", $Group)
            }
           { $SetResult -is [ErrorRecord] }{
                $PSCmdlet.ThrowTerminatingError($GetResult)
            }
            default{
                throw "SetResult in Add-DryADGroupMember failed: $($GetResult.ToString())"
            }
        }
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }  
}
