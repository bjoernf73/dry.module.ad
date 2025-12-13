Using NameSpace System.Management.Automation
Using NameSpace System.Management.Automation.Runspaces
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Copy-DryADFilesToRemoteTarget{
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param(
        [Parameter(Mandatory)]
        [string]
        $TargetPath,

        [Parameter(Mandatory)]
        [string]
        $SourcePath,

        [Parameter(Mandatory, ParameterSetName = 'Remote')]
        [PSSession]
        $PSSession
    )
    
    try{
        olad v @('Copy Type', "$($PSCmdlet.ParameterSetName)")
        olad v @('Source Path', "$SourcePath")
        olad v @('Target Path', "$TargetPath")
        # The PS Progress Bar is astonsishingly uninformative when copying multiple small 
        # files - suppress, and bring it back to the original $ProgressPreference in Finally  
        $OriginalProgressPreference = $ProgressPreference
        
        # Remove any double backslashes and wildcards from target
        while ($TargetPath -match '\\\\'){
            $TargetPath = $TargetPath -Replace '\\\\', '\'
        }
        $TargetPathTrimmed = $TargetPath.TrimEnd('*')
        $TargetPathTrimmed = $TargetPathTrimmed.TrimEnd('\')
        $TargetPathTrimmed = $TargetPathTrimmed + '\'
        olad v @('Trimmed Target Path', "$TargetPathTrimmed")
        
        # Remove any double backslashes and wildcards from source
        while ($SourcePath -match '\\\\'){
            $SourcePath = $SourcePath -Replace '\\\\', '\'
        }
        $SourcePathTrimmed = $SourcePath.TrimEnd('*')
        $SourcePathTrimmed = $SourcePathTrimmed.TrimEnd('\')
        $SourcePathTrimmed = $SourcePathTrimmed + ('\')
        olad v @('Trimmed Source Path', "$SourcePathTrimmed")

        # Make sure the root folder exists. Copy-Item is deviously unpredictable
        $TargetDirectory = $TargetPathTrimmed.Trim('\')
        olad v @('Trying to create directory', $TargetDirectory)
        $InvokeCommandParams = @{
            ScriptBlock  = $DryAD_SB_CreateDir
            ArgumentList = @($TargetDirectory)
        }
        if($PSSession){
            $InvokeCommandParams += @{
                Session = $PSSession
            }
        }

        $Result = Invoke-Command @InvokeCommandParams
        switch($Result){
            $true{
                olad v @('Successfully created directory', $TargetDirectory)
            }
           { $Result -is [ErrorRecord] }{
                $PSCmdlet.ThrowTerminatingError($Result)
            }
            default{
                throw "Failed to create directory '$TargetDirectory'", $Result.ToString()
            }
        }

        <#
        $SourceDirectories = Get-ChildItem -Path $SourcePathTrimmed -Recurse -Directory -ErrorAction Stop
        foreach($SourceDirectory in $SourceDirectories){
            $TargetDirectory = $TargetPathTrimmed + $($SourceDirectory.FullName).SubString($SourcePathTrimmed.Length)
            olad d @('Trying to create directory', $TargetDirectory)
            
            $InvokeCommandParams = @{
                ScriptBlock  = $DryAD_SB_CreateDir
                ArgumentList = @($TargetDirectory)
            }
            if($PSSession){
                $InvokeCommandParams += @{
                    Session = $PSSession
                }
            }

            $Result = Invoke-Command @InvokeCommandParams
            switch($Result){
                $true{
                    olad v @('Successfully created directory', $TargetDirectory)
                }
               { $Result -is [ErrorRecord] }{
                    $PSCmdlet.ThrowTerminatingError($Result)
                }
                default{
                    throw "Failed to create directory '$TargetDirectory'", $Result.ToString()
                }
            }
        }
        #>
        
        $ProgressPreference = 'SilentlyContinue'
        $CopyItemParams = @{
            Path        = $SourcePathTrimmed
            Destination = $TargetPathTrimmed
            Recurse     = $true
            Container   = $true
            Force       = $true
            ErrorAction = 'Stop'
        }
        if($PSSession){
            $CopyItemParams += @{
                ToSession = $PSSession
            }
        }
         
        Copy-Item @CopyItemParams
        olad v @('Successfully copied files to directory', $TargetPathTrimmed)
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally{
        $ProgressPreference = $OriginalProgressPreference
        
        @('TargetPath',
            'TargetPathTrimmed',
            'SourcePath',
            'SourcePathTrimmed',
            'SourceDirectories',
            'TargetDirectory',
            'InvokeCommandParams',
            'Result',
            'CopyItemParams'
        ).foreach({ Remove-Variable -Name $_ -ErrorAction 'Ignore' })
    }
}
