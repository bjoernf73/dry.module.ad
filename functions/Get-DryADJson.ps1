<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Get-DryADJson{
    [CmdletBinding()]
    param(
        [ValidateScript({ (Test-Path $_ -PathType 'leaf') -and (($_ -match ".json$") -or ($_ -match ".jsonc$")) })]
        [Parameter(Mandatory, ParameterSetName = 'stringpath')]
        [string]$Path,

        [ValidateScript({ ($_.exists -and (($_.name -match ".json$") -or ($_.name -match ".jsonc$"))) })]
        [Parameter(Mandatory, ParameterSetName = 'fileinfo')]
        [System.IO.FileInfo]$File
    )
    try{
        if($Path){
            [System.IO.FileInfo]$Item = Get-Item -Path $Path -ErrorAction Stop
        }
        else{
            [System.IO.FileInfo]$Item = $File
        }
        
        # Get all lines that does not start with comment, i.e "//"
        [array]$ContentArray = Get-Content -Path $Item -ErrorAction Stop | Where-Object{ 
            $_.Trim() -notmatch "^//" 
        }

        [string]$ContentString = $ContentArray | Out-String -ErrorAction 'Stop'

        # Convert to PSObject and return
        ConvertFrom-Json -InputObject $ContentString -ErrorAction 'Stop'
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
