Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Set-DryADAccessRule{
    [CmdletBinding(DefaultParameterSetName = 'Local')] 
    param( 
        [Parameter(HelpMessage = "Name of user to delegate rights to. 
        Never used by DryDeploy, since rights are always delegated to groups")]
        [string]
        $User,

        [Parameter(HelpMessage = "Name of group to delegate rights to")]
        [string]
        $Group,    
    
        [Parameter(Mandatory,
            HelpMessage = "DistinguisheName of container object (ou or cn) to set rights on")]
        [string]
        $Path,

        [Parameter(Mandatory,
            HelpMessage = "Array of Active Directory standard or extended rights")]
        [String[]]
        $ActiveDirectoryRights,
        
        [Parameter(Mandatory,
            HelpMessage = "Access Controlad Type, either 'Allow' or 'Deny'.")]
        [ValidateSet("Allow", "Deny")]
        [string]
        $AccessControlType, 
        
        [Parameter(HelpMessage = "Inheritance")]
        [ValidateSet("All", "Children", "Descendents", "SelfAndChildren", "None")]
        [string]
        $ActiveDirectorySecurityInheritance, 

        [Parameter(HelpMessage = "The AD object type that the right(s) applies to. 
        Like 'user','computer' or 'organizationalunit', or any other AD object type")]
        [string]
        $ObjectType, 
        
        [Parameter(HelpMessage = "The object type by name that should inherit the right(s).")]
        [string]
        $InheritedObjectType,

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
        if($Group -and (-not $User)){
            $TargetName = $Group
            $TargetType = 'group'
        }
        elseif($User -and (-not $Group)){
            $TargetName = $User
            $TargetType = 'user'
        }
        else{
            throw "Specify either a Group or a User to delegate permissions to - and not both"
        }
        
        olad v @('Path', "$Path")
        olad v @('TargetName', "$TargetName")
        olad v @('TargetType', "$TargetType")
        

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

        # Since parameters cannot be splatted, or named in -Argumentslist, make sure all exists
        if(-not $ObjectType){ [string]$ObjectType = '' }
        if(-not $InheritedObjectType){ [string]$InheritedObjectType = '' }
        if(-not $ActiveDirectorySecurityInheritance){ [string]$ActiveDirectorySecurityInheritance = '' }
            
        $ArgumentList = @(
            $Path,
            $TargetName,
            $TargetType,
            $ActiveDirectoryRights,
            $AccessControlType,
            $ObjectType,
            $InheritedObjectType,
            $ActiveDirectorySecurityInheritance,
            $ExecutionType,
            $Server
        )
        $InvokeParams = @{
            ScriptBlock  = $DryAD_SB_ADAccessRule_Set
            ArgumentList = $ArgumentList
        }
        if($PSCmdlet.ParameterSetName -eq 'Remote'){
            $InvokeParams += @{
                Session = $PSSession
            }
        }
        $return = $null; $return = Invoke-Command @InvokeParams

        # Send every string in $Return[0] to Debug via Out-DryADLog
        foreach($ReturnString in $Return[0]){
            olad d "$ReturnString"
        }
        
        # Test the ReturnValue in $Return[1]
        if($Return[1] -eq $true){
            olad v "Successfully configured AD right"
            $true
        } 
        else{
            olad w "Failed to configure AD right"
            if($null -ne $Return[2]){
                throw ($Return[2]).ToString()
            } 
            else{
                throw "ReturnValue false, but no ErrorRecord returned - check debug"
            }
        }  
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
