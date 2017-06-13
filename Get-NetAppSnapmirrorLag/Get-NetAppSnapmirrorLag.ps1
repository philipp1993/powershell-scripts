<#
.SYNOPSIS 
Outputs a PRTG XML with all NetApp Snapmirror relationships and their lagtime.

.DESCRIPTION
Every snapmirror relationships results in one channel.
Channel names are FilerA:volA - FilerB:volB.
The message of the sensor is set to the relationship name with the biggest lag time.
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
C:\PS> Get-NetAppSnapmirrorLagtime netapp.company.local h 25 30

.EXAMPLE
C:\PS> Get-NetAppSnapmirrorLagtime netapp.company.local 

.NOTES
    Author: Philipp Koch
    Created: 2016-12-08
    Updated: 2017-06-13
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
    [char]$TimeFormat = "h",
    [int]$WarningThreshold = "25",
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
        Connect-NaController -Name $TargetHost -Credential $Credential -HTTP -Port $Port -ErrorAction Stop -ErrorVariable err
    }
    else
    {
        Connect-NaController -Name $TargetHost -Credential $Credential -HTTPS -Port $Port -ErrorAction Stop -ErrorVariable err
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

$Snapmirrors = Get-NaSnapmirror

#The Sensor will show the relationship with the biggest lagtime as sensor text
$PRTGText = ""
$BiggestLagtime = 0


write-host "<prtg>"

foreach($SnapmirrorRelationship in $Snapmirrors)
{ 
    $LagtimeInMinutes = $SnapmirrorRelationship.LagTime / 60

    if($TimeFormat -eq "h")
    {
        $value = [math]::round($LagtimeInMinutes / 60,2)
    }
    else
    {
        $value = $LagtimeInMinutes   
    }

    write-host "<result>"

    write-host -NoNewline "<channel>"
    write-host -NoNewline $SnapmirrorRelationship.SourceLocation
    write-host -NoNewline " - "
    write-host -NoNewline $SnapmirrorRelationship.DestinationLocation
    write-host "</channel>"


    $valueText = "<value>"+$value+"</value>"
    #PRTG needs a dot not a comma for the float value. Replace it if necessary. 
    $valueText = $valueText.Replace(',','.')

    write-host $valueText

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

    if($LagtimeInMinutes -gt $BiggestLagtime)
    {
        $PRTGText =$SnapmirrorRelationship.SourceLocation + "-" + $SnapmirrorRelationship.DestinationLocation
    }
}


write-host "<text>" $PRTGText "</text>"
write-host "</prtg>"
