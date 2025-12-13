Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Set-DryADDrive{
    [CmdletBinding(DefaultParameterSetName = 'Local')] 
    param( 
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
            olad v @("Making sure AD Drive on DC $($PSSession.ComputerName) targets", 'localhost')
            $Server = 'localhost'
            olad d @('Session Type', 'Remote')
            olad d @('Remoting to Domain Controller', $PSSession.ComputerName)
        }
        else{
            olad v @('Making sure AD Drive on local system targets DC', "$DomainController")
            $Server = $DomainController
            olad d @('Session Type', 'Local')
            olad d @('Using Domain Controller', $Server)
        }
        
        $ArgumentList = @($Server)
        $InvokeParams = @{
            ScriptBlock  = $DryAD_SB_ADDrive_Set
            ArgumentList = $ArgumentList
        }
        if($PSCmdlet.ParameterSetName -eq 'Remote'){
            $InvokeParams += @{
                Session = $PSSession
            }
        }
        $return = $null; $return = Invoke-Command @InvokeParams

        # Send every string in $Return[0] to Degug via Out-DryADLog
        foreach($ReturnString in $Return[0]){
            olad d "$ReturnString"
        }
        
        # Test the ReturnValue in $Return[2]
        if($Return[1] -eq $true){
            olad v "Successfully set AD Drive to target Domain Controller"
        } 
        else{
            olad w "Failed to set AD Drive to target Domain Controller"
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
