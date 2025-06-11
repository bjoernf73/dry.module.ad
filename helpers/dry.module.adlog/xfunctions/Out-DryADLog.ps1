<#
.SYNOPSIS
A logging and output-to-display module for dry.module.ad

.DESCRIPTION
A logging and output-to-display module for dry.module.ad

.PARAMETER Type
Types follow Windows Streams, except for stream 6 - we use stream 1 (output) 
to make it easier for a tool like ansible to comprehend the output. 
    Type 'e' = Error
    Type 'w' = Warning
    Type 'v' = Verbose
    Type 'd' = Debug
    Type 'i' = Information

.PARAMETER Message
The text to display and/or log.

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
Out-DryADLog -Type i -Message "This is a type 6 (informational) message"

info:   This is a type i (informational) message
.EXAMPLE
Out-DryADLog i "This is a type 6 (informational) message"
        This is a type i (informational) message

.EXAMPLE
olad i "This is a type i (informational) message"
        This is a type i (informational) message

.EXAMPLE
olad v "This is a type v (verbose) message which won't display anything"

.EXAMPLE
olad v "This is a type v (verbose) message" -Verbose
VERBOSE:   This is a type v (verbose) message               [MyScript.ps1:245 14:25:57]

.EXAMPLE
olad v 'This is an','arrayed message' ; olad v 'And this is yet another','one'

VERBOSE:   This is an                       : arrayed message
VERBOSE:   And this is yet another          : one

.EXAMPLE
olad v "this is a small header" -sh                                                                                                                                                                       â”€â•¯
VERBOSE:    this is a small header   .............................................................

