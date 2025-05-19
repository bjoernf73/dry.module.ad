function Split-DryString {
    param(
        [Parameter(Mandatory,HelpMessage="The string to split into lines of a certain maximum length")]
        [ValidateNotNullOrEmpty()]
        [string]$String,

        [Parameter(Mandatory,HelpMessage="The function will split `$String into an array of strings, or
        lines, of maximum length `$Length. They may be shorter - see description of paramameter
        `$WhiteSpaceAtEndChars below")]
        [ValidateScript({"$_ -gt 1"})]
        [int]$Length,

        [Parameter(HelpMessage="In order not to split a sentence in the middle of a word, the function
        will search the last 10 by default (or the number of `$WhiteSpaceAtEndChars) chars of each line, 
        for a whitespace. If a whitespace is found within those chars, it will split at the whitespace 
        instead of exactly at `$Length")]
        [int]$WhiteSpaceAtEndChars = 10
    )

    $Lines = @()
    $i = 0

    # Replace tabs with whitespace
    $String = $String.Replace("`t"," ")

    while($i -le ($String.length-$Length)){
        $Line = $String.Substring($i,$Length)
        # Search for the last whitespace in the $WhiteSpaceAtEndChars number of
        # characters at the end of each line. But only if all of the following
        # conditions are met:
        #  - the line is of the full length (not shorter)
        #  - the charachter following the line is not a whitespace
        #  - the last character of the line is not a whitespace
        # If such a whitespace is found, we split at that instead
        if($String.Length -gt ($i+$Line.Length+1)){
            if(
                ($Line.Length -eq $Length) -and 
                ($String.Substring($i+$Line.Length,1) -ne ' ') -and 
                ($Line.Substring($Line.Length-1) -ne ' ')
            ){
                $LastWhiteSpace = ($Line.Substring($Line.Length-$WhiteSpaceAtEndChars)).LastIndexOf(' ')
                if ($LastWhiteSpace -ge 0){
                    $cutindex = $WhiteSpaceAtEndChars - ($LastWhiteSpace+1)
                    $Lines += ($String.Substring($i,$Length-$cutindex)).Trim()
                    $i += $Length-$cutindex
                }
                else {
                    # No Whitespace found
                    $Lines += ($String.Substring($i,$Length)).Trim()
                    $i += $Length
                }
            }
            else {
                # Just add to $Lines and add $Length to $i
                $Lines += ($String.Substring($i,$Length)).Trim()
                $i += $Length
            }
        }
        else {
            $Lines += ($String.Substring($i,$Length)).Trim()
            $i += $Length
        }
    }
    if(($String.Substring($i)).Trim() -ne ''){
        $Lines += $String.Substring($i)
    }
    $Lines
}