Using Namespace System.Management.Automation.Runspaces
Using Namespace System.Collections.Generic
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Set-DryADSchemaExtension{
    [CmdletBinding(DefaultParameterSetName = 'Local')] 
    param(
        [Parameter(Mandatory, HelpMessage = 'The Schema Extension type')]
        [string]
        $Type,

        [Parameter(Mandatory, HelpMessage = 'The number of times the success strings
        must be matched')]
        [int]
        $SuccessCount,

        [Parameter(Mandatory, HelpMessage = 'The LDF Content')]
        [string]
        $Content,

        [Parameter(HelpMessage = 'Variables used for replacements in LDFs. Each 
        `$var.name will be wrapped in trippel hashes (###$($var.name)###) and
        any match replaced with $var.value')]
        [List[PSObject]]
        $Variables,

        [Parameter(Mandatory, ParameterSetName = 'Remote', HelpMessage = "PSSession 
        to run the script blocks in")]
        [PSSession] 
        $PSSession,

        [Parameter(Mandatory, HelpMessage = "The Schema Master")]
        [string] 
        $SchemaMaster
    )
    try{
        olad v @('Execution Type', "$($PSCmdlet.ParameterSetName)")

        $SuccessStrings = @(
            'Entry modified successfully.',
            'Entry already exists, entry skipped',
            'Attribute or value exists, entry skipped.',
            'The command has completed successfully'
        )

        # Loop through variables and replace patterns in LDF Content
        if($Variables){
            foreach($Var in $Variables){
                $Content = $Content -Replace "###$($Var.Name)###", "$($Var.Value)"
            }
        }

        # Trim start of each line
        $Content = ($Content -Split "`n" | foreach-Object{ $_.TrimStart() } ) -join "`n"

        $ExtendSchemaArgumentList = @(
            $Content,
            $SchemaMaster
        )
        $InvokeSchemaExtensionParams = @{
            ScriptBlock  = $DryAD_SB_SchemaExtension_Set
            ArgumentList = $ExtendSchemaArgumentList
            ErrorAction  = 'Stop'
        }
        if($PSCmdlet.ParameterSetName -eq 'Remote'){
            $InvokeSchemaExtensionParams += @{
                Session = $PSSession
            }
        }
        $ExtendSchemaResult = Invoke-Command @InvokeSchemaExtensionParams
        
        if($ExtendSchemaResult[0] -eq ''){
            $MatchCount = 0
            $ExtendSchemaResult[1].foreach({ 
                    $CurrentString = $_; 
                    $SuccessStrings.foreach({ 
                            if($CurrentString -Match $_){ 
                                $MatchCount++
                            } 
                        })
                })
            if($MatchCount -eq $SuccessCount){
                olad d "AD Schema is extended"
                olad v @('Successfully extended AD Schema of Type', $Type)
            }
            else{
                olad w @("Target successcount $SuccessCount, actual", "$MatchCount")
                # Display thesult in debug
                $ExtendSchemaResult[1].foreach({
                        olad d $_
                    })
                throw "Schema extension failed"
            }
        }
        else{
            olad e "Schema extension failed"
            throw $ExtendSchemaResult[0]
        }  
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
