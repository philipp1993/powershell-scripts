<#
.SYNOPSIS 
Converts the Ekahau Antenna Data in JSON to the NSMA WG16.99.050 standard format. https://nsma.org/wp-content/uploads/2016/05/wg16_99_050.pdf

.DESCRIPTION
Ekahau has a wide variety of Antenna pattern which is shipped to every user, but they use their own JSON file format.
This script converts these JSON Files to NSMA WG16.99.050 standard format which is readably by many software products.
For example, the "Antenna Pattern Editor 2.0" which can render a 3D view of the antenna pattern. https://www.wireless-planning.com/antenna-pattern-editor
The Ekahau Antenna Files are located in C:\Program Files\Ekahau\Ekahau AI Pro\Conf\antennas.zip 
You must extract these ZIP to a folder of choice. 
See my blog for a more a detailed explanation: https://blog.philipp-koch.net/

.PARAMETER InputDirectory
Select the folder in which you extracted the Ekahau antennas.zip

.PARAMETER OutputDirectory
Select an existing (empty) folder to which the converted files are written. 

.INPUTS
None. You cannot pipe objects.

.OUTPUTS
None. Output files are written to the OutputDirectory

.LINK
http://github.com/philipp1993/powershell-scripts

.EXAMPLE
C:\PS> Set-PasswordExpiredIfRange

.EXAMPLE
C:\PS> Set-PasswordExpiredIfRange C:\temp\antennas-in\ C:\temp\antennas-out\ 

.NOTES
    Author: Philipp Koch
    Created: 2023-01-07
    Updated: 2023-01-07
#>
param(
    [Parameter(Mandatory=$true)][string]$InputDirectory,
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)

#Only read JSON files. Perhaps there are more files in this directory.
Get-ChildItem  $InputDirectory -Filter "*.json" | 
Foreach-Object {
    $Antenna = Get-Content -Raw $_.FullName | ConvertFrom-Json
    $OutputFile = $OutputDirectory + $_.Name + ".txt"
    "REVNUM:,NSMA WG16.99.050" | Out-File -FilePath $OutputFile
    "REVDAT:,19990520" | Out-File -FilePath $OutputFile -Append
    "ANTMAN:," + $Antenna.accessPointVendorModel.vendor.vendor | Out-File -FilePath $OutputFile -Append 
    "MODNUM:," + $Antenna.accessPointVendorModel.model.model + " " + $Antenna.frequencyBand  | Out-File -FilePath $OutputFile -Append 
    $PATFRE = ""
    switch ($Antenna.frequencyBand) {
        "TWO" { 
            "LOWFRQ:,2412" | Out-File -FilePath $OutputFile -Append
            "HGHFRQ:,2484" | Out-File -FilePath $OutputFile -Append
            $PATFRE = "2412"
        }
        "FIVE" { 
            "LOWFRQ:,5150" | Out-File -FilePath $OutputFile -Append
            "HGHFRQ:,5725" | Out-File -FilePath $OutputFile -Append
            $PATFRE = "5150"
        }
        "SIX" { 
            "LOWFRQ:,5925" | Out-File -FilePath $OutputFile -Append
            "HGHFRQ:,6425" | Out-File -FilePath $OutputFile -Append
            $PATFRE = "5925"
        }
        Default {}
    }
    #Ekahau provides the Gain for some antennas. If not, "0" is written to file, since this a mandatory field. 
    "GUNITS:,DBI" | Out-File -FilePath $OutputFile -Append
    if ($Antenna.manufacturerMaximumGain -ne "NaN") {
        "MDGAIN:," + $Antenna.manufacturerMaximumGain | Out-File -FilePath $OutputFile -Append
    }
    else {
        "MDGAIN:,0" | Out-File -FilePath $OutputFile -Append
    }
    "ELTILT:," + $Antenna.defaultTiltAngle.degrees | Out-File -FilePath $OutputFile -Append
    "PATTYP:,TYPICAL" | Out-File -FilePath $OutputFile -Append
    "NOFREQ:,1" | Out-File -FilePath $OutputFile -Append
    "PATFRE:," + $PATFRE | Out-File -FilePath $OutputFile -Append 
    "NUMCUT:,2" | Out-File -FilePath $OutputFile -Append 

    "PATCUT:,AZ" | Out-File -FilePath $OutputFile -Append 
    "POLARI:,H/H" | Out-File -FilePath $OutputFile -Append 
    "NUPOIN:," + $Antenna.horizontalPlane.gains.count | Out-File -FilePath $OutputFile -Append
    "FSTLST:," + $Antenna.horizontalPlane.gains[0].angleInDegrees + "," + $Antenna.horizontalPlane.gains[$Antenna.horizontalPlane.gains.count - 1].angleInDegrees | Out-File -FilePath $OutputFile -Append 
    foreach ($gain in $Antenna.horizontalPlane.gains) {
        [String]$gain.angleInDegrees + "," + [String]$gain.dBi + "," | Out-File -FilePath $OutputFile -Append 
    }

    "PATCUT:,EL" | Out-File -FilePath $OutputFile -Append 
    "POLARI:,H/H" | Out-File -FilePath $OutputFile -Append 
    "NUPOIN:," + $Antenna.elevationPlane.gains.count | Out-File -FilePath $OutputFile -Append
    "FSTLST:," + $Antenna.elevationPlane.gains[0].angleInDegrees + "," + $Antenna.elevationPlane.gains[$Antenna.elevationPlane.gains.count - 1].angleInDegrees | Out-File -FilePath $OutputFile -Append  
    foreach ($gain in $Antenna.elevationPlane.gains) {
        [String]$gain.angleInDegrees + "," + [String]$gain.dBi + "," | Out-File -FilePath $OutputFile -Append 
    }
    "ENDFIL:,EOF" + $Antenna.elevationPlane.gains.count | Out-File -FilePath $OutputFile -Append

}
