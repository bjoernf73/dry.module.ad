Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#>
function New-DryADSecurityGroup {
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param (   
        [Parameter(Mandatory,
            HelpMessage = "Enter name of the group")]
        [ValidateNotNullOrEmpty()]
        [string] $Name, 

        [Parameter(Mandatory,
            HelpMessage = "Enter distinguishedName of the path of the group")]
        [ValidateScript({ $_ -match "^OU=" -or $_ -match "^CN="})]
        [string]$Path, 
        
        [Parameter(HelpMessage = "Optionally, enter a description for the group")]
        [string]$Description, 

        [Parameter(HelpMessage = "Active Directory group scope. Must be 'DomainLocal', 'Global' or 'Universal'")]
        [ValidateSet("DomainLocal", "Global", "Universal")]
        [string] $GroupScope = "DomainLocal", 

        [Parameter(HelpMessage = "Group category. Must be 'Security' or 'Distribution'. Defaults to security.")]
        [string] 
        $GroupCategory = "Security",

        [Parameter(ParameterSetName = 'Remote',
            HelpMessage = "PSSession to run the script blocks in")]
        [PSSession]$PSSession,

        [Parameter(Mandatory, ParameterSetName = 'Local',
            HelpMessage = "For 'Local' sessions, specify the Domain Controller to use")]
        [string]$DomainController
    )
    # Details to the debug stream
    olad d @("Creating Group", $Name)
    olad d @("Group Path", $Path)
    olad d @("Group Scope", $GroupScope)
    olad d @("Group Category", $GroupCategory)
    olad d @("Group Description", $Description)
    <#
        If executing on a remote session to a DC, use localhost as  
        server. If not, the $DomainController param is required
    #>
    if ($PSCmdlet.ParameterSetName -eq 'Remote') {
        $Server = 'localhost'
        olad d @('Session Type', 'Remote')
        olad d @('Remoting to Domain Controller', "$($PSSession.ComputerName)")
    }
    else {
        $Server = $DomainController
        olad d @('Session Type', 'Local')
        olad d @('Using Domain Controller', "$Server")
    }
    
    try {
        $GetArgumentList = @($Name, $Server)
        $GetParams = @{
            ScriptBlock  = $DryAD_SB_SecurityGroup_Get
            ArgumentList = $GetArgumentList
        }
        if ($PSCmdlet.ParameterSetName -eq 'Remote') {
            $GetParams += @{
                Session = $PSSession
            }
        }
        $GetResult = Invoke-Command @GetParams

        switch ($GetResult) {
            $true {
                olad v @("The AD Group exists already", $Name)
                Return
            }
            $false {
                olad v @("The Group does not exist, and must be created", $Name)
            }
            default {
                olad e @("Error trying to get Group", "$Name")
                throw $GetResult
            }
        } 
    }
    catch {
        olad e @("Failed trying to get group", "$Name")
        throw $_
    }
    
    if ($GetResult -eq $false) {
        $SetArgumentList = @($Name, $Path, $Description, $GroupCategory, $GroupScope, $Server)
        $SetParams = @{
            ScriptBlock  = $DryAD_SB_SecurityGroup_Set
            ArgumentList = $SetArgumentList
        }
        if ($PSCmdlet.ParameterSetName -eq 'Remote') {
            $SetParams += @{
                Session = $PSSession
            }
        }
        $SetResult = Invoke-Command @SetParams
        
        switch ($SetResult) {
            $true {
                olad v @("AD Group was created", $Name)
            }
            default {
                olad e @('Error creating AD Group', $Name)
                throw $SetResult
            }
        }
    }
}
