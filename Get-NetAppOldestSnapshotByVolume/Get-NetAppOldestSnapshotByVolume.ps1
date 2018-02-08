<#
.SYNOPSIS 
Outputs a PRTG XML with all NetApp Volumes and their oldest snapshot age.

.DESCRIPTION
Every volume results in one channel.
The message of the sensor is set to the volume name with the oldest snapshot.
For more infos see the parameter descriptions.

Tested against Data OnTap 8.2.4P6 7-Mode

This script requires the NetApp Powershell module.
http://mysupport.netapp.com/tools/info/ECMLP2310788I.html?productID=61926

.PARAMETER TargetHost
DNS name or IP of the NetApp filer. You can use the %host parameter of PRTG 

.PARAMETER User
User name for the NetApp. You can use the %linuxuser parameter of PRTG 

.PARAMETER Password
Password for the specified user. You can use the %linuxpassword parameter of PRTG 

.PARAMETER Port
If set this port will be used to connect to the NetApp. Leave empty for default.

.PARAMETER HTTP
Set this switch to use HTTP instead of HTTPS.

.PARAMETER TimeFormat
Specify if the returned snapshot age should be in minutes (m), hours (h) or days (d)

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
C:\PS> Get-NetAppSnapmirrorLagtime netapp.company.local h 25 30

.EXAMPLE
C:\PS> Get-NetAppSnapmirrorLagtime netapp.company.local 

.NOTES
    Author: Philipp Koch
    Created: 2016-12-08
    Updated: 2018-02-08
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetHost,
    [Parameter(Mandatory=$true)]
    [string]$User,
    [Parameter(Mandatory=$true)]
    [string]$Password,
    [int]$Port,
    [switch]$HTTP,
    [char]$TimeFormat = "d",
    [int]$WarningThreshold = "7",
    [int]$ErrorThreshold = "30"
)

try{
    #Import the OnTap module manually using the following path.
    Import-Module 'C:\Program Files (x86)\NetApp\NetApp PowerShell Toolkit\Modules\DataONTAP\dataontap.psd1' -ErrorAction Stop -ErrorVariable err
}
catch
{
    write-host "<prtg>"
    write-host "<error>1</error>"
    write-host "<text>NetApp Module couldn't be loaded. Powershell Error: " $err[0].ErrorRecord "</text>"
    write-host "</prtg>"
    exit 1
}

$pass = $Password | ConvertTo-SecureString -asPlainText -Force
#Create the credential used to connect to each NetApp controller
$Credential = New-Object System.Management.Automation.PSCredential($User,$pass)



try{
    if(!$Port)
    {
        #Sets one of the default ports if no one was specified.
        if($HTTP)
        {
            $Port = 80
        }
        else
        {
            $Port = 443
        }
        
    }

    if($HTTP)
    {
        $info = Connect-NaController -Name $TargetHost -Credential $Credential -HTTP -Port $Port -ErrorAction Stop -ErrorVariable err
    }
    else
    {
        $info = Connect-NaController -Name $TargetHost -Credential $Credential -HTTPS -Port $Port -ErrorAction Stop -ErrorVariable err
    }
    
}
catch
{
    write-host "<prtg>"
    write-host "<error>1</error>"
    write-host "<text>Can't connect to the NetApp "$TargetHost ". Powershell Error: " $err[0].ErrorRecord "</text>"
    write-host "</prtg>"
    exit 1
}

#Get all volumes to iterate over them
$Volumes = Get-NaVol | Where-Object {$_.State -eq "online"}

#The Sensor will show the volume with the oldest snapshot as sensor text.
$PRTGText = ""
$BiggestSnapAgeAll = 0

$CurrentEpochTime = [int][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s))


write-host "<prtg>"

foreach($Volume in $Volumes)
{ 

    #Gets the snapshot with the oldest accesstime.
    $Snapshot = Get-NaSnapshot $Volume.Name | Sort-Object -Property AccessTime | Select-Object -First 1

    #No Snapshot for this volume
    if(!$Snapshot)
    {
        continue
    }

    $SnapAgeInSeconds = $CurrentEpochTime - $Snapshot.AccessTime

    if($SnapAgeInSeconds -gt $BiggestSnapAgeAll)
    {
        $BiggestSnapAgeAll = $SnapAgeInSeconds
        $PRTGText = $Volume.Name
    }
    
    write-host "<result>"

    write-host -NoNewline "<channel>"
    write-host -NoNewline $Volume.Name
    write-host "</channel>"

    switch($TimeFormat)
    {
        'm' { 
            $value = [math]::round($SnapAgeInSeconds / 60,2)
            write-host "<CustomUnit>minutes</CustomUnit>"
        }

        'h' {
            $value = [math]::round($SnapAgeInSeconds / 3600,2)
            write-host "<CustomUnit>hours</CustomUnit>"
        }

         'd' {
            $value = [math]::round($SnapAgeInSeconds / 86400,2)
            write-host "<CustomUnit>days</CustomUnit>"
        }

        'default' { 
            $value = [math]::round($SnapAgeInSeconds / 60,2)
            write-host "<CustomUnit>minutes</CustomUnit>"
        }


    }

    write-host "<float>1</float>"

    $valueText = "<value>"+$value+"</value>"
    #PRTG needs a dot not a comma for the float value. Replace it if necessary. 
    $valueText = $valueText.Replace(',','.')

    write-host $valueText

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


write-host "<text>" $PRTGText "</text>"
write-host "</prtg>"
