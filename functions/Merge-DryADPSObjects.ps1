<#  
    This is an AD Config module for use with DryDeploy, or by itself.
    Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
    LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
#>
function Merge-DryADPSObjects{
    [CmdLetBinding()]
    param(
        $FirstObject,
         
        $SecondObject,

        [Switch]$PreferSecondObjectOnConflict,

        [Switch]$FailOnConflict
    )
    try{
        # This will accumulate the result
        $Private:Resultobject = New-Object -TypeName psobject
        $Private:ProcessedConflictingPropertyNames = @()

        # is both are arrays, merge
        if(($FirstObject -is [array]) -and ($SecondObject -is [array])){
            $Private:ResultArray += $FirstObject
            $Private:ResultArray += $SecondObject
            return $Private:ResultArray 
        }
        elseif( ($FirstObject -is [string]) -and $SecondObject -is [string] ){
            # This happens when properties are identical in above iterations. By default, the property from 
            # $FirstObject is returned, unless the switch $PreferSecondObjectOnConflict is passed - then 
            # the property from $SecondObject is returned. In any case, if the switch $FailOnConflict, 
            # is passed, we throw an error
            if($FailOnConflict){
                throw "There was conflict (identical properties) and you passed -FailonConflict"
            }
            else{
                if($PreferSecondObjectOnConflict){
                    return $SecondObject
                } 
                else{
                    return $FirstObject
                }
            }
        }
        elseif( ($FirstObject -is [PSCustomObject]) -and $SecondObject -is [PSCustomObject] ){
            # Iterate through each object property of $FirstObject
            foreach($Property in $FirstObject | Get-Member -Type NoteProperty, Property){
                # does SecondObject have a matching node?
                if($null -eq $SecondObject.$($Property.Name)){
                    # $SecondObject does not contain the current property from $FirstObject, so 
                    # the property can be added to $Private:Resultobject as it is
                    $Private:Resultobject | Add-Member -MemberType $Property.MemberType -Name $Property.Name -Value $FirstObject.($Property.Name)
                }
                else{
                    # $SecondObject contains the current property from $FirstObject, so 
                    # the two must be merged. Call Merge-DryADPSObject
                    $Private:Resultobject | Add-Member $Property.MemberType -Name $Property.Name -Value ( Merge-DryADPSObjects -FirstObject ($FirstObject.$($Property.Name)) -SecondObject ($SecondObject.$($Property.Name)) -PreferSecondObjectOnConflict:$PreferSecondObjectOnConflict -FailOnConflict:$FailOnConflict)
                    $Private:ProcessedConflictingPropertyNames += $Property.Name
                }
            }

            # Members in $SecondObject that are not yet processed, has no 
            # match in $FirstObject, and may be added to the result as is
            foreach($Property in $SecondObject | Get-Member -type NoteProperty, Property){
                if($Private:ProcessedConflictingPropertyNames -notcontains $Property.Name){
                    olad d "Trying to add property '$($Property.Name)', type '$($Property.MemberType)', Value '$($SecondObject.($Property.Name))' "

                    $Private:Resultobject | Add-Member -MemberType $Property.MemberType -Name $Property.Name -Value $SecondObject.($Property.Name)
                }
                else{
                    olad d "Property '$($Property.Name)' is already processed"
                }
            }
            return $Private:Resultobject
        }
        else{
            olad e "FirstObject type: $($($FirstObject.Gettype()).Name) (Basetype: $($($FirstObject.Gettype()).BaseType))"
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    catch{
        $PSCmdLet.ThrowTerminatingError($_)
    }
}
