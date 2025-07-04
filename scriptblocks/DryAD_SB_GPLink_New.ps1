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

[ScriptBlock]$DryAD_SB_GPLink_New ={
    param(
        $OU,
        $GPO,
        $Order,
        $LinkEnabled,
        $Enforced,
        $DomainController
    ) 
    
    $Status = $false
    $ErrorString = ''
    try{
        $NewLinkParams = @{
            Name        = $GPO
            Target      = $OU
            Order       = $Order
            LinkEnabled = $LinkEnabled
            Enforced    = $Enforced
            Server      = $DomainController
            ErrorAction = 'Stop'
        }
        New-GPLink @NewLinkParams | 
            Out-Null
        $Status = $true
        return @($Status, $ErrorString)
    }
    catch{
        # If caught, get the string
        $ErrorString = $_.ToString()
        return @($Status, $ErrorString)
    }
}
