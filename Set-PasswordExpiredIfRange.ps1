<#
.SYNOPSIS 
Set 'user must change password at next logon' for users whose password will expire in X days.

.DESCRIPTION
Set 'user must change password at next logon' for users whose password will expire in X days.
See the USER CONFIG part of this script to change it for your needs. 

.INPUTS
None. You cannot pipe objects to Set-PasswordExpiredIfRange.

.OUTPUTS
None. Output is written to log file.

.EXAMPLE
C:\PS> Set-PasswordExpiredIfRange

.LINK
http://github.com/philipp1993/powershell-scripts
#>

#Requires -Modules ActiveDirectory

#------------------------START USER CONFIG---------------------#
#This script iterates over members of the following group.
$GroupMembers = Get-ADGroupMember "Everyone"
#Password will be set to 'change at next logon' for users with expiring passwords in X days.
$expiresInDays=1
#------------------------END USER CONFIG---------------------#


#Get AD Passwordpolicy to determine when passwords will normally expire.
#Keep in mind that this will NOT reflect fine-grained password policies.
$passwordPolicy = Get-ADDefaultDomainPasswordPolicy

#Build filename of log file.
$logfile = Get-Date -format "yyyy-MM-dd"
$logfile = "Set-PasswordExpiredIfRange-"+$logfile+".txt"

#Get current date and log it
$date = get-date 
$date | Out-File $logfile -Append

#Iterate group members.
foreach ($user in $GroupMembers)
{
	#Get userdetails for each member (important for us: PasswordLastSet und PasswordNeverExpires)
	$userDetails = Get-ADUser -Identity $user -Properties *
	
	#Check if the password for the given user WILL expire generally
	if(!$userDetails.PasswordNeverExpires)
	{
		#Check if the password was set before and if it expires within the $expiresInDays range.
		if($userDetails.passwordlastset -and $userDetails.passwordlastset.AddDays($passwordPolicy.MaxPasswordAge.Days) -lt $date.AddDays($expiresInDays) -and $date -lt $userDetails.passwordlastset.AddDays(92) )
		{
			$user.Name | Out-File $logfile -Append
			"LastSet: "+$userDetails.passwordlastset | Out-File $logfile -Append
			"Expires: "+$userDetails.passwordlastset.AddDays($passwordPolicy.MaxPasswordAge.Days) | Out-File $logfile -Append
			#Set-ADUser -Identity $user -ChangePasswordAtLogon $true | Out-File $logfile -Append
			"" | Out-File $logfile -Append #empty line to make the log more readable
		}	
	}
}

