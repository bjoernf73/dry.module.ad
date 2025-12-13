Using Namespace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

function Remove-DryADGPLink{
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param(
        [Parameter(Mandatory, HelpMessage = "Object containing description ov an OU and set of ordered GPLinks")]
        [PSObject]
        $GPOLinkObject,

        [Parameter(Mandatory)]
        [string]
        $DomainFQDN,

        [Parameter(Mandatory)]
        [string]
        $DomainDN,

        [Parameter(Mandatory, ParameterSetName = 'Remote')]
        [PSSession]
        $PSSession,

        [Parameter(Mandatory, ParameterSetName = 'Local',
            HelpMessage = "For 'Local' sessions, specify the Domain Controller to use")]
        [string]
        $DomainController
    )

    if($PSCmdLet.ParameterSetName -eq 'Remote'){
        $Server = 'localhost'
        olad v @('Session Type', 'Remote')
        olad v @('Remoting to Domain Controller', "$($PSSession.ComputerName)")
    }
    else{
        $Server = $DomainController
        olad v @('Session Type', 'Local')
        olad v @('Using Domain Controller', "$Server")
    }
  
    # Add the domainDN to $OU if not already done
    if($GPOLinkObject.Path -notmatch "$DomainDN$"){
        if(($GPOLinkObject.Path).Trim() -eq ''){
            # The domain root
            $GPOLinkObject.Path = $DomainDN
        }
        else{
            $GPOLinkObject.Path = $GPOLinkObject.Path + ',' + $DomainDN
        }
    }
    olad v @('Linking GPOs to', "$($GPOLinkObject.Path)") 

    try{
        $RemoveLinkArgumentList = @($GPOLinkObject.Path, $LinkToRemove, $Server)
        $InvokeRemoveLinkParams = @{
            ScriptBlock  = $DryAD_SB_GPLink_Remove
            ArgumentList = $RemoveLinkArgumentList
        }
        if($PSCmdLet.ParameterSetName -eq 'Remote'){
            $InvokeRemoveLinkParams += @{
                Session = $PSSession
            }
        }
        $RemoveLinkRet = Invoke-Command @InvokeRemoveLinkParams 
        
        if($RemoveLinkRet[0] -eq $true){
            olad d "Successfully removed link for GPO '$LinkToRemove'"
        }
        else{
            throw $RemoveLinkRet[1]
        }
    }
    catch{
        $PSCmdLet.ThrowTerminatingError($_)
    }
}














