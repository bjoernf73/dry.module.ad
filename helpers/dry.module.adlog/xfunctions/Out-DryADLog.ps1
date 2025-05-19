<#
.SYNOPSIS
A logging and output-to-display module for dry.module.ad

.DESCRIPTION
A logging and output-to-display module for dry.module.ad

.PARAMETER Type
Types follow Windows Streams, except for stream 1 (output) which isn't
used. You may also use first letter of a stream name, so type 2 and 'e'
are both the error stream, type 3 and 'w' the warning, and so on.
    Type 2 or 'e' = Error
    Type 3 or 'w' = Warning
    Type 4 or 'v' = Verbose
    Type 5 or 'd' = Debug
    Type 6 or 'i' = Information

.PARAMETER Message
The text to display and/or log.

.PARAMETER MsgHash
A hashtable to display and/or log

.PARAMETER MsgArr
A two-element array; for instance a hashtable key and it's corresponding value.
Out-DryADLog will add whitespaces to the first element until it reaches a length
of `$ADLoggingOptions.array_first_element_length, which orders all second elements
in a straight vertical line. So basically for readability of a pair

.PARAMETER Header
Creates a line that seperates previous stuff from upcoming stuff, and then
displays the meader message, like:
..........................................................................
This is a normal header

.PARAMETER SmallHeader
Displays the header message, and then fills rest of the line with the header
chars, like

This is a small header  ..................................................

.PARAMETER Air
'Airs' the message in header or smallheader, converts 'Air' to 'A i r', like
..........................................................................
A i r e d   H e a d e r

.PARAMETER Callstacklevel
This function uses Get-PSCallstack to identify the location of the caller, i.e.
which function or script, and at what line, Out-DryADLog was called. For certain
types (see parameter Type above) the function will then display that location on
the far right of each displayed line. You may configure for which types the
calling location should be displayed in `$ADLoggingOptions. Anyway, if a function
or many functions call the same proxy function that in turn calls Out-DryADLog, it
may be more informative if the proxy function calls Out-DryADLog with '-Callstacklevel 2'.
The effect is that the Location is no longer the PS Callstack element number 1 (the
proxy function), but element number 2 (the function that called the proxy function)

.EXAMPLE
Out-DryADLog -Type 6 -Message "This is a type 6 (informational) message"

info:   This is a type 6 (informational) message
.EXAMPLE
Out-DryADLog 6 "This is a type 6 (informational) message"
        This is a type 6 (informational) message

.EXAMPLE
olad 6 "This is a type 6 (informational) message"
        This is a type 6 (informational) message

.EXAMPLE
olad 4 "This is a type 4 (verbose) message which won't display anything"


.EXAMPLE
olad 4 "This is a type 4 (verbose) message" -Verbose
verbose:   This is a type 4 (verbose) message               [MyScript.ps1:245 14:25:57]

.EXAMPLE
olad i 'This is an','arrayed message' ; olad i 'And this is yet another','one'

info:   This is an                       : arrayed message
info:   And this is yet another          : one

.EXAMPLE
olad i "this is a small header" -sh                                                                                                                                                                       ─╯
info:    this is a small header   .............................................................

.EXAMPLE
info:    .....................................................................................................................................................................................................
info:    this is a normal header

.EXAMPLE


