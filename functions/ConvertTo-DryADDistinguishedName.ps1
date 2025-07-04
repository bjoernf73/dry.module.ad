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

<# 
.Synopsis 
    Translates a path 'Servers/Serverroles/CA' (from root to leaf) to a 
    domainDN like OU=CA,OU=ServerRoles,OU=Servers (from leaf to root). 
#> 
function ConvertTo-DryADDistinguishedName{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter()]
        [ValidateSet("upper", "lower", "ignore", "capitalize", "capitalized")]
        [string]$Case = 'ignore'
    )
    
    # chop off any leading or trailing slashes and spaces. 
    $Name = $Name.Trim()
    $Name = $Name.Trim('/')
    olad d @('Input', $Name)   
   
    try{
        [string]$ConvertedName = ""
        
        if(
            ($Name -match "^ou=") -or 
            ($Name -match "^cn=")
        ){
            # the name is alerady a dN
            olad d @('The input is already a DistinguishedName', $Name)   
            $ConvertedName = "$Name"
        }
        elseif($name -eq ''){
            olad d 'Empty string (probably root of domain - return empty string then'
            $ConvertedName = $name
        }
        else{
            # names like root/middle/leaf will be converted 
            # to ou=leaf,ou=middle,ou=root. Must assume that 
            # these are OUs, not CNs (or DCs)
            $NameArr = @($Name -split "/")
            for ($c = ($nameArr.Count - 1); $c -ge 0; $c--){  
                $ConvertedName += "OU=$($nameArr[$c]),"
            }
            # The accumulated name ends with ',', chop that off
            $ConvertedName = $ConvertedName.TrimEnd(',')
        }

        olad d @('Sending to ConvertTo-DryADCase' , "$ConvertedName")
        $ConvertedName = ConvertTo-DryADCase -Name $ConvertedName -Case $Case 

        olad d @('Returning', "$ConvertedName")  
        $ConvertedName
    }
    catch{
        olad w "Error converting '$Name' to distinguishedName"  
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
