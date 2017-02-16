<#
.SYNOPSIS 
Set 'user must change password at next logon' for users whose password will expire in X days.

.DESCRIPTION
If a users password expires during the work day they sometimes are faced with unexpected behavior.
Furthermore if the password expires while the workstation is locked the user has to manually select "Change user"
and enter their username and old credentials again. This is sometimes unclear (regardless Windows shows a message explaining so).
To reduce these problems and helpdesk tickets we manually set the password as expired every night to force the user to change their password once
they enter the office.

.PARAMETER TargetGroup
Select the group with all users the script should itterate over.

.PARAMETER ExpiresInDaysThreshold
Password is set to expired for users whose password will expire in the timespan of the given days.

.PARAMETER MaxPasswordAgeDays
This option is needed if you use fine-grained password policies. Give the amount of days users are forced to change their password.
If you leave this parameter out or set it 0 the MaxPasswordAge of the Default Domain Policy will be queried.

.PARAMETER LogDirectory
All users with their expiring time will be logged. If no directory is given the working directory will be used.
Logs are named Set-PasswordExpiredIfRange-YYYY-MM-DD.txt

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
None. Output is written to log file.

.EXAMPLE
C:\PS> Set-PasswordExpiredIfRange

.EXAMPLE
C:\PS> Set-PasswordExpiredIfRange Group1 5 90 

.LINK
http://github.com/philipp1993/powershell-scripts
#>

#Requires -Modules ActiveDirectory

param(
    [string]$TargetGroup = "Everyone",
    [string]$ExpiresInDaysThreshold = "1",
    [int]$MaxPasswordAgeDays = 0,
    [string]$LogDirectory = ""
)

#This script iterates over members of the following group.
$GroupMembers = Get-ADGroupMember $TargetGroup

if($MaxPasswordAgeDays -lt 1)
{
    #Get AD Passwordpolicy to determine when passwords will normally expire.
    #Keep in mind that this will NOT reflect fine-grained password policies.
    $PasswordPolicy = Get-ADDefaultDomainPasswordPolicy
    $MaxPasswordAgeDays = $PasswordPolicy.MaxPasswordAge.Days
}

#Build filename of log file.
$Logfile = $LogDirectory+"Set-PasswordExpiredIfRange-"+$(Get-Date -format "yyyy-MM-dd")+".txt"

#Get current date (default formating) and log it
$CurrentDate = Get-Date
$CurrentDate | Out-File $Logfile -Append

#Iterate group members.
foreach ($User in $GroupMembers)
{
	#Get userdetails for each member
	$UserDetails = Get-ADUser -Identity $User -Properties PasswordLastSet,PasswordNeverExpires
	
	#Check if the password for the given user WILL expire generally
	if(!$UserDetails.PasswordNeverExpires)
	{
        #Check if the password was set before
        if($UserDetails.PasswordLastSet)
        {
            #Calculate when it will expire
            $UserPasswordExpires = $UserDetails.passwordlastset.AddDays($MaxPasswordAgeDays)

		    #Chef if it expires within the $expiresInDays range.
		    if($UserPasswordExpires -lt $CurrentDate.AddDays($ExpiresInDaysThreshold) -and $CurrentDate -lt $UserPasswordExpires )
		    {
			    $User.Name | Out-File $Logfile -Append
			    "LastSet: "+$UserDetails.passwordlastset | Out-File $Logfile -Append
			    "Expires: "+$UserPasswordExpires | Out-File $Logfile -Append
			    Set-ADUser -Identity $User -ChangePasswordAtLogon $true | Out-File $logfile -Append
			    "" | Out-File $Logfile -Append #empty line to make the log more readable
		    }	
        }
	}
}

