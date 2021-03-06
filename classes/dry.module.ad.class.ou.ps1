Using Module ActiveDirectory
Using Namespace System.Management.Automation.Runspaces
# dry.module.ad is an AD config module for use with DryDeploy, or by itself.
#
# Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
# LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

Class OU {
    [String]       $OUDN
    [String]       $ObjectType
    [String]       $DomainFQDN
    [String]       $DomainDN
    [PSSession]    $PSSession
    [String]       $DomainController
    [PSCredential] $Credential
    [String]       $ExecutionType

    # Overload for CN or OU creation in a PSSession
    OU(
        [String]    $OUDN,
        [String]    $DomainFQDN,
        [PSSession] $PSSession
    )
    {
        $This.OUDN = $OUDN
        If ($This.OUDN -match "^CN=*") {
            $This.ObjectType   = 'container' 
        }
        ElseIf ($This.OUDN -match "^OU=*") {
            $This.ObjectType   = 'organizationalUnit' 
        }
        ElseIf ($This.OUDN.Trim() -eq '') {
            $This.ObjectType   = 'DomainRoot' 
        }
        Else { 
            ol 1 "Unknown Object Type (not CN, OU or Domain Root): $($This.OUDN)"
            Throw "Unknown Object Type (not CN, OU) or Domain Root: $($This.OUDN)"
        }  
        $This.DomainFQDN       = $DomainFQDN 
        $This.DomainDN         = "DC=" + $($This.DomainFQDN.replace(".",",DC="))
        $This.PSSession        = $PSSession
        $This.ExecutionType    = 'Remote'
        $This.DomainController = 'localhost'
    } 

    # Overload for CN or OU creation locally with PSCredential
    OU(
        [String]       $OUDN,
        [String]       $DomainFQDN,
        [String]       $DomainController,
        [PSCredential] $Credential
    )
    {
        $This.OUDN = $OUDN
        If ($This.OUDN -match "^CN=*") {
            $This.ObjectType   = 'container' 
        }
        ElseIf ($This.OUDN -match "^OU=*") {
            $This.ObjectType   = 'organizationalUnit' 
        }
        ElseIf ($This.OUDN.Trim() -eq '') {
            $This.ObjectType   = 'DomainRoot' 
        }
        Else { 
            ol w "Unknown Object Type (not CN or OU): $($This.OUDN)"
            Throw "Unknown Object Type (not CN or OU): $($This.OUDN)"
        } 
        $This.DomainFQDN       = $DomainFQDN 
        $This.DomainDN         = "DC=" + $($This.DomainFQDN.replace(".",",DC="))
        $This.Credential       = $Credential
        $This.ExecutionType    = 'Local'
        $This.DomainController = $DomainController
    } 

    # Overload for CN or OU creation locally using privileges of the executing user
    OU(
        [String]       $OUDN,
        [String]       $DomainFQDN,
        [String]       $DomainController
    )
    {
        $This.OUDN = $OUDN
        If ($This.OUDN -match "^CN=*") {
            $This.ObjectType   = 'container' 
        }
        ElseIf ($This.OUDN -match "^OU=*") {
            $This.ObjectType   = 'organizationalUnit' 
        }
        ElseIf ($This.OUDN.Trim() -eq '') {
            $This.ObjectType   = 'domainRoot' 
        }
        Else { 
            ol 1 "Unknown Object Type (not CN or OU): $($This.OUDN)"
            Throw "Unknown Object Type (not CN or OU): $($This.OUDN)"
        } 
        $This.DomainFQDN       = $DomainFQDN 
        $This.DomainDN         = "DC=" + $($This.DomainFQDN.replace(".",",DC="))
        $This.Credential       = $Null
        $This.ExecutionType    = 'Local'
        $This.DomainController = $DomainController
    } 

    [void]CreateOU () {
        If ($This.ObjectType -eq 'domainRoot') {
            ol d "Trying to create root of domain - just return"
        } 
        Else {
            # Create an array of elements. Start with making sure  
            # root level exist, looping out to the leaf
            $DNParts = $This.OUDN.Split(',')
            For ($c = ($DNParts.Count -1); $c -ge 0; $c--) {    
                
                $CurrentDN             = [String]::Join(',', ($DNParts[$c..($DNParts.Count -1)]))
                $CurrentDomainDN       = ($CurrentDN + ',' + $This.DomainDN).TrimStart(',')
                $CurrentName           = (($CurrentDN -split (",",2))[0]).SubString(3)
                $CurrentParent         = ($currentDN -split (",",2))[1]
                $CurrentParentDomainDN = ($CurrentParent + ',' + $This.DomainDN).TrimStart(',')
                
                If ($CurrentParent -eq '') {
                    ol d "'$CurrentName'. The parent domainDN is $CurrentParentDomainDN"
                }
                
                Else {
                    ol d 'LeafOU (CurrentName)',"'$CurrentName'" 
                    ol d 'Parent (CurrentParent)',"'$CurrentParent'"
                    ol d 'Parent domainDN (CurrentParentDomainDN)',"'$CurrentParentDomainDN'"
                    ol d 'CurrentDomainDN',"'$CurrentDomainDN'"
                }
                
                # Test if object exists
                try {
                    [ScriptBlock] $GetResultScriptBlock = { 
                        Param (
                            $ObjectDN,
                            $Server,
                            $Credential
                        )
                        
                        try {
                            $GetADObjectParams = @{
                                Identity    = $ObjectDN
                                Server      = $Server
                                ErrorAction = 'Stop'
                            }
                            If ($Credential) {
                                $GetADObjectParams += @{
                                    Credential = $Credential
                                }   
                            }
                            Get-ADOBject @GetADObjectParams | Out-Null
                            # The Object exists already
                            $True
                        }
                        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                            # The Object does not exist
                            $False
                        }
                        Catch {
                            $PSCmdlet.ThrowTerminatingError($_)
                        }
                    } 

                    $GetArgumentList = @($CurrentDomainDN,$This.DomainController,$This.Credential)
                    $GetParams       = @{
                        ScriptBlock  = $GetResultScriptBlock
                        ArgumentList = $GetArgumentList
                    }
                    If ($This.ExecutionType -eq 'Remote') {
                        $GetParams  += @{
                            Session  = $This.PSSession
                        }
                    }
                    $GetResult       = Invoke-Command @GetParams

                    Switch ($GetResult) {
                        $True {
                            ol s "The OU exists already"
                            ol d "The OU '$CurrentName' in parent '$CurrentParent' exists already."
                        }
                        $False {
                            ol d "The OU '$CurrentName' in parent '$CurrentParent' does not exist, must be created"
                        }
                        Default {
                            ol e "Error trying to get OU '$CurrentName' in parent '$CurrentParent'"
                            Throw $GetResult
                        }
                    } 
                }
                Catch {
                    ol e "Failed to test '$CurrentDomainDN'" 
                    throw $_
                }  

                If ($GetResult -eq $False) {
                    [ScriptBlock] $SetResultScriptBlock = { 
                        Param (
                            $Name,
                            $Type,
                            $Path,
                            $Server,
                            $Credential
                        )
                        
                        try {
                            $NewADObjectParams = @{
                                Name        = $Name
                                Type        = $Type
                                Path        = $Path
                                Server      = $Server
                                ErrorAction = 'Stop'
                            }
                            If ($Credential) {
                                $NewADObjectParams += @{
                                    Credential = $Credential
                                }   
                            }
                            New-ADOBject @NewADObjectParams | Out-Null
                            # The Object was created
                            $True
                        }
                        Catch {
                            $_
                        }
                    } 

                    $SetArgumentList = @($CurrentName,$This.ObjectType,$CurrentParentDomainDN,$This.DomainController,$This.Credential)
                    $SetParams       = @{
                        ScriptBlock  = $SetResultScriptBlock
                        ArgumentList = $SetArgumentList
                    }
                    If ($This.ExecutionType -eq 'Remote') {
                        $SetParams  += @{
                            Session  = $This.PSSession
                        }
                    }
                    $SetResult       = Invoke-Command @SetParams

                    Switch ($SetResult) {
                        $True {
                            ol s "The OU was created"
                            ol d "OU '$CurrentName' in parent '$CurrentParent' was created"
                            $OUsWasCreated = $True
                        }
                        
                        Default {
                            ol f "The OU was not created"
                            ol e "Failed to create OU '$CurrentName' in parent '$CurrentParent'"
                            Throw $SetResult.ToString()
                        }
                    }
                }
            }     
        }
    }
}