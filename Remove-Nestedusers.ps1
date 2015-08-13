# THIS FUNCTION WILL COLLAPSE NESTED GROUP MEMBERSHIP ONE LEVEL UP.

# Joe Funk - 8/13/2015

# The script takes an input of groups, then it checks those groups for membership in any other group (Memberof) 
# If it finds a group is a member of any other groups it moves forward with processing
# It recusrsively checks its own group membership for users, then adds all those users to any and all groups that it is a direct member of.  
# Lastly it removes itself from the groups that it is a memberof

# Effectively it is replacing any membership it has in any groups, with direct membership of its own members including users in groups nested in itself.
# Thus, collapsing nesting in lieu of direct membership

# This is most useful for decommissioning a large number of groups

# It can take pipeline input for the 'strGroups' variable.  
# For example :  
# $strgroups = Get-ADGroup -Filter {GroupCategory -eq 'security' -and name -like '*test*'} -SearchBase 'OU=Test,OU=Groups,DC=PHYSIOCORP,DC=COM' 

function remove-nestedusers {


param
  (
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
      HelpMessage='What group would you like to target?')]
    [Alias('Group')]
    [string[]]$strgroups
  )



foreach ($strGroup in $strgroups)
{

# Determine if group is a member of any other groups, if it is then it moves forwards with collapsing nesting
if ((GET-ADGROUP –Identity $strGroup –Properties MemberOf | Select-Object MemberOf).memberof)

{

# List groups that current group is a member of and save to variable
$CurrentGroupGroups = (GET-ADGROUP –Identity $strGroup –Properties MemberOf | Select-Object MemberOf).MemberOf
# List membership of current group and save to variable
$members = Get-ADGroupMember $strgroup -recursive


foreach($group in $CurrentGroupGroups)
{
     foreach($member in $members)
    {

       # Add members of current group directly to any groups it is currently nested in
    Add-ADGroupMember -Identity $group -Members $member
    }
    # Remove current group from nested membership
    Remove-ADGroupMember $group $strGroup -Confirm:$false
}
}
}
}
