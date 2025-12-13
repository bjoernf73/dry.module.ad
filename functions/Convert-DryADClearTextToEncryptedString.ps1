<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Convert-DryADClearTextToEncryptedString{
    [CmdletBinding()]
    [OutputType([System.String])]
    param( 
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClearText,
        
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string] $CertificateFile
    )

    try{
        # Encrypts 
        olad v @("CertificateFile", $CertificateFile)
        $PublicCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificateFile)
        # System.Security.Cryptography.ECDsa eCDsa = certificate.GetECDsaPublicKey(); // This line causes an exception - the certificate key pair must be RSA
        $ByteArray = [System.Text.Encoding]::UTF8.GetBytes($ClearText)
        $EncryptedByteArray = $PublicCert.PublicKey.Key.Encrypt($ByteArray, $true)
        $EncryptedBase64String = [Convert]::ToBase64String($EncryptedByteArray)
        return $EncryptedBase64String 
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
