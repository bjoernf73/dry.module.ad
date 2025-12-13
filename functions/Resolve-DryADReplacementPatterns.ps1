Using Namespace System.Collections.Generic
<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>

function Resolve-DryADReplacementPatterns{
    [CmdletBinding()]
    param(
        [Parameter(ParametersetName = "InputObject", Position = 0, Mandatory)]
        [PSCustomObject]$InputObject,

        [Parameter(ParametersetName = "InputText", Position = 0, Mandatory)]
        [AllowEmptyString()]
        [string]$InputText,

        [Parameter(ParametersetName = "InputObject", Position = 1, Mandatory)]
        [Parameter(ParametersetName = "InputText", Position = 1, Mandatory)]
        [List[PSObject]]$Variables
    )

    try{
        if(($InputObject -is [array]) -and $InputObject.count -eq 0){
            Return
        } 
        elseif($InputObject){
            # make a copy of the object, or else the changes 
            # may be written back to the original object
            $CopyObject = $InputObject.PSObject.Copy()
            # loop through all properties of $InputObject
            if($CopyObject -is [array]){
                $ResultArray = @()
                foreach($arrItem in $CopyObject){
                    $ResultArray += Resolve-DryADReplacementPatterns -InputObject $arrItem -Variables $Variables
                }
                $ResultArray
            }
            else{
                $CopyObject.PSObject.Properties | foreach-Object{
                    $PropertyName = $_.Name
                    $PropertyValue = $_.Value
                    # The pattern definitions themselves (common_variables and resource_variables), 
                    # may be sent to this function. Avoid replacing the pattern definitions themselves, 
                    # just return the original object
                    if($PropertyName -match "common_variables$"){
                        olad d "Skipping replacement for the common_variables object itself ($PropertyName)"
                    }
                    elseif($PropertyName -match "resource_variables$"){
                        olad d "Skipping replacement for the resource_variables object itself ($PropertyName)"
                    }
                    # If Key is a string, we can do the replacement. If it is an object, we must make a nested 
                    # call. If array, make nested call for each element of the array
                    elseif($PropertyValue -is [string]){
                        # call Resolve-DryADReplacementPattern that returns the replaced string
                        $PropertyValue = Resolve-DryADReplacementPattern -InputText $PropertyValue -Variables $Variables     
                    }
                    elseif($PropertyValue -is [PSObject]){
                        # make a nested call to this function
                        $PropertyValue = Resolve-DryADReplacementPatterns -InputObject $PropertyValue -Variables $Variables
                    } 
                    elseif($PropertyValue -is [array]){
                        # nested call for each array element
                        $PropertyValue = @(  $PropertyValue | foreach-Object{ 
                                if($_ -is [string]){
                                    Resolve-DryADReplacementPatterns -InputText $_ -Variables $Variables
                                } 
                                else{
                                    Resolve-DryADReplacementPatterns -InputObject $_ -Variables $Variables
                                }
                            })
                    }
                    # Set the value
                    $CopyObject."$PropertyName" = $PropertyValue
                }
                return $CopyObject
            }
        } 
        else{
            # Any property will eventually end up here 
            $InputText = Resolve-DryADReplacementPattern -InputText $InputText -Variables $Variables
            return $InputText
        }
    }
    catch{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
