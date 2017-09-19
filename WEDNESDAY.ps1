#THURSDAY \\Support Script For FRIDAY Active Configurator//Runs FRIDAY as SYSTEM\\USE WITH CAUTION
$RUNDIR = $PSScriptRoot
$HOSTNAME = $env:computername

function Test-Admin 
{ 
   $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
   if ($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) 
   { 
      return $true 
   } 
   else 
   { 
      return $false 
   } 
}  
Test-Admin

Function Restart-ScriptAsAdmin

{
	$Invocation=((Get-Variable MyInvocation).value).ScriptName 
	
	if ($Invocation -ne $null) 
	{ 
	   $arg="-command `"& '"+$Invocation+"'`"" 
	   if (!(Test-Admin)) { # ----- F
			      Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg 
			      break 
		   		} 
			Else {
				Write-Host "Already running as Admin no need to restart..."
		}
	} 
	else 
	{ 
	   return "Error - Script is not saved" 
	   break 
	} 
}
Restart-ScriptAsAdmin

Copy-Item $RUNDIR\GOD\* C:\Windows\System32
#& "$RUNDIR\SetACL Studio.msi"
#cp "$RUNDIR\SetACL Studio.msi" "C:\Windows\System32\SetACL Studio.msi"
#C:\Windows\System32\RemoveTIFromCLSIDs.bat
net stop trustedinstaller
net start trustedinstaller
C:\Windows\System32\RunasSystem_x64.exe "C:\Windows\system32\RunFromToken64.exe explorer.exe 1 C:\Windows\System32\explorer.exe"
