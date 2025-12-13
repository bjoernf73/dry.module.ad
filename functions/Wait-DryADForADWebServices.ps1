Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Wait-DryADForADWebServices{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $DomainDN,

        [Parameter(Mandatory)]
        [PSSession]
        $PSSession,

        [Parameter(HelpMessage = "How long should I try this without success?")]
        [int]
        $WaitMinutes = 20
  
    )
    [Boolean]$ADWebServicesUp = $false
    [string]$DomainControllersOUDN = "OU=Domain Controllers,$DomainDN"
    [DateTime]$StartTime = Get-Date
    Do{
        $TestResult = Invoke-Command -Session $PSSession -ScriptBlock{ 
            param($DomainControllersOUDN); 
            try{
                # If this works, return true
                Get-ADObject -Identity $DomainControllersOUDN | Out-Null
                $true
            } 
            catch{
                $false
            }
        } -ArgumentList $DomainControllersOUDN
        
        switch($TestResult){
            $true{
                olad v "Active Directory Web Services is now up and reachable."
                $ADWebServicesUp = $true
            }
            $false{
                #! should Out-DryADLog have a wait-option?
                olad v "Waiting for Active Directory Web Services to become available...."
                Start-Sleep -Seconds 30
            }
            default{
                olad e "Error testing Active Directory Web Services"
                throw $TestResult
            }
        } 
    }
    While (
        (-not $ADWebServicesUp) -and
        (Get-Date -lt ($StartTime.AddMinutes($WaitMinutes)))
    )

    switch($ADWebServicesUp){
        $false{
            olad e "AD Webservices wasn't ready after waiting the configured $WaitMinutes minutes"
            throw "AD Webservices wasn't ready after waiting the configured $WaitMinutes minutes"
        }
        default{
        }
    }
}
