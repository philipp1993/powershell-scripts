<#
.SYNOPSIS 
Checks the last result of all Veeam jobs and presents them as PRTG XML.

.DESCRIPTION
This script connects to the the Veeam Backup and Replication Server with the VeeamPSSnapin (to get it, you must install the Veeam Console)
and checks the "last result" for all enabled jobs. The results are written out as PRTG XML. One channel per Job.
No specific edition of veeam is required. This script was last tested against Veeam Backup and Replication 9.5 Update 2.
If your PRTG Probe Server is x64 you need a little trick to start the Powershell Script in x64 Powershell.
See https://kb.paessler.com/en/topic/32033-is-it-possible-to-use-the-64bit-version-of-powershell-with-prtg for details and a solution.
Example: Use the Custom Exe (Advanced) Sensor. Choose "PSx64.exe" as Programm. Use '-f=Get-VeeamJobResults.ps1 -p="%host"' as the parameter for the sensor.
Both, the PSx64.exe and this Powershell Script need to be in the EXEXML custom sensor folder of the probe running this sensor.
If you want don't provide Username and Password to the sensor you need to change the security context of the sensor to use the credentials for the parent device
instead of the probe services context.
The Lookup file "ps.veeam.jobResults.ovl" needs to be placed in "..\PRTG Network Monitor\lookups\custom" on the CORE server.
After that you need to rescan the lookup files. 

.PARAMETER Server
The IP or DNS of the Server running Veeam. You can use the %host parameter of PRTG.

.PARAMETER Port
Port of the Veeam instance. Leave empty for default (9392)

.PARAMETER User
User with login rights to Veeam. "Backup Viewer" Role is sufficient. Leave empty to use the credentials of the user running this script.

.PARAMETER Password
The Password for the User.

.PARAMETER ExcludeBackRepliJobs
If this switch is present all Backup, Replication, Backup copy, File copy and VM Copy jobs are excluded.

.PARAMETER ExcludeTapeJobs
If this switch ist present all backup to tape and file to tape jobs are excluded.

.PARAMETER ExcludeEndpointJobs
If this switch ist present all Agents and Endpoint Protection Jobs are excluded.

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
    Updated: 2017-06-12
#>

param(
    [Parameter(Mandatory=$true)][string]$Server,
    [int]$Port,
    [string]$User,
    [string]$Password,
    [switch] $ExcludeBackRepliJobs,
    [switch] $ExcludeTapeJobs,
    [switch] $ExcludeEndpointJobs   
)

try
{
    Add-PSSnapin VeeamPSSnapin -ErrorAction Stop -ErrorVariable err
}
catch
{
    #Veeam SnapIn couldn't be loaded. Write an PRTG Error
    write-host "<prtg>"
    write-host "<error>1</error>"
    write-host "<text>Veeam Snapin couldn't be loaded. See description. Check if script is running in x64 Powershell. Powershell Error Output: " $err[0].ErrorRecord "</text>"
    write-host "</prtg>"
    exit 1
}


#PRTG wants numeric values. Veeam provides the last result as string.
$ResultLookUp=@{"Success" = 0; "Warning" = 1; "Error" = 2; "Failed" = 2}

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

    write-host "<float>0</float>"

    write-host "<ValueLookup>ps.veeam.jobResults</ValueLookup>"

    write-host "</result>"
    
}

if(!$Port)
{
    #Sets default port if no one was specified.
    $Port = 9392
}

try
{
    if($User)
    {
        #username was specified. Use it.
        Connect-VBRServer -Server $Server -Port $Port -User $User -Password $Password -Timeout 30 -ErrorAction Stop -ErrorVariable err
    }
    else
    {
        #No username. Use current user to connect.
        Connect-VBRServer -Server $Server -Port $Port -ErrorAction Stop -ErrorVariable err
    }
}
catch
{
    #Can't connect to Veeam. Write an PRTG Error
    write-host "<prtg>"
    write-host "<error>1</error>"
    write-host "<text>Couldn't connect to Veeam on" $Server $Port " Reason: " $err[0].ErrorRecord "</text>"
    write-host "</prtg>"
    exit 2
}

write-host "<prtg>"

if(!$ExcludeBackRepliJobs)
{
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
            Build-XML $Job.Name $Job.Info.LatestStatus.ToString()
        }
    }
}

if(!$ExcludeTapeJobs)
{
    #Gets all
        # Backup to Tape jobs
        # File to Tape jobs
    $VeeamJobs = Get-VBRTapeJob
    foreach ($Job in $VeeamJobs)
    {
        Build-XML $Job.Name $Job.LastResult.ToString()
    }
}

if(!$ExcludeEndpointJobs)
{
    #Gets all
        # Agent/Endpoints Jobs
    $VeeamJobs = Get-VBREPJob
    foreach ($Job in $VeeamJobs)
    {
        Build-XML $Job.Name $Job.LastResult.ToString()
    }
}


write-host "</prtg>"

Disconnect-VBRServer
