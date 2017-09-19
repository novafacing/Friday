#FRIDAY 1.0 (Windows)

#ENV_VARS
$RUNDIR = $PSScriptRoot
$HOSTNAME = $env:computername

Write-Host "BASE_LEVEL_SCRIPT_"
Write-Host "CHECKING_RUN_ADMIN_"

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

Write-Host "Starting FRIDAY. Hello, Tony."
Write-Host "."
Start-Sleep -m 500
Write-Host "."
Start-Sleep -m 450
Write-Host "."
Start-Sleep -m 400
Write-Host "."
Start-Sleep -m 350
Write-Host "."
Start-Sleep -s 1
Write-Host "FRIDAY INITIALIZED."
Write-Host "Ready for some Cyber, Boss?"

$PromptForInstallProfile = new-object -comobject wscript.shell 
$PromptForInstallProfileAnswer = $PromptForInstallProfile.popup("Install Local Security Policy?", ` 0,"Install Policy",4) 
If ($PromptForInstallProfileAnswer -eq 6) { 
    Write-Host "Installing the Local Security Policy Profile, Boss."
	secedit /configure /db secedit.sdb /cfg "$RUNDIR\CONFIG.inf"
	Write-Host "That should do it, but you should probably check manually at some point, Boss."
} else { 
    Write-Host "Alright, Boss, skipping the Local Policy. That might not be the best idea."
}

$PromptForDisableBadServices = new-object -comobject wscript.shell 
$PromptForDisableBadServicesAnswer = $PromptForDisableBadServices.popup("Disable Bad Services?", ` 0,"Disable",4) 
If ($PromptForDisableBadServicesAnswer -eq 6) { 
    Write-Host "Okay Boss, disabling those nasy services now. I'm listing them below for you."
	Get-Service
	Write-Host "Boss, I need your input. Type in the services to stop, separated by spaces."
	Write-Host "They should look something like: RPCEptMapper or NetTcpPortSharing. It'll be the second left column, Boss."
	$ServiceArray = Read-Host "ENTER "
	$ServiceArray = $ServiceArray.Split(' ')
	for ($i=0; $i -lt $ServiceArray.length; $i++) {
		Get-Service $ServiceArray[$i] | Stop-Service -PassThru | Set-Service -StartupType disabled
	}
	Write-Host "Cleaned that one up for you."
} else { 
    Write-Host "Alright, Boss, skipping the services. The odds the services on this machine are clean are infinitely small."
}

$PromptForEnableFirewall = new-object -comobject wscript.shell 
$PromptForEnableFirewallAnswer = $PromptForEnableFirewall.popup("Enable Firewall?", ` 0,"Firewall",4) 
If ($PromptForEnableFirewallAnswer -eq 6) { 
    Write-Host "Enabling the Firewall. Good going, boss."
	Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
} else { 
    Write-Host "I'm going to be honest with you, Boss. That was a terrible idea."
}

$PromptForEnableDefender = new-object -comobject wscript.shell 
$PromptForEnableDefenderAnswer = $PromptForEnableDefender.popup("Enable Defender?", ` 0,"Defend",4) 
If ($PromptForEnableDefenderAnswer -eq 6) { 
    Write-Host "I'm turning on Windows Defender. Just to be safe, I'll update it and install additional tools."
	Write-Host "I lied, Boss. Defender won't work here, so I'm going to install MSE and MBAM."
	& "$RUNDIR\mb3-setup-consumer-3.0.6.1469.exe"
	& "$RUNDIR\MSEInstall.exe"
	Write-Host "That should keep it locked down pretty good, eh Boss?"
} else { 
    Write-Host "I'm not mad, Boss. I'm just disappointed."
}

