function Convert-DNToUnixPath{
    param(
        [string]$DistinguishedName,

        [switch]$RemoveLeaf
    )
    # Split the DN by commas, filter out 'DC=' components, reverse and replace 'OU='
    $pathParts = @($DistinguishedName -split "," | 
        Where-Object{ $_ -notmatch "^DC=" } | 
        ForEach-Object{ $_ -replace "^OU=", "" })
    
    # remove the object itself - we only want the path
    if($RemoveLeaf){
        $pathParts = $pathParts[1..($pathParts.Length - 1)]
    }
    
    # if there are CN's in the path, we cannot convert to unix path - just delete the DC-part
    $containsCN = $false
    foreach($part in $pathParts){
        if($part -match '^CN='){
            $containsCN = $true
        }
    }

    if($true -eq $containsCN){
        # just return the distingushedname without DC-part - but remove the element itself 
        return ($pathParts -join ",")
    }
    else{
        [array]::Reverse($pathParts)
        # Convert to Unix-like path
        return ($pathParts -join "/")
    }
}

function Get-ADSecurityGroupsInfo{
    $groups = Get-ADGroup -Filter * -Properties Description, GroupCategory, GroupScope, DistinguishedName, MemberOf | Where-Object{ $_.GroupCategory -eq 'Security'}
    $output = @()
    foreach($group in $Groups){
        $groupInfo = [ordered]@{
            "Name" = $group.Name
            "Path" = $(Convert-DNToUnixPath -DistinguishedName $group.DistinguishedName -RemoveLeaf)
            "Description" = $group.Description
            "GroupScope" = $group.GroupScope.tostring()
            "MemberOf" = @()
        }
        # Get groups that the current group is a member of
        foreach($parentGroup in $group.MemberOf){
            $parentGroupName = (Get-ADGroup -Identity $parentGroup).Name
            $groupInfo.MemberOf += $parentGroupName
        }
        $output += $groupInfo
    }

    $output
}

function Get-ADOrganizationalUnitsInfo{
    $OUs = Get-ADOrganizationalUnit -Filter * -Properties Description, DistinguishedName
    $output = @()
    foreach($ou in $OUs){
        $OUInfo = [ordered]@{
            "Path" = $(Convert-DNToUnixPath -DistinguishedName $ou.DistinguishedName)
            "Description" = $ou.Description
            "alias" = ''
        }
        $output += $OUInfo
    }
    $output
}

# Get OUs
$OUs = [pscustomobject]@{
    ou_schema = @($(Get-ADOrganizationalUnitsInfo))
}
$OUs | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 -FilePath '.\active_directory_ou_schema.json'


# Get Active Directory Groups
$ActiveDirectoryGroups = [pscustomobject]@{
    security_groups = @($(Get-ADSecurityGroupsInfo))
}
$ActiveDirectoryGroups | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 -FilePath '.\active_directory_security_groups.json'