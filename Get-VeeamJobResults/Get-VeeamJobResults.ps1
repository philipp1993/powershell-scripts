<#
.SYNOPSIS 
Checks the last result of all Veeam Backup jobs and presents them as PRTG XML.

.DESCRIPTION
This script connects to the the Veeam Backup and Replication Server with the VeeamPSSnapin (to get it, you must install the Veeam Console)
and checks the "last result" for all enabled jobs. The results are written out as PRTG XML. One channel per Job.

.PARAMETER Server
The IP or DNS of the Server running Veeam.

.PARAMETER Port
Port of the Veeam instance. Leave empty for default

.PARAMETER User
User with login rights to Veeam. "Backup Viewer" Role is sufficient. Leave empty to use the credentials of the user running this script.

.PARAMETER Password
The Password for the User.

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
PRTG XML to console

.LINK
http://github.com/philipp1993/powershell-scripts

.EXAMPLE
C:\PS> Get-VeeamJobResults -Server veeam.company.com 

.EXAMPLE
C:\PS> Get-VeeamJobResults -Server veeam.company.com -User company\backupAdmin -Password securePhrase1 

.NOTES
    Author: Philipp Koch
    Created: 2017-06-09
    Updated: 2017-06-09
#>

param(
    [Parameter(Mandatory=$true)][string]$Server,
    [int]$Port,
    [string]$User,
    [string]$Password   
)

Add-PSSnapin VeeamPSSnapin

#PRTG wants numeric values. Veeam provides the last result as string.
$ResultLookUp=@{Success = 0.0; Warning = 1.0; Error = 2.0}

#Helper function for writing the same XML format for all kind of jobs.
function Build-XML($Job, $LastResult)
{
    write-host "<result>"

    write-host -NoNewline "<channel>"
    write-host -NoNewline $Job
    write-host "</channel>"

    write-host -NoNewline "<value>"
    write-host -NoNewline $ResultLookUp[$LastResult]
    write-host "</value>"

    write-host "<float>1</float>"

    write-host "<LimitMaxWarning>0.5</LimitMaxWarning>"
    write-host "<LimitMaxError>1.5</LimitMaxError>"

    write-host "<LimitWarningMsg>Last result of this Job had a warning</LimitWarningMsg>"
    write-host "<LimitErrorMsg>Last result of this Job had an error</LimitErrorMsg>"

    write-host "</result>"
    
}

if(!$Port)
{
    #Sets default port if no one was specified.
    $Port = 9392
}

if($User)
{
    #username was specified. Use it.
    Connect-VBRServer -Server $Server -Port $Port -User $User -Password $Password
}
else
{
    #No username. Use current user to connect.
    Connect-VBRServer -Server $Server -Port $Port
}

write-host "<prtg>"

#Gets all
    # Backup jobs 
    # Replication jobs
    # Backup copy jobs
    # File copy jobs
    # VM Copy jobs
$VeeamJobs = Get-VBRJob
foreach ($Job in $VeeamJobs)
{
    #Don't list 'disabled' Jobs.
    if($Job.IsScheduleEnabled)
    {
        Build-XML $Job.Name $Job.Info.LatestStatus
    }
}

#Gets all
    # Backup to Tape jobs
    # File to Tape jobs
$VeeamJobs = Get-VBRTapeJob
foreach ($Job in $VeeamJobs)
{
    Build-XML $Job.Name $Job.LastResult
}


#Gets all
    # Agent/Endpoints Jobs
$VeeamJobs = Get-VBREPJob
foreach ($Job in $VeeamJobs)
{
    Build-XML $Job.Name $Job.LastResult
}


write-host "</prtg>"

Disconnect-VBRServer
