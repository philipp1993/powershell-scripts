# Powershell scripts

Various powershell scripts written for work.
Every script is provided 'as is'.

Pull requests and issues are welcome!

But keep in mind: if a bug/improvement requires several hours to fix it and I'm not directly affected by it I probably won't fix it.  

| script   | description   | environment |
|----------|---------------|------------|
| [Set-PasswordExpiredIfRange](../master/Set-PasswordExpiredIfRange/Set-PasswordExpiredIfRange.ps1) | Set 'user must change password at next logon' for users whose password will expire in X days. | Active Directory |
| [Get-NetAppSnapmirrorLag](../master/Get-NetAppSnapmirrorLag/Get-NetAppSnapmirrorLag.ps1) | Outputs a [PRTG](https://www.paessler.com/prtg) XML with all Snapmirror relationships and their lagtime   | NetApp + PRTG |
| [Get-VeeamJobResults](../master/Get-VeeamJobResults/Get-VeeamJobResults.ps1) | Outputs a [PRTG](https://www.paessler.com/prtg) XML with all Veeam Jobs and their last status   | Veeam + PRTG |

_more to come_
