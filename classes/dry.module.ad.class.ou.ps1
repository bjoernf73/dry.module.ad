Using Namespace System.Management.Automation.Runspaces
# removed: 
# Using Module ActiveDirectory
# dry.module.ad is an AD config module for use with DryDeploy, or by itself.
#
# Copyright (C) 2021  Bjørn Henrik Formo (bjornhenrikformo@gmail.com)
# LICENSE: https://raw.githubusercontent.com/bjoernf73/dry.module.ad/main/LICENSE
# 
Class OU{
    [string]       $OUDN
    [string]       $ObjectType
    [string]       $DomainFQDN
    [string]       $DomainDN
    [PSSession]    $PSSession
    [string]       $DomainController
    [PSCredential] $Credential
    [string]       $ExecutionType

    # Overload for CN or OU creation in a PSSession
    OU(
        [string]    $OUDN,
        [string]    $DomainFQDN,
        [PSSession] $PSSession
    )
   {
        $This.OUDN = $OUDN
        if($This.OUDN -match "^CN=*"){
            $This.ObjectType   = 'container' 
        }
        elseif($This.OUDN -match "^OU=*"){
            $This.ObjectType   = 'organizationalUnit' 
        }
        elseif($This.OUDN.Trim() -eq ''){
            $This.ObjectType   = 'DomainRoot' 
        }
        else{ 
            olad e "Unknown Object Type (not CN, OU or Domain Root): $($This.OUDN)"
            throw "Unknown Object Type (not CN, OU) or Domain Root: $($This.OUDN)"
        }  
        $This.DomainFQDN       = $DomainFQDN 
        $This.DomainDN         = "DC=" + $($This.DomainFQDN.replace(".",",DC="))
        $This.PSSession        = $PSSession
        $This.ExecutionType    = 'Remote'
        $This.DomainController = 'localhost'
    } 

    # Overload for CN or OU creation locally with PSCredential
    OU(
        [string]       $OUDN,
        [string]       $DomainFQDN,
        [string]       $DomainController,
        [PSCredential] $Credential
    )
   {
        $This.OUDN = $OUDN
        if($This.OUDN -match "^CN=*"){
            $This.ObjectType   = 'container' 
        }
        elseif($This.OUDN -match "^OU=*"){
            $This.ObjectType   = 'organizationalUnit' 
        }
        elseif($This.OUDN.Trim() -eq ''){
            $This.ObjectType   = 'DomainRoot' 
        }
        else{ 
            olad w "Unknown Object Type (not CN or OU): $($This.OUDN)"
            throw "Unknown Object Type (not CN or OU): $($This.OUDN)"
        } 
        $This.DomainFQDN       = $DomainFQDN 
        $This.DomainDN         = "DC=" + $($This.DomainFQDN.replace(".",",DC="))
        $This.Credential       = $Credential
        $This.ExecutionType    = 'Local'
        $This.DomainController = $DomainController
    } 

    # Overload for CN or OU creation locally using privileges of the executing user
    OU(
        [string]       $OUDN,
        [string]       $DomainFQDN,
        [string]       $DomainController
    )
   {
        $This.OUDN = $OUDN
        if($This.OUDN -match "^CN=*"){
            $This.ObjectType   = 'container' 
        }
        elseif($This.OUDN -match "^OU=*"){
            $This.ObjectType   = 'organizationalUnit' 
        }
        elseif($This.OUDN.Trim() -eq ''){
            $This.ObjectType   = 'domainRoot' 
        }
        else{ 
            olad e "Unknown Object Type (not CN or OU): $($This.OUDN)"
            throw "Unknown Object Type (not CN or OU): $($This.OUDN)"
        } 
        $This.DomainFQDN       = $DomainFQDN 
        $This.DomainDN         = "DC=" + $($This.DomainFQDN.replace(".",",DC="))
        $This.Credential       = $null
        $This.ExecutionType    = 'Local'
        $This.DomainController = $DomainController
    } 

    [void]CreateOU (){
        if($This.ObjectType -eq 'domainRoot'){
            olad d "Trying to create root of domain - just return"
        } 
        else{
            # Create an array of elements. Start with making sure  
            # root level exist, looping out to the leaf
            $DNParts = $This.OUDN.Split(',')
            for ($c = ($DNParts.Count -1); $c -ge 0; $c--){    
                
                $CurrentDN             = [string]::Join(',', ($DNParts[$c..($DNParts.Count -1)]))
                $CurrentDomainDN       = ($CurrentDN + ',' + $This.DomainDN).TrimStart(',')
                $CurrentName           = (($CurrentDN -split (",",2))[0]).SubString(3)
                $CurrentParent         = ($currentDN -split (",",2))[1]
                $CurrentParentDomainDN = ($CurrentParent + ',' + $This.DomainDN).TrimStart(',')
                
                if($CurrentParent -eq ''){
                    olad d "'$CurrentName'. The parent domainDN is $CurrentParentDomainDN"
                }
                
                else{
                    olad d 'LeafOU (CurrentName)',"'$CurrentName'" 
                    olad d 'Parent (CurrentParent)',"'$CurrentParent'"
                    olad d 'Parent domainDN (CurrentParentDomainDN)',"'$CurrentParentDomainDN'"
                    olad d 'CurrentDomainDN',"'$CurrentDomainDN'"
                }
                
                # Test if object exists
                try{
                    [ScriptBlock] $GetResultScriptBlock ={ 
                        param(
                            $ObjectDN,
                            $Server,
                            $Credential
                        )
                        
                        try{
                            $GetADObjectParams = @{
                                Identity = $ObjectDN
                                Server = $Server
                                ErrorAction = 'Stop'
                            }
                            if($Credential){
                                $GetADObjectParams += @{
                                    Credential = $Credential
                                }   
                            }
                            Get-ADOBject @GetADObjectParams | Out-Null
                            # The Object exists already
                            $true
                        }
                        catch{
                            if($_.CategoryInfo.Reason -eq 'ADIdentityNotFoundException'){
                                # The Object does not exist
                                $false
                            }
                            else{
                                # The Object does not exist
                                olad e "Error trying to get OU '$CurrentName' in parent '$CurrentParent'"
                                olad e $_.Exception.Message
                                olad e $_.InvocationInfo
                                olad e $_.ScriptStackTrace
                                olad e $_.ScriptName
                                olad e $_.TargetObject
                                olad e $_.FullyQualifiedErrorId
                                olad e $_.ErrorRecord
                                
                                # Throw the error to the caller
                                $PSCmdlet.ThrowTerminatingError($_)
                            }
                        }
                    } 

                    $GetArgumentList = @($CurrentDomainDN,$This.DomainController,$This.Credential)
                    $GetParams       = @{
                        ScriptBlock  = $GetResultScriptBlock
                        ArgumentList = $GetArgumentList
                    }
                    if($This.ExecutionType -eq 'Remote'){
                        $GetParams  += @{
                            Session  = $This.PSSession
                        }
                    }
                    $GetResult = Invoke-Command @GetParams

                    switch($GetResult){
                        $true{
                            olad d "The OU '$CurrentName' in parent '$CurrentParent' exists already."
                        }
                        $false{
                            olad d "The OU '$CurrentName' in parent '$CurrentParent' does not exist, must be created"
                        }
                        default{
                            olad e "Error trying to get OU '$CurrentName' in parent '$CurrentParent'"
                            throw $GetResult
                        }
                    } 
                }
                catch{
                    olad e "Failed to test '$CurrentDomainDN'" 
                    throw $_
                }  

                if($GetResult -eq $false){
                    [ScriptBlock] $SetResultScriptBlock ={ 
                        param(
                            $Name,
                            $Type,
                            $Path,
                            $Server,
                            $Credential
                        )
                        
                        try{
                            $NewADObjectParams = @{
                                Name        = $Name
                                Type        = $Type
                                Path        = $Path
                                Server      = $Server
                                ErrorAction = 'Stop'
                            }
                            if($Credential){
                                $NewADObjectParams += @{
                                    Credential = $Credential
                                }   
                            }
                            New-ADOBject @NewADObjectParams | Out-Null
                            # The Object was created
                            $true
                        }
                        catch{
                            $_
                        }
                    } 

                    $SetArgumentList = @($CurrentName,$This.ObjectType,$CurrentParentDomainDN,$This.DomainController,$This.Credential)
                    $SetParams       = @{
                        ScriptBlock  = $SetResultScriptBlock
                        ArgumentList = $SetArgumentList
                    }
                    if($This.ExecutionType -eq 'Remote'){
                        $SetParams  += @{
                            Session  = $This.PSSession
                        }
                    }
                    $SetResult       = Invoke-Command @SetParams

                    switch($SetResult){
                        $true{
                            olad d "OU '$CurrentName' in parent '$CurrentParent' was created"
                            $OUsWasCreated = $true
                        }
                        
                        default{
                            olad e "Failed to create OU '$CurrentName' in parent '$CurrentParent'"
                            throw $SetResult.ToString()
                        }
                    }
                }
            }     
        }
    }
}