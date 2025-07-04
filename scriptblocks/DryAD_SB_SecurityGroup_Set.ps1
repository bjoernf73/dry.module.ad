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

[ScriptBlock] $DryAD_SB_SecurityGroup_Set ={ 
    param(
        $Name,
        $Path,
        $Description,
        $GroupCategory,
        $GroupScope,
        $Server
    )

    $ADRootDSE = Get-ADRootDSE 
    $DomainDN = $ADRootDSE.DefaultNamingContext
    
    # Add DomainDN to path if not already added
    if($Path -notmatch "$DomainDN$"){
        $Path = $Path + ",$DomainDN"
    }
    
    try{
        $NewADGroupParams = @{
            Name          = $Name 
            Path          = $Path 
            Description   = $Description 
            GroupCategory = $GroupCategory
            GroupScope    = $GroupScope
            Server        = $Server
            ErrorAction   = 'Stop'
        }
        New-ADGroup @NewADGroupParams | Out-Null
        $true
    }
    catch{
        $_
    }
}
