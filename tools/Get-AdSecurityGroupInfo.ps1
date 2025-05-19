function Get-ADSecurityGroupsInfo {
    $groups = Get-ADGroup -Filter * -Properties Description, GroupCategory, DistinguishedName, MemberOf
    $output = @()

    foreach ($group in $Groups) {
        $groupInfo = @{
            "Name" = $group.Name
            "Path" = $group.DistinguishedName
            "Description" = $group.Description
            "GroupType" = if ($group.GroupCategory -eq "Security") { "security" } else { "distribution" }
            "GroupScope" = $group.GroupScope
            "MemberOf" = @()
        }

        # Get groups that the current group is a member of
        foreach ($parentGroup in $group.MemberOf) {
            $parentGroupName = (Get-ADGroup -Identity $parentGroup).Name
            $groupInfo.MemberOf += $parentGroupName
        }
        $output += $groupInfo
    }

    $output | ConvertTo-Json -Depth 3
}

# Run the function
Get-ADSecurityGroupsInfo | Out-File "ADGroups.json"