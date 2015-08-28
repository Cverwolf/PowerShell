# This is a fairly simple script that queryies DDG membership and saves to a text file in the same directory as it is executed.
# There is a choice menu to query group membership on either (A) all DDGs or (S) a specific DDG.  
# There is a popup for name of the specific DDG if (S) is chosen.  
#
# Currently it loads the Exchage 2007 admin tools
# Plan to edit to look for and load the other tools and/or use remoting. 
#
# 

function get_DDMems($DDGgrps)
{
foreach ($grp in $DDGgrps) 
{
    $DDGmembers = get-recipient -recipientpreviewfilter $grp.RecipientFilter -resultsize unlimited | select name, primarysmtpaddress 
    $grp.Name + " has the following " + @($DDGmembers).count + " members: `n"
    "----------------------------------------------------------"
    @($DDGmembers) + "`r`n"
}
} 

#Check for and if needed, load Exchange 2007 snapin
if ( (Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.Admin -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
}


#Create choice menu
$title = "DDG Membership"
$message = "Export DDG Members - Specific DDG or all DDGs"
$all = New-Object System.Management.Automation.Host.ChoiceDescription "&All DDGs", "Export members of all DDGs"
$specificDDG = New-Object System.Management.Automation.Host.ChoiceDescription "&Specific DDG", "Export members of a specific DDG"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($All, $specificDDG)
$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

#select group membership query type from choice menu input from $result
switch ($result)
    {
        0 {
            # Query all DDGs and run return members function 'get_DDMems' on them all, outputting to a TXT file
            $DDGgrps = Get-DynamicDistributionGroup -resultsize unlimited
            get_DDMems $DDGgrps | out-file All_DDG_members.txt
          }
        1 {
            # Create inputbox for entering specific DDG
            [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
            $inputgrp = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a Dynamic Disto Group name", "DDG") 
            # get specific DDG supplied in inputbox and assign it to variable
            $DDGgrps = Get-DynamicDistributionGroup $inputgrp
            # Append groupname to '_DDG_members.txt' to name output file
            $outfile = $inputgrp + "_DDG_members.txt"
            # Run return members function 'get_DDMems' on specific DDG supplied, outputting to a TXT file
            get_DDMems $DDGgrps | out-file $outfile
          }
    }

 