#>
function Out-DryADLog{
    [CmdletBinding(DefaultParameterSetName="message")]
    [Alias("olad")]
    param(
        [Alias("t")]
        [Parameter(Mandatory,Position=0)]
        [string]$Type,

        [Alias("m")]
        [Parameter(ParameterSetName="message",Mandatory,Position=1)]
        [AllowEmptyString()]
        [string]$Message,

        [Alias("arr")]
        [Parameter(ParameterSetName="array",Mandatory,Position=1,
        HelpMessage="The 'MsgArr' parameter set expects an array of 2 elements, for instance a name or description of a
        value of some kind, and the second element is the value. Out-DryADLog will add whitespaces to the first element
        until it reaches a length of `$ADLoggingOptions.array_first_element_length, which orders all second elements in
        a straight vertical line. So basically for readability of a pair")]
        [ValidateScript({"$($_.Count) -le 2"})]
        [array]$MsgArr,

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

    try{
        if($null -eq $GLOBAL:ADLoggingOptions){
            $GLOBAL:ADLoggingOptions = [PSCustomObject]@{
                log_to_file                = $false;
                path                       = &{ if($PSVersionTable.Platform -eq 'Unix'){ "$($env:HOME)/dry.module.ad/dry.module.ad.log" } else{ ("$($env:UserProfile)\dry.module.ad\dry.module.ad.log").Replace('\','\\')}};
                console_width_threshold    = 70;
                post_buffer                = 3;
                array_first_element_length = 45;
                verbose     = [PSCustomObject]@{ display_location = $true;  }
                debug       = [PSCustomObject]@{ display_location = $true;  }
                warning     = [PSCustomObject]@{ display_location = $true;  }
                information = [PSCustomObject]@{ display_location = $false; }
                error       = [PSCustomObject]@{ display_location = $true;  }
            }
        }
        $ADLoggingOptions = $GLOBAL:ADLoggingOptions

        if($ADLoggingOptions.log_to_file -eq $true){
            if($ADLoggingOptions.path){
                $LogFile = $ADLoggingOptions.path
                if(($GLOBAL:DoNotLogToFile -ne $true) -and (-not (Test-Path $LogFile))){
                    New-Item -ItemType File -Path $LogFile -Force -ErrorAction Continue | Out-Null
                }
            }
            else{
                throw "You must define ADLoggingOptions.path to log to file"
            }
        }
        else{
            $LogFile = $null
        }
        # Get the calling cmdlet/script and line number
        $Caller = (Get-PSCallStack)[$callstacklevel]
        [string] $Location = ($Caller.location).Replace(' line ','')
        [string] $LocationString = "[$Location $(get-date -Format HH:mm:ss)]"

        <#
            Windows Output Streams:
            1 OutPut/Success
            2 Error
            3 Warning
            4 Verbose
            5 Debug
            6 Information
        #>
        switch($Type){
           {$_ -in ('e','error')}{
                $Type = 'error'
                $TypeStringLength = 14  # "Out-DryADLog: "
            }
           {$_ -in ('w','warning')}{
                $Type = 'warning'
                $TypeStringLength = 9  # "WARNING: "
            }
           {$_ -in ('d','debug')}{
                $Type = 'debug'
                $TypeStringLength = 7  # "DEBUG: "
            }
           {$_ -in ('i','information','info')}{
                $Type = 'information'
                $TypeStringLength = 0
            }
            default{
                $Type = 'verbose'
                $TypeStringLength = 9
            }
        }

        if($ADLoggingOptions."$Type".display_location){
            $DisplayLocation = $ADLoggingOptions."$Type".display_location
        }  
        # determine the console width
        if($ADLoggingOptions.force_console_width){
            $ConsoleWidth = $ADLoggingOptions.force_console_width
        }
        else{
            $ConsoleWidth = $Host.UI.RawUI.WindowSize.Width
        }

        if($DisplayLocation){
            $TargetMessageLength = $ConsoleWidth - ($ADLoggingOptions.post_buffer + $LocationString.Length + $TypeStringLength)
        }
        else{
            $TargetMessageLength = $ConsoleWidth - ($ADLoggingOptions.post_buffer + $TypeStringLength)
        }

        if($Header){
            $HeaderLine,$Message = New-DryHeader -Message $Message -TargetMessageLength $TargetMessageLength -HeaderChars $HeaderChars -Air:$Air
        }
        elseif($SmallHeader){
            $Message = New-DryHeader -Message $Message -Small -TargetMessageLength $TargetMessageLength -HeaderChars $HeaderChars -Air:$Air
        }

        if($PSCmdlet.ParameterSetName -eq 'message'){
            # If $TargetMessageLength is greater than the $ADLoggingOptions.console_width_threshold, and
            # $Message is longer than $TargetMessageLength, we want to split the message
            # into chunks so they fit nicely in the console
            if(($TargetMessageLength -gt $ADLoggingOptions.console_width_threshold) -and
                ($Message.Length -gt $TargetMessageLength)){
                [array]$Messages = Split-DryString -Length $TargetMessageLength -String $Message
            }
            else{
                if($HeaderLine){
                    [array]$Messages += $HeaderLine
                }
                [array]$Messages += $Message
            }
        }
        elseif($PSCmdlet.ParameterSetName -eq 'array'){
            $FirstElement = $MsgArr[0]
            $SecondElement = $MsgArr[1]
            $BlankFirstElement = ''
            $ArrayMessages = $null
            $ArrayMessage = $null

            if($FirstElement.length -lt ($ADLoggingOptions.array_first_element_length + (14-$TypeStringLength))){
                do{
                    $FirstElement = "$FirstElement "
                }
                while ($FirstElement.length -lt ($ADLoggingOptions.array_first_element_length + (14-$TypeStringLength)))
            }
            
            if($BlankFirstElement.length -lt ($ADLoggingOptions.array_first_element_length + (14-$TypeStringLength))){
                do{
                    $BlankFirstElement = "$BlankFirstElement "
                }
                while ($BlankFirstElement.length -lt ($ADLoggingOptions.array_first_element_length + (14-$TypeStringLength)))
            }
            
            $ArrayMessage = "$($FirstElement): $($SecondElement)"
            
            if(($TargetMessageLength -gt $ADLoggingOptions.console_width_threshold) -and
                ($ArrayMessage.Length -gt $TargetMessageLength)){
                $ArrayMessages = $null
                [array]$ArrayMessages = Split-DryString -Length ($TargetMessageLength - ("$($FirstElement): ").length ) -String $SecondElement
                
                switch($ArrayMessages.count){
                   {$_ -eq 1 }{
                        [System.Collections.Generic.List[string]]$Messages = @("$($ArrayMessages[0])")
                    }
                   {$_ -gt 1 }{
                        [System.Collections.Generic.List[string]]$Messages = @("$($FirstElement): $($ArrayMessages[0])")
                        for ($m = 1; $m -le $ArrayMessages.count; $m++){
                            $Messages.Add("$($BlankFirstElement)  $($ArrayMessages[$m])")
                        }
                    }
                }
            }
            else{
                [System.Collections.Generic.List[string]]$Messages = @("$ArrayMessage")
            }                
        }
        foreach($MessageChunk in $Messages){
            if($MessageChunk.length -lt $TargetMessageLength){
                do{
                    $MessageChunk = "$MessageChunk "
                }
                while ($MessageChunk.length -lt $TargetMessageLength)
            }
            
            # Attach the pieces
            if($DisplayLocation){
                $FullMessageChunk = $MessageChunk + $LocationString
            }
            else{
                $FullMessageChunk = $MessageChunk
            }
            switch($Type){
                'information'{
                    Write-Output $FullMessageChunk
                }
                'verbose'{
                    if($PSBoundParameters.ContainsKey('Verbose') -or ($GLOBAL:VerbosePreference -eq 'Continue')){
                        $VerbosePreference = 'Continue'
                        Write-Verbose $FullMessageChunk
                    }
                }
                'debug'{
                    if($PSBoundParameters.ContainsKey('Debug') -or ($GLOBAL:DebugPreference -eq 'Continue')){
                        $DebugPreference = 'Continue'
                        Write-Debug $FullMessageChunk
                    }
                }
                'warning'{
                    Write-Warning $FullMessageChunk
                }
                'error'{
                    Write-Error $FullMessageChunk
                }
            }
        }

        # Log to file
        switch($ADLoggingOptions.log_to_file){
            $true{
                switch($PSCmdlet.ParameterSetName){
                    'message'{
                        if(-not $Header){
                            $LogMessage = "{0} `$$<{1}><{2}{3}><thread={4}>" -f ($Message), $Location, (Get-Date -Format "MM-dd-yyyy"), (Get-Date -Format "HH:mm:ss.ffffff"), $PID
                            $LogMessage | Out-File -Append -Encoding UTF8 -FilePath ("filesystem::{0}" -f $LogFile) -Force
                        }
                    }
                    'array'{
                        $LogMessage = "{0} `$$<{1}><{2}{3}><thread={4}>" -f ($MsgArr[0] + ' => ' + $MsgArr[1] ), $Location, (Get-Date -Format "MM-dd-yyyy"), (Get-Date -Format "HH:mm:ss.ffffff"), $PID
                        $LogMessage | Out-File -Append -Encoding UTF8 -FilePath ("filesystem::{0}" -f $LogFile) -Force
                    }
                }
            }
            default{
                # do nothing
            }
        }
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}