$PromptForChangePasswords = new-object -comobject wscript.shell 
$PromptForChangePasswordsAnswer = $PromptForChangePasswords.popup("Change Passwords?", ` 0,"Passwords",4) 
If ($PromptForChangePasswordsAnswer -eq 6) { 
    Write-Host "Changing up those basic passwords."
	$DESIREDPASSWORD = Read-Host "ENTER PASSWORD "
	Get-WmiObject win32_useraccount | Foreach-Object { ([adsi]("WinNT://"+$_.caption).replace("\","/")).SetPassword("$DESIREDPASSWORD")}
	Write-Host "Passwords have been set to $DESIREDPASSWORD. Make sure to right that down, okay?"
	Write-Host "Accounts:"
	Get-WmiObject win32_useraccount 
	$DISABLEACCOUNTS = Read-Host "Any accounts to disable, separated by spaces. "
	$DISABLEACCOUNTS = $DISABLEACCOUNTS.Split(' ')
	$EnableUser = 512
	$DisableUser = 2
	$PasswordNotExpire = 65536
	$PasswordCantChange = 64
	Foreach($USER in $DISABLEACCOUNTS) { $USER = [ADSI]"WinNT://$HOSTNAME/$USER"
		$USER.userflags = $DisableUser+$PasswordNotExpire+$PasswordCantChange
		$USER.setinfo()
	}
	Write-Host "Boss, I can't set the Groups for you. I'm opening up Computer Management for you to do it."
	& compmgmt.msc
	Start-Sleep -s 5
	Write-Host "Keep going once you finish that. No rush, only preventing the end of the world."
} else { 
    Write-Host "You're going to have to do that by hand, Boss."
}


$PromptForDisableShares = new-object -comobject wscript.shell 
$PromptForDisableSharesAnswer = $PromptForDisableShares.popup("Disable Shares?", ` 0,"Share",4) 
If ($PromptForDisableSharesAnswer -eq 6) { 
    Write-Host "Disabling All Shares. I'd check the user share seperately though."
	$ShareArray = Get-WmiObject -Class Win32_Share
	Write-Host "Listing Shares."
	Write-Host $ShareArray
	$DISABLESHARES = Read-Host "Input the exact share names to disable, separated by spaces."
	$DISABLESHARES = $DISABLESHARES.Split(' ')
	Foreach($SHARE in $DISABLESHARES) {
		if ($ITEM = Get-WmiObject -Class Win32_Share `
			-ComputerName $HOSTNAME -Filter "Name=$SHARE") `
			{ $ITEM.delete() }
	}
	Write-Host "Disable ADMIN Shares? NOTE! Only do this on a machine that does not require SAMBA!"
	$INPUT = Read-Host "If you want to disale those shares, type Yes. Otherwise, type no."
	If ($INPUT -eq "Yes" -or $INPUT -eq "yes") {
		If($DisableAdminShares -eq $null) { 
			Try { 
				New-ItemProperty -Path $KeyPath -Name "AutoShareWKS" -Value 0 -PropertyType DWord | Out-Null 
				Write-Host "Disabled administrative shares successfully." -ForegroundColor Green 
				#Invoke prompt message 
				Get-Choice 
		} 
		Catch 
		{ 
			Write-Host "Failed to disable administrative shares." -ForegroundColor Red 
		} 
		} 	
	}
} else { 
    Write-Host "I know I'm just an AI, boss, but you don't have to treat me exactly like Ms. Potts."
}

$PromptForCreateResourceFiles = new-object -comobject wscript.shell 
$PromptForCreateResourceFilesAnswer = $PromptForCreateResourceFiles.popup("Create Resource Files?", ` 0,"Resource",4) 
If ($PromptForCreateResourceFilesAnswer -eq 6) { 
    Write-Host "I'm doing some scans now. This will take a while, so here is a list of things you can do in the mean time."
	Write-Host "Local Machine Group Users, Group Policy, Double-Check Settings, Group Policy (you really should do this one), "
	Write-Host "Creating files for: Media Files, Recursive Home Directory, "
	$excludeDirectories = ("Intel", "Logs")
	function Exclude-Directories {
		process {
			$allowThrough = $true
			foreach ($directoryToExclude in $excludeDirectories) {
				$directoryText = "*\" + $directoryToExclude
				$childText = "*\" + $directoryToExclude + "\*"
				if (($_.FullName -Like $directoryText -And $_.PsIsContainer) `
					-Or $_.FullName -Like $childText)
				{
					$allowThrough = $false
					break
				}
			}
			if ($allowThrough) {
				return $_
			}
		}
	}
	Clear-Host
	#Get-ChildItem -Path "C:\" -Recurse `
		#| Exclude-Directories | where {$_.Name -like "*.mp3" -or $_.Name -like "*.mp4" -or $_.Name -like "*.mov" -or $_.Name -like "*.avi" -or $_.Name -like "*.mpg" -or $_.Name -like "*.flac" -or $_.Name -like "*.m4a" -or $_.Name -like "*.flv" -or $_.Name -like "*.mkv" -or $_.Name -like "*.ogg" -or $_.Name -like "*.gif" -or $_.Name -like "*.png" -or $_.Name -like "*.jpg" -or $_.Name -like "*.jpeg" } > $RUNDIR\MediaFiles.txt
	#Get-ChildItem -Path "C:\" -Recurse `
		#| Exclude-Directories | where {$_.Name -like "*.exe" -or $_.Name -like "*.com" -or $_.Name -like "*.pif" -or $_.Name -like "*.bat" -or $_.Name -like "*.scr"} > $RUNDIR\PotentialMalware.txt
	Get-Service > $RUNDIR\Services.txt
	Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | select DisplayName, Publisher, InstallDate > $RUNDIR\InstalledPrograms.txt
	Get-NetFirewallRule > $RUNDIR\FirewallRules.txt
	Write-Host "Made some resource files in whatever directory you used to run me, Boss. You can check them at your leisure."
	} else { 
    Write-Host "You missed approximately 50 points of information."
}

