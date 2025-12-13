<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Convert-DryADEncryptedBase64StringToClearText{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $EncryptedBase64String
    )
    try{
        # Try to find a certificate in the LocalMachine\My (Personal) Store with
        #   - a private key accessible
        #   - of type SHA256 RSA (ECDH does not work)
        #   - 'Server Authentiaction' as part of the Enhanced Key Usage
        $Cert = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction Stop | 
            Where-Object{ 
            ($_.HasPrivateKey -eq $true) -and 
            ($_.SignatureAlgorithm.FriendlyName -eq 'SHA256RSA') -and
            (@(($_.EnhancedKeyUsageList).FriendlyName) -contains 'Server Authentication')  
            }

        # If multiple, use first
        if($Cert -is [array]){
            $Cert = $Cert[0]
        }
        
        if($Cert){
            $EncryptedByteArray = [Convert]::FromBase64String($EncryptedBase64String)
            $ClearText = [System.Text.Encoding]::UTF8.GetString($Cert.PrivateKey.Decrypt($EncryptedByteArray, $true))
        }
        else{
            throw "Server Authentication Certificate with Private Key not found!"
        }
        return $ClearText
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
