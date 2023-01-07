# Convert-EkahauAntennaJSONtoNSMA.ps1
## SYNOPSIS
Converts the Ekahau Antenna Data in JSON to the NSMA WG16.99.050 standard format.  
https://nsma.org/wp-content/uploads/2016/05/wg16_99_050.pdf

## SYNTAX
```powershell
C:\PS>Convert-EkahauAntennaJSONtoNSMA\Convert-EkahauAntennaJSONtoNSMA.ps1 [-InputDirectory] <String> [-OutputDirectory] <String> [<CommonParameters>]
```

## DESCRIPTION
Ekahau has a wide variety of Antenna pattern which is shipped to every user, but they use their own JSON file format.  
This script converts these JSON Files to NSMA WG16.99.050 standard format which is readably by many software products.  
For example, the "Antenna Pattern Editor 2.0" which can render a 3D view of the antenna pattern.  
https://www.wireless-planning.com/antenna-pattern-editor  
The Ekahau Antenna Files are located in C:\Program Files\Ekahau\Ekahau AI Pro\Conf\antennas.zip  
You must extract these ZIP to a folder of choice.  
See my blog for a more a detailed explanation: https://blog.philipp-koch.net/  

## PARAMETERS
### -InputDirectory &lt;String&gt;
Select the folder in which you extracted the Ekahau antennas.zip
```
REQUIRED?                true
Position?                    1
Default                 
```
 
### --OutputDirectory &lt;String&gt;
Select an existing (empty) folder to which the converted files are written.
```
REQUIRED?                true
Position?                    2
Default                 1
```

## INPUTS
None. You cannot pipe objects.

## OUTPUTS
None. Output files are written to the OutputDirectory

## NOTES


## EXAMPLES
### EXAMPLE 1
```powershell
C:\PS>Set-PasswordExpiredIfRange
```

 
### EXAMPLE 2
```powershell
C:\PS>Set-PasswordExpiredIfRange C:\temp\antennas-in\ C:\temp\antennas-out\ 
```



