<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_WMIFilter_Set ={
    param(
        $Name,
        $Description,
        $Query,
        $Server
    )
    try{
        $ADRootDSE = Get-ADRootDSE -Server $Server -ErrorAction Stop
        $DomainDN = $ADRootDSE.DefaultNamingContext
        $WMIPath = ("CN=SOM,CN=WMIPolicy,CN=System,$DomainDN")
        $Guid = [System.Guid]::NewGuid()
        $msWMICreationDate = (Get-Date).ToUniversalTime().ToString("yyyyMMddhhmmss.ffffff-000")
        $msWMIAuthor = $(& whoami)
        $WMIGUID = "{$Guid}"
        $WMIDistinguishedName = "CN=$WMIGUID,$WMIPath"
        $msWMIParm1 = "$Description " # Fails if empty, therefore the space at the end...
        $msWMIParm2 = $Query.Count.ToString() + ";"
        $Query | foreach-Object{
            $msWMIParm2 += "3;10;" + $_.Length + ";WQL;root\CIMv2;" + $_ + ";"
        }

        $Attributes = @{
            'msWMI-Name'             = $Name
            'msWMI-Parm1'            = $msWMIParm1
            'msWMI-Parm2'            = $msWMIParm2
            'msWMI-Author'           = $msWMIAuthor
            'msWMI-ID'               = $WMIGUID
            'instanceType'           = 4
            'showInAdvancedViewOnly' = 'TRUE'
            'distinguishedname'      = $WMIDistinguishedName
            'msWMI-ChangeDate'       = $msWMICreationDate 
            'msWMI-CreationDate'     = $msWMICreationDate
        }
    
        $NewADObjectParams = @{
            Name            = $WMIGUID  
            Type            = 'msWMI-Som' 
            Path            = $WMIPath 
            OtherAttributes = $Attributes 
            Server          = $Server
            ErrorAction     = 'Stop'
        }
        New-ADObject @NewADObjectParams
        $true
    }
    catch{
        $_
    }
}
