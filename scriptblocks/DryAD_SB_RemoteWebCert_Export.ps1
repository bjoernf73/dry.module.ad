Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_RemoteWebCert_Export ={
    param(
        [string] $Path,
        [array]  $SignatureAlgorithms,
        [string] $KeyUsage
    )
    try{
        $Cert = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction Stop | Where-Object{ 
            ($_.HasPrivateKey -eq $true) -and 
            ($_.SignatureAlgorithm.FriendlyName -in $SignatureAlgorithms) -and
            (@(($_.EnhancedKeyUsageList).FriendlyName) -contains $KeyUsage)  
        }

        # If multiple, use first
        if($Cert -is [array]){
            $Cert = $Cert[0]
        }
        
        if($Cert -is [System.Security.Cryptography.X509Certificates.X509Certificate2]){
            Export-Certificate -Cert $Cert -FilePath $Path -Type CERT -Force -ErrorAction Stop | 
                Out-Null
        }
        else{
            throw "Certificate not found"
        }
        return @($true, '')
    }
    catch{
        return @($false, "$($_.ToString())")
    }
}
