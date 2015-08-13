<#
.SYNOPSIS

This function will collapse nested group membership one level up to facillitate decommission a large number of groups

.DESCRIPTION

The script takes an input of groups, then it checks those groups for membership in any other group (Memberof) 
If it finds a group is a member of any other groups it moves forward with processing
It recusrsively checks its own group membership for users, then adds all those users to any and all groups that it is a direct member of.  
Lastly it removes itself from the groups that it is a memberof


.PARAMETER StrGroups

Group name to interrogate and then collapse nested membership one level up from

.EXAMPLE

Collapse nested membership from a single group called 'test_group'

remove-nestedusers test_group

.EXAMPLE

Collapse nested membership via pipeline input from variable

$strgroups = Get-ADGroup -Filter {GroupCategory -eq 'security' -and name -like '*test*'} -SearchBase 'OU=Test,OU=Groups,DC=domain,DC=COM'
remove-nestedusers $StrGroups

.NOTES

It can take pipeline input for the 'strGroups' variable.  
Joe Funk - 8/13/2015
#>



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
