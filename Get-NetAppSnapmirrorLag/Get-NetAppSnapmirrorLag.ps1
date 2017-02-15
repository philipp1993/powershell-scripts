<#
.SYNOPSIS 
Outputs a PRTG XML with all NetApp Snapmirror relationships and their lagtime.

.DESCRIPTION
Every snapmirror relationships results in one channel.
Channel names are FilerA:volA - FilerB:volB.
The message of the sensor is set to the relationship name with the biggest lag time.
For more infos see the parameter descriptions.

Tested against Data OnTap 8.1.4

The snmapwalk.exe is required in the scripts directory. 
https://syslogwatcher.com/cmd-tools/snmp-walk/

.PARAMETER TargetHost
DNS name or IP of the NetApp filer. You can use the %host parameter of PRTG 

.PARAMETER TimeFormat
Specify if the returned lagtime should be in minutes (m) or hours (h)

.PARAMETER WarningThreshold
Specify the default channel warnig threshold. 0 = disabled

.PARAMETER ErrorThreshold
Specify the default channel error threshold. 0 = disabled

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
PRTG Style XML with each NetApp Snapmirror relationship as sensor channel. 

.LINK
http://github.com/philipp1993/powershell-scripts

.EXAMPLE
C:\PS> Get-NetAppSnapmirrorLagtime netapp h 25 30

.EXAMPLE
C:\PS> Get-NetAppSnapmirrorLagtime netapp 

.NOTES
    Author: Philipp Koch
    Created: 2016-12-08
    Updated: 2017-02-15
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetHost,
    [string]$TimeFormat = "h",
    [int]$WarningThreshold = "25",
    [int]$ErrorThreshold = "30"
)

$Workingdir = Split-Path $MyInvocation.MyCommand.Path -Parent #Get current working directory
$Snmpwalk = $Workingdir+"\snmpwalk.exe" #Build the full path of the executable

$ResultArray = @{}

#Output of snmpwalk is one entry per line. This is splitted get an array.
#Get the left side of the snapmirror relationship.
$ResultArray["Left"] = $(&$Snmpwalk -r:$Targethost -v:2 -t:1 -os:".1.3.6.1.4.1.789.1.9.20.1.2" -op:".1.3.6.1.4.1.789.1.9.20.1.3" -q) -split [Environment]::NewLine
#Get the right side of the snapmirror relationship
$ResultArray["Right"] = $(&$Snmpwalk -r:$Targethost -v:2 -t:1 -os:".1.3.6.1.4.1.789.1.9.20.1.3" -op:".1.3.6.1.4.1.789.1.9.20.1.4" -q) -split [Environment]::NewLine
#Get the lagtime of the snapmirror relationship
$ResultArray["Lag"] = $(&$Snmpwalk -r:$Targethost -v:2 -t:1 -os:".1.3.6.1.4.1.789.1.9.20.1.6" -op:".1.3.6.1.4.1.789.1.9.20.1.7" -q) -split [Environment]::NewLine

#Lastcall to snmpwalk.exe failed (the ones before probably also)
#Return an PRTG Error with output of snmpwalk.exe
#Check $LASTEXITCODE.
if($LASTEXITCODE -gt 0)
{
    write-host "<prtg>"
    write-host "<error>1</error>"
    write-host "<text>snmpwalk.exe:"$ResultArray["Lag"]"</text>"
    write-host "</prtg>"
    exit 1
}

write-host "<prtg>"

for ($i=0; $i -le $ResultArray["Left"].Count-1; $i++)  
{
    $LagtimeInMinutes = 0

    #snmpwalk outputs lagtime in human readable format like "4 days, 18:59:55.84"
    if($ResultArray["Lag"][$i] -like "*days*")#only if above 24 hours
    {
        $LagtimeSplit = $ResultArray["Lag"][$i] -split " "
        $LagTimeInDays = [int]$LagtimeSplit[0] #contains the number of days (4)
        #$LagtimeDays[1] is the string "days,"
        $ResultArray["Lag"][$i] = $LagtimeSplit[2] #contains the remaing string with the time (18:59:55.84)

        #lets build the lagtime in minutes...
        $LagtimeInMinutes += $LagTimeInDays * 24 * 60
    }

    #the days (if any) are now counted. Lets add the remaining hours and minutes
    $LagTimeTime = $ResultArray["Lag"][$i] | Get-Date

    $LagtimeInMinutes += $LagTimeTime.Hour * 60 + $LagTimeTime.Minute

    if($TimeFormat -eq "h")
    {
        $ResultArray["Lag"][$i] = [math]::round($LagtimeInMinutes / 60,2)
    }
    else
    {
        $ResultArray["Lag"][$i] = $LagtimeInMinutes   
    }

    #write-host $ResultArray["Left"][$i] - $ResultArray["Right"][$i] - $ResultArray["Lag"][$i]

    write-host "<result>"
    write-host "<channel>"$ResultArray['Left'][$i]"-"$ResultArray['Right'][$i]"</channel>"
    write-host "<value>"$ResultArray['Lag'][$i]"</value>"

    if($TimeFormat -eq "h")
    {

        write-host "<float>1</float>"
        write-host "<CustomUnit>hours</CustomUnit>"
    }
    else
    {
        write-host "<float>0</float>"
        write-host "<CustomUnit>minutes</CustomUnit>"
    }

    if($WarningThreshold -gt 0 -or $ErrorThreshold -gt 0)
    {
        write-host "<LimitMode>1</LimitMode>"
    }

    if($WarningThreshold -gt 0)
    {
        write-host "<LimitMaxWarning>$WarningThreshold</LimitMaxWarning>"
    }

    if($ErrorThreshold -gt 0)
    {
        write-host "<LimitMaxError>$ErrorThreshold</LimitMaxError>"
    }

    write-host "</result>"
}


$biggestLagtime = ($ResultArray["Lag"] | measure -Maximum).Maximum

#Search the relationshipname of the biggestLagtime

#NOTE: I tried $ResultArray["Lag"].IndexOf($biggestLagtime) but it returned -1

for ($i=0; $i -le $ResultArray["Lag"].Count-1; $i++) 
{
    if($ResultArray["Lag"][$i] -eq $biggestLagtime)
    {
        write-host "<text>"$ResultArray['Left'][$i]"-"$ResultArray['Right'][$i]"</text>"
        break
    }
} 

write-host "</prtg>"