$PromptForKillFTP = new-object -comobject wscript.shell 
$PromptForKillFTPAnswer = $PromptForKillFTP.popup("Delete FTP?", ` 0,"FTPDEL",4) 
If ($PromptForKillFTPAnswer -eq 6) { 
    Remove-Item C:\Windows\System32\ftp.exe
	Write-Host "Killed FTP for you, boss. Assuming you ran me as the System. Because I am....I am the System, Boss."
} else { 
    Write-Host "I hope FTP was required, otherwise that was a bad move."
}
$PromptForActivateAdminTools = new-object -comobject wscript.shell 
$PromptForActivateAdminToolsAnswer = $PromptForActivateAdminTools.popup("Delete FTP?", ` 0,"FTPDEL",4) 
If ($PromptForActivateAdminToolsAnswer -eq 6) { 
	Write-Host "Boss, there are some tools you may want to open next. I'm going to stay running and continue to give you a list of tools."
	Write-Host "Just type the toolname from the list and hit enter to open it."
	$TOOLLIST = (	"Windows Features : OptionalFeatures.exe", `
					"Group Policy Editor : gpedit.msc", `
					"Autoruns : Autoruns64.exe", `
					"Process Explorer :	 procexp64.exe", `
					"Logon Sessions Manager : logonsessions64.exe", `
					"Windows Object Viewer : Winobj.exe", `
					"EVERYTHING Searcher : Everything.exe", `
					"TYPE EXIT to close this script and end.")
	$SELECTEDTOOL = nul
	$EXITCONDITIONAL = "EXIT"
	While ($SELECTEDTOOL -ne $EXITCONDITIONAL) {
		Foreach ( $SELECTION in $TOOLLIST ) {
			Write-Host $SELECTION
		}
		$SELECTEDTOOL = Read-Host "Type the exact name of the service from above."
		& C:\Windows\System32\$SELECTEDTOOL 
	}
} else { 
    Write-Host "Hope this helped!"
}






