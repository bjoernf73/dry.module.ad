<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Get-DryADRandomString{
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Length = 20,

        [Parameter()]
        [int]$NonAlphabetics = 5,

        [Parameter(HelpMessage = "Returns Secure String instead of plain text")]
        [Switch]$Secure
    )
    try{
        Add-Type -AssemblyName System.Web -ErrorAction Stop
        switch($Secure){
            $true{
                return [SecureString](ConvertTo-SecureString $([System.Web.Security.Membership]::GeneratePassword($Length, $NonAlphabetics)) -AsPlainText -Force)
            }
            default{
                return [System.Web.Security.Membership]::GeneratePassword($Length, $NonAlphabetics)
            }
        }
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