#>
function Out-DryADLog {
    [CmdletBinding(DefaultParameterSetName="message")]
    [Alias("olad")]
    param (
        [Alias("t")]
        [Parameter(Mandatory,Position=0)]
        [string]$Type,

        [Alias("m")]
        [Parameter(ParameterSetName="message",Mandatory,Position=1)]
        [AllowEmptyString()]
        [string]$Message,

        [Alias("hash")]
        [Parameter(ParameterSetName="hashtable",Mandatory,Position=1)]
        [hashtable]$MsgHash,

        [Alias("arr")]
        [Parameter(ParameterSetName="array",Mandatory,Position=1,
        HelpMessage="The 'MsgArr' parameter set expects an array of 2 elements, for instance a name or description of a
        value of some kind, and the second element is the value. Out-DryADLog will add whitespaces to the first element
        until it reaches a length of `$ADLoggingOptions.array_first_element_length, which orders all second elements in
        a straight vertical line. So basically for readability of a pair")]
        [ValidateScript({"$($_.Count) -le 2"})]
        [array]$MsgArr,

        [Alias("obj")]
        [Parameter(ParameterSetName="object",Mandatory,Position=1,
        HelpMessage="Expects a very simple PSCustomObject with properties made up of strings, ints and bools. More 
        complex types will be ignored")]
        [PSCustomObject]$MsgObj,

        [Alias("title")]
        [Parameter(ParameterSetName="hashtable",HelpMessage="Title of the Hashtable to display")]
        [Parameter(ParameterSetName="object",HelpMessage="Title of the PSCustomObject to display")]
        [string]$MsgTitle,

        [Parameter(ParameterSetName="object", HelpMessage="Don't use this param. It is only for use in nested calls. 
        Meaning that the MsgObjLevel will be increased by 1 each time Out-DryADLog parameterset 'object' calls itself")]
        [int]$MsgObjLevel = 1,

        [Alias("h")]
        [Parameter(ParameterSetName="message",HelpMessage="Creates a nice header of the message text")]
        [Switch]$Header,

        [Alias("hchar")]
        [Parameter(ParameterSetName="message",HelpMessage="The char(s) to fill the line")]
        [string]$HeaderChars = '.',

        [Alias("sh")]
        [Parameter(ParameterSetName="message",HelpMessage="Creates a nice, small header of the message text")]
        [Switch]$SmallHeader,

        [Alias("a")]
        [Parameter(ParameterSetName="message",HelpMessage="If -Header or -SmallHeader, converts 'Message' to 'M e s s a g e'")]
        [Switch]$Air,

        [Alias("cs")]
        [Parameter(HelpMessage="Normally 1, the direct caller. However, if Out-DryADLog is called by a proxy function, you may use
        2 to point the 'location' (where in your code Out-DryADLog was called) to the call before the direct call.")]
        [int]$Callstacklevel = 1
    )

    try {
        if ($null -eq $GLOBAL:ADLoggingOptions) {
            $GLOBAL:ADLoggingOptions = [PSCustomObject]@{
                log_to_file                = $false;
                path                       = & { if ($PSVersionTable.Platform -eq 'Unix') { "$($env:HOME)/dry.module.ad/dry.module.ad.log" } else { ("$($env:UserProfile)\dry.module.ad\dry.module.ad.log").Replace('\','\\')}};
                console_width_threshold    = 70;
                post_buffer                = 2;
                array_first_element_length = 45;
                verbose     = [PSCustomObject]@{ foreground_color = 'Yellow';     background_color = $null; display_location = $true;  text_type = 'verbose:' }
                debug       = [PSCustomObject]@{ foreground_color = 'DarkYellow'; background_color = $null; display_location = $true;  text_type = 'debug:  ' }
                warning     = [PSCustomObject]@{ foreground_color = 'Yellow';     background_color = $null; display_location = $true;  text_type = 'warning:' }
                information = [PSCustomObject]@{ foreground_color = 'White';      background_color = $null; display_location = $false; text_type = 'info:   ' }
                error       = [PSCustomObject]@{ foreground_color = 'Red';        background_color = $null; display_location = $true;  text_type = 'error:  ' }
                input       = [PSCustomObject]@{ foreground_color = 'Blue';       background_color = $null; display_location = $true;  text_type = 'input:  ' }
                success     = [PSCustomObject]@{ foreground_color = 'Green';      background_color = $null; display_location = $false; text_type = 'success:' ;  status_text = 'Success'}
                fail        = [PSCustomObject]@{ foreground_color = 'Red';        background_color = $null; display_location = $false; text_type = 'fail:   ' ;  status_text = 'Fail'   }
            }
        }
        $ADLoggingOptions = $GLOBAL:ADLoggingOptions

        if ($ADLoggingOptions.log_to_file -eq $true) {
            if ($ADLoggingOptions.path) {
                $LogFile = $ADLoggingOptions.path
                if (($GLOBAL:DoNotLogToFile -ne $true) -and (-not (Test-Path $LogFile))) {
                    New-Item -ItemType File -Path $LogFile -Force -ErrorAction Continue | Out-Null
                }
            }
            else {
                throw "You must define ADLoggingOptions.path to log to file"
            }
        }
        else {
            $LogFile = $null
        }
        # Get the calling cmdlet/script and line number
        $Caller = (Get-PSCallStack)[$callstacklevel]
        [string] $Location = ($Caller.location).Replace(' line ','')
        [string] $LocationString = "[$Location $(get-date -Format HH:mm:ss)]"

        <#
            Windows Output Streams:
            1 OutPut/Success - not in use here
            2 Error
            3 Warning
            4 Verbose
            5 Debug
            6 Information
        #>
        $DisplayLogMessage = $true
        switch ($Type) {
            {$_ -in ('2','e','error')} {
                $Type = 'error'
            }
            {$_ -in ('3','w','warning')} {
                $Type = 'warning'
            }
            {$_ -in ('5','d','debug')} {
                $Type = 'debug'
                if ($PSBoundParameters.ContainsKey('Debug') -or 
                    ($PSCmdlet.GetVariableValue('DebugPreference') -eq 'Continue')) {
                }
                else {
                    $DisplayLogMessage = $false
                }
            }
            {$_ -in ('6','i','information','info')} {
                $Type = 'information'
            }
            {$_ -in ('s','success')} {
                $Type = 'success'
                $StatusText = $ADLoggingOptions."$Type".status_text
                $DisplayLogMessage = $false
            }
            {$_ -in ('f','fail','failed')} {
                $Type = 'fail'
                $StatusText = $ADLoggingOptions."$Type".status_text
                $DisplayLogMessage = $false
            }
            default {
                $Type = 'verbose'
                if ($PSBoundParameters.ContainsKey('Verbose') -or 
                    ($PSCmdlet.GetVariableValue('VerbosePreference') -eq 'Continue')) {
                }
                else {
                    $DisplayLogMessage = $false
                }
            }
        }

        if ($ADLoggingOptions."$Type".text_type) {
            $TextType = $ADLoggingOptions."$Type".text_type
        }
        if ($ADLoggingOptions."$Type".foreground_color) {
            $LOFore   = $ADLoggingOptions."$Type".foreground_color
        }
        if ($ADLoggingOptions."$Type".background_color) {
            $LOBack   = $ADLoggingOptions."$Type".background_color
        }
        if ($ADLoggingOptions."$Type".display_location) {
            $DisplayLocation = $ADLoggingOptions."$Type".display_location
        }

        [hashtable]$LogColors = @{}
        if ($null -ne $LOFore) {
            $LogColors += @{foregroundcolor = $LOFore}
        }
        if ($null -ne $LOBack) {
            $LogColors += @{backgroundcolor = $LOBack}
        }
            
        if ($DisplayLogMessage) {
            $StartOfMessage = $TextType + ' '
            # determine the console width
            if ($ADLoggingOptions.force_console_width) {
                $ConsoleWidth = $ADLoggingOptions.force_console_width
            }
            else {
                $ConsoleWidth = $Host.UI.RawUI.WindowSize.Width
            }

            if ($DisplayLocation) {
                $TargetMessageLength = $ConsoleWidth - ($ADLoggingOptions.post_buffer + $StartOfMessage.Length + $LocationString.Length)
            }
            else {
                $TargetMessageLength = $ConsoleWidth - ($ADLoggingOptions.post_buffer + $StartOfMessage.Length)
            }

            if ($Header) {
                # New-DryHeader will call Out-DryADLog back after making a header
                $HeaderLine,$Message = New-DryHeader -Message $Message -TargetMessageLength $TargetMessageLength -HeaderChars $HeaderChars -Air:$Air
            }
            elseif ($SmallHeader) {
                $Message = New-DryHeader -Message $Message -Small -TargetMessageLength $TargetMessageLength -HeaderChars $HeaderChars -Air:$Air
            }

            if ($PSCmdlet.ParameterSetName -eq 'message') {
                if ($Type -in @('success','fail')) {
                    do {
                        $StatusText = "$StatusText "
                    }
                    while ($StatusText.length -le $ADLoggingOptions.array_first_element_length)
                    $Messages = @("$StatusText`: $Message")
                }
                # If $TargetMessageLength is greater than the $ADLoggingOptions.console_width_threshold, and
                # $Message is longer than $TargetMessageLength, we want to split the message
                # into chunks so they fit nicely in the console
                elseif (
                    ($TargetMessageLength -gt $ADLoggingOptions.console_width_threshold) -and
                    ($Message.Length -gt $TargetMessageLength)
                ) {
                    [array]$Messages = Split-DryString -Length $TargetMessageLength -String $Message
                }
                else {
                    if ($HeaderLine) {
                        [array]$Messages += $HeaderLine
                    }
                    [array]$Messages += $Message
                }
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'hashtable') {
                # hashtable - loop through all key-value pairs
                if ($MsgTitle) {
                    $NestedOutDryLogCallParams += @{
                        Message         = "$MsgTitle"
                        Type            = $Type
                        Callstacklevel  = $($Callstacklevel + 1) 
                        Smallheader     = $true
                    }
                    Out-DryADLog @NestedOutDryLogCallParams
                }
                $Messages = @()
                foreach ($Key in $MsgHash.Keys) {
                    Remove-Variable -Name ThisValue -ErrorAction Ignore
                    if ($($MsgHash[$Key]) -is [PSCredential]) {
                        $ThisValue = ($MsgHash[$Key]).UserName
                    }
                    else {
                        if ($Key -match "password") {
                            do {
                                $ThisValue = "$ThisValue*"
                            }
                            until ($ThisValue.Length -ge ($MsgHash[$Key]).Length)
                        }
                        else {
                            $ThisValue = $MsgHash[$Key]
                        }
                    }
                    $Messages += "'$Key'='$ThisValue'"
                }
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'array') {
                $FirstElement = $MsgArr[0]
                $SecondElement = $MsgArr[1]
                $BlankFirstElement = ''
                $ArrayMessages = $null
                $ArrayMessage = $null

                do {
                    $FirstElement = "$FirstElement "
                }
                while ($FirstElement.length -le $ADLoggingOptions.array_first_element_length)
                do {
                    $BlankFirstElement = "$BlankFirstElement "
                }
                while ($BlankFirstElement.length -le $ADLoggingOptions.array_first_element_length)
                $ArrayMessage = "$($FirstElement): $($SecondElement)"
                
                if (($TargetMessageLength -gt $ADLoggingOptions.console_width_threshold) -and
                    ($ArrayMessage.Length -gt $TargetMessageLength)) {
                    $ArrayMessages = $null
                    [array]$ArrayMessages = Split-DryString -Length ($TargetMessageLength - ("$($FirstElement): ").length ) -String $SecondElement
                    
                    switch ($ArrayMessages.count) {
                        {$_ -eq 1 } {
                            [System.Collections.Generic.List[string]]$Messages = @("$($ArrayMessages[0])")
                        }
                        {$_ -gt 1 } {
                            [System.Collections.Generic.List[string]]$Messages = @("$($FirstElement): $($ArrayMessages[0])")
                            for ($m = 1; $m -le $ArrayMessages.count; $m++) {
                                $Messages.Add("$($BlankFirstElement)  $($ArrayMessages[$m])")
                            }
                        }
                    }
                }
                else {
                    [System.Collections.Generic.List[string]]$Messages = @("$ArrayMessage")
                }                
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'object') {
                # The header (name of object)
                if ($MsgTitle) {
                    $NestedOutDryLogCallParams += @{
                        Message         = "$MsgTitle"
                        Type            = $Type
                        Callstacklevel  = $($Callstacklevel + 1) 
                        Smallheader     = $true
                    }
                    Out-DryADLog @NestedOutDryLogCallParams
                }

                # Iterate through properties
                $MsgObj.PSObject.Properties | foreach-Object {
                    if ($null -eq $_.Value) { $_.Value = '(null)'}
                    if (($_.Value -is [string]) -or ($_.Value -is [bool]) -or (($_.Value).Gettype().Name -match 'byte|short|int32|long|sbyte|ushort|uint32|ulong|float|double|decimal|Version')) {
                        $NestedOutDryLogCallParams = @{
                            Type            = $Type
                            MsgArr          = @(($(' '*$MsgObjLevel + ' ') + ($_.Name)),$_.Value) 
                            Callstacklevel  = $Callstacklevel+1
                        }
                        Out-DryADLog @NestedOutDryLogCallParams
                    }
                    elseif ($_.Value -is [array]) {
                        $ObjValue = $_.Value
                        $ObjName = $_.Name
                        $NestedOutDryLogCallParams = @{
                            Type            = $Type
                            Message         = ($(' '*$MsgObjLevel+ ' ') + "$ObjName") 
                            Callstacklevel  = $Callstacklevel+1
                        }
                        Out-DryADLog @NestedOutDryLogCallParams  
                        foreach ($ObjItem in $ObjValue) {
                            if (($ObjItem -is [string]) -or ($ObjItem -is [bool]) -or ($ObjItem.Gettype().Name -match 'byte|short|int32|long|sbyte|ushort|uint32|ulong|float|double|decimal|Version')) {
                                $NestedOutDryLogCallParams = @{
                                    Type            = $Type
                                    Message         = ($('  '*$MsgObjLevel+ ' ') + "$ObjItem")
                                    Callstacklevel  = $Callstacklevel+1
                                }
                                Out-DryADLog @NestedOutDryLogCallParams
                            }
                            elseif ($ObjItem -is [PSCustomObject]) {
                                $NestedOutDryLogCallParams = @{
                                    Type            = $Type
                                    MsgObj          = $ObjItem 
                                    Callstacklevel  = $Callstacklevel+1
                                    MsgObjLevel     = $MsgObjLevel+1
                                }
                                Out-DryADLog @NestedOutDryLogCallParams
                            }
                        }
                    } 
                    elseif ($_.Value -is [PSCustomObject]) {
                        $NestedOutDryLogCallParams = @{
                            Type            = $Type
                            MsgObj          = $_.Name 
                            Callstacklevel  = $Callstacklevel+1
                            MsgObjLevel     = $MsgObjLevel+1
                        }
                        Out-DryADLog @NestedOutDryLogCallParams
                        Out-DryADLog -Type $Type -MsgObj $_.Name -Callstacklevel $($Callstacklevel+1) -MsgObjLevel $($MsgObjLevel+1)
                        Out-DryADLog -Type $Type -MsgObj $_.Value -Callstacklevel $($Callstacklevel+1) -MsgObjLevel $($MsgObjLevel+1)
                    }
                }
            }

            foreach ($MessageChunk in $Messages) {
                do {
                    $MessageChunk = "$MessageChunk "
                }
                while ($MessageChunk.length -le $TargetMessageLength)

                # Attach the pieces
                if ($DisplayLocation) {
                    $FullMessageChunk = $StartOfMessage + $MessageChunk + $LocationString
                }
                else {
                    $FullMessageChunk = $StartOfMessage + $MessageChunk
                }
                if ($LogColors) {
                    Write-Host @LogColors -Object $FullMessageChunk
                }
                else {
                    Write-Host -Object $FullMessageChunk
                }
            }
        }

        # Log to file
        switch ($ADLoggingOptions.log_to_file) {
            $true {
                switch ($PSCmdlet.ParameterSetName) {
                    'message' {
                        if (-not $Header) {
                            $LogMessage = "{0} `$$<{1}><{2} {3}><thread={4}>" -f ($StartOfMessage + ": " + $Message), $Location, (Get-Date -Format "MM-dd-yyyy"), (Get-Date -Format "HH:mm:ss.ffffff"), $PID
                            $LogMessage | Out-File -Append -Encoding UTF8 -FilePath ("filesystem::{0}" -f $LogFile) -Force
                        }
                    }
                    'hashtable' {
                        foreach ($Key in $MsgHash.Keys) {
                            $LogMessage = "{0} `$$<{1}><{2} {3}><thread={4}>" -f ($StartOfMessage + ": " + $Key + '=' + $MsgHash[$Key] ), $Location, (Get-Date -Format "MM-dd-yyyy"), (Get-Date -Format "HH:mm:ss.ffffff"), $PID
                            $LogMessage | Out-File -Append -Encoding UTF8 -FilePath ("filesystem::{0}" -f $LogFile) -Force
                        }
                    }
                    'array' {
                        $LogMessage = "{0} `$$<{1}><{2} {3}><thread={4}>" -f ($StartOfMessage + ": " + $MsgArr[0] + ' => ' + $MsgArr[1] ), $Location, (Get-Date -Format "MM-dd-yyyy"), (Get-Date -Format "HH:mm:ss.ffffff"), $PID
                        $LogMessage | Out-File -Append -Encoding UTF8 -FilePath ("filesystem::{0}" -f $LogFile) -Force
                    }
                }
            }
            default {
                # do nothing
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}