using NameSpace System.Management.Automation
using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Add-DryADPSModulesPath{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSSession]$PSSession,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(HelpMessage = 'Forcefully import the modules into the session')]
        [string[]]$Modules
    )

    try{
        
        
        # Add Path to $env:PSModulePath on the remote system, so functions are
        # available without explicit import. 
        
        # Change double backslash to single, remove trailing backslash, and lastly make all 
        # single backslashes double in the regex
        $Path = ($Path.Replace('\\', '\')).TrimEnd('\')         
        $PathRegEx = $Path.Replace('\', '\\')

        $InvokePSModPathParams = @{
            ScriptBlock  = $DryAD_SB_PSModPath
            Session      = $PSSession 
            ArgumentList = @($Path, $PathRegEx)
        }
        $RemotePSModulePaths = Invoke-Command @InvokePSModPathParams

        olad v @('The PSModulePath on remote system', "'$RemotePSModulePaths'")
        switch($RemotePSModulePaths){
           { $RemotePSModulePaths -Match $PathRegEx }{
                olad v @('Successfully added to remote PSModulePath', "'$Path'")
            }
            default{
                olad w @('Failed to add path to remote PSModulePath', "'$Path'")
                throw "The RemoteRootPath '$Path' was not added to the PSModulePath in the remote session"
            }
        }

        if($Modules){
            $ImportModsParams = @{
                Session      = $PSSession 
                ScriptBlock  = $DryAD_SB_ImportMods 
                ArgumentList = @($Modules)
                ErrorAction  = 'Stop' 
            }   
            $ImportResult = Invoke-Command @ImportModsParams
    
            switch($ImportResult){
                $true{
                    olad v "The modules '$Modules' were imported into PSSession to $($PSSession.ComputerName)"
                }
                default{
                    olad w "The modules '$Modules' were not imported into PSSession to $($PSSession.ComputerName)"
                    throw "The modules '$Modules' were not imported into PSSession to $($PSSession.ComputerName)"
                }
            }
        }
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally{
        $ProgressPreference = $OriginalProgressPreference
    }
}
