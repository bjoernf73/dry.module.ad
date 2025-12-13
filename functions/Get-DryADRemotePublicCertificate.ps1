Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Get-DryADRemotePublicCertificate{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = "PSSession to a Domain Controller")]
        [PSSession]
        $PSSession,
        
        [Parameter(Mandatory)]
        [string]
        $CertificateFile
    )

    try{
        $InvokeCommandParams = @{
            ScriptBlock  = $DryAD_SB_RemoteWebCert_Export
            Session      = $PSSession
            ArgumentList = @('C:\PublicCertificate.cer', @('SHA256RSA'), 'Server Authentication')
        }
        $Result = Invoke-Command @InvokeCommandParams
        
        if($Result[0] -eq $true){
            Copy-Item -FromSession $PSSession -Path 'C:\PublicCertificate.cer' -Destination "$CertificateFile" -Force -ErrorAction Stop
            olad v @('Fetched public certificate', "$CertificateFile")
        }
        else{
            throw "Failed getting remote public certificate: $($Result[1].ToString())"
        }
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally{
        $InvokeRemoveParams = @{
            ScriptBlock  = $DryAD_SB_RemoveItem
            Session      = $PSSession
            ErrorAction  = 'Ignore'
            ArgumentList = @('C:\PublicCertificate.cer', 'Ignore')
        }
        Invoke-Command @InvokeRemoveParams | Out-Null
    }
}
