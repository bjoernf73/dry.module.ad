﻿<#  
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
