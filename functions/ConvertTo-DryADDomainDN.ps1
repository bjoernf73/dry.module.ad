<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

<# 
.Synopsis 
    Converts Domain FQDN to distinguishedName
#> 
function ConvertTo-DryADDomainDN{
    [CmdLetBinding()]
    param(
        [ValidateScript({ $_ -match "^[a-zA-Z0-9][a-zA-Z0-9-_]{0,61}[a-zA-Z0-9]{0,1}\.([a-zA-Z]{1,6}|[a-zA-Z0-9-]{1,30}\.[a-zA-Z]{2,3})$" })]
        [string]$DomainFQDN
    )

    try{
        $FQDNParts = $DomainFQDN.Split(".")
        $DomainDN = ""
        for ($i = 0; $i -le ($FQDNParts.Count - 1); $i++){
            $DomainDN += "DC=$(${FQDNParts}[$i]),"
        }
        $DomainDN = $DomainDN.Remove($DomainDN.Length - 1, 1)
        return $DomainDN
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally{
        @('DomainFQDN', 'FQDNParts').foreach({
                Remove-Variable -Name $_ -ErrorAction Ignore
            })
    }
}
