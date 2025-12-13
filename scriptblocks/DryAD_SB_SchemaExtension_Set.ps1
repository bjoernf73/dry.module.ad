<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

[ScriptBlock]$DryAD_SB_SchemaExtension_Set ={
    param(
        $LDFContent,
        $SchemaMaster
    )
    try{
        $LDFFilePath = Join-Path -Path $ENV:LOCALAPPDATA -ChildPath 'LdfContent.ldf' -ErrorAction Stop
        $LDFContent | Out-File -FilePath $LDFFilePath -Encoding ASCII -Force -ErrorAction Stop
        $LdifdeResult = & ldifde -i -k -s "$SchemaMaster" -f "$LDFFilePath" -v
        return @('', $LdifdeResult)
    }
    catch{
        return @($_.ToString(), $LdifdeResult)
    }
    finally{
        Remove-Item -Path $LDFFilePath -Force -ErrorAction Ignore
        @('LDFFilePath', 'LDFContent', 'LdifdeResult').foreach({
            Remove-Variable -Name $_ -ErrorAction Ignore
        })
    } 
}
