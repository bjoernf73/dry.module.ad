<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Get-DryADCredential{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ ("$_" -split '\\').count -eq 2 })]
        [string]$UserName,
        
        [Parameter()]
        [int]$Length = 20,

        [Parameter()]
        [int]$NonAlphabetics = 5,

        [Switch]$Random
    )
    try{
        if($Random){
            [SecureString]$SecStringPassword = Get-DryADRandomString -Length $Length -NonAlphabetics $NonAlphabetics -Secure
            [PSCredential]$Credential = New-Object System.Management.Automation.PSCredential ($UserName, $SecStringPassword)
        }
        else{
            [PSCredential]$Credential = Get-Credential -UserName $UserName -Message "Specify password for '$UserName'"
        }
        return $Credential
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally{
        $SecStringPassword = $null
    }
}
