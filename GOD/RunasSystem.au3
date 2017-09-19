#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Start program from the local SYSTEM account
#AutoIt3Wrapper_Res_Description=Start program from the local SYSTEM account
#AutoIt3Wrapper_Res_Fileversion=1.0.0.2
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Most of the code is taken from wraithdu's examples
; Modified by Joakim
#include <WinAPI.au3>
Global Const $tagSTARTUPINFO1 = "dword cb;ptr lpReserved;ptr lpDesktop;ptr lpTitle;dword dwX;dword dwY;dword dwXSize;dword dwYSize;" & _
						"dword dwXCountChars;dword dwYCountChars;dword dwFillAttribute;dword dwFlags;ushort wShowWindow;" & _
						"ushort cbReserved2;ptr lpReserved2;ptr hStdInput;ptr hStdOutput;ptr hStdError"
Global Const $tagPROCESSINFO1 = "ptr hProcess;ptr hThread;dword dwProcessId;dword dwThreadId"
Global Const $NORMAL_PRIORITY_CLASS = 0x00000020
Global Const $CREATE_NEW_CONSOLE = 0x00000010
Global Const $CREATE_UNICODE_ENVIRONMENT = 0x00000400
Global $ghADVAPI32 = DllOpen("advapi32.dll")
_SetPrivilege("SeDebugPrivilege")
If @error Then exit

If $cmdline[0] = 0 Then
	$sCmdLine = "cmd.exe"
Else
	$sCmdLine = $cmdline[1]
EndIf
$sProcessAsUser = "winlogon.exe"

$dwSessionId = DllCall("kernel32.dll", "dword", "WTSGetActiveConsoleSessionId")
If @error Or $dwSessionId[0] = 0xFFFFFFFF Then
	ConsoleWrite("WTSGetActiveConsoleSessionId: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	Exit
EndIf
$dwSessionId = $dwSessionId[0]
ConsoleWrite("Running in session: " & $dwSessionId & @CRLF)
Dim $aProcs = ProcessList($sProcessAsUser), $processPID = -1, $ret
For $i = 1 To $aProcs[0][0]
	$ret = DllCall("kernel32.dll", "int", "ProcessIdToSessionId", "dword", $aProcs[$i][1], "dword*", 0)
	If Not @error And $ret[0] And ($ret[2] = $dwSessionId) Then
		$processPID = $aProcs[$i][1]
		ExitLoop
	EndIf
Next
ConsoleWrite("Host PID: " & $processPID & @CRLF)
If $processPID = -1 Then
	ConsoleWrite("Return 0 ; failed to get winlogon PID in current sessio")
	Exit
EndIf
Local $hProc = DllCall("kernel32.dll", "ptr", "OpenProcess", "dword", 0x001F0FFF, "int", 0, "dword", $processPID)
If @error Or Not $hProc[0] Then
	ConsoleWrite("OpenProcess: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	Exit
EndIf
$hProc = $hProc[0]
$hToken = DllCall($ghADVAPI32, "int", "OpenProcessToken", "ptr", $hProc, "dword", 0x2, "ptr*", 0)
If @error Or Not $hToken[0] Then
	ConsoleWrite("OpenProcessToken: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hProc)
	Exit
EndIf
$hToken = $hToken[3]
$hDupToken = DllCall($ghADVAPI32, "int", "DuplicateTokenEx", "ptr", $hToken, "dword", 0x1F0FFF, "ptr", 0, "int", 1, "int", 1, "ptr*", 0)
If @error Or Not $hDupToken[0] Then
	ConsoleWrite("DuplicateTokenEx: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hToken)
	DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hProc)
	Exit
EndIf
$hDupToken = $hDupToken[6]
$pEnvBlock = _GetEnvironmentBlock($sProcessAsUser, $dwSessionId) ; target process
$dwCreationFlags = BitOR($NORMAL_PRIORITY_CLASS, $CREATE_NEW_CONSOLE)
If $pEnvBlock Then $dwCreationFlags = BitOR($dwCreationFlags, $CREATE_UNICODE_ENVIRONMENT)
$SI = DllStructCreate($tagSTARTUPINFO1)
DllStructSetData($SI, "cb", DllStructGetSize($SI))
$PI = DllStructCreate($tagPROCESSINFO1)
$sDesktop = "winsta0\default"
$lpDesktop = DllStructCreate("wchar[" & StringLen($sDesktop) + 1 & "]")
DllStructSetData($lpDesktop, 1, $sDesktop)
DllStructSetData($SI, "lpDesktop", DllStructGetPtr($lpDesktop))
$ret = DllCall($ghADVAPI32, "bool", "CreateProcessWithTokenW", "handle", $hDupToken, "dword", 1, "ptr", 0, "wstr", $sCmdLine, "dword", $dwCreationFlags, "ptr", $pEnvBlock, "wstr", @WindowsDir, "ptr", DllStructGetPtr($SI), "ptr", DllStructGetPtr($PI))
If @error or Not $ret[0] Then
	$ret = DllCall($ghADVAPI32, "int", "CreateProcessAsUserW", "handle", $hDupToken, "ptr", 0, "wstr", $sCmdLine, "ptr", 0, "ptr", 0, "int", 0, "dword", $dwCreationFlags, "ptr", $pEnvBlock, "ptr", 0, "ptr", DllStructGetPtr($SI), "ptr", DllStructGetPtr($PI))
	If Not @error And $ret[0] Then
		ConsoleWrite("New process created successfully: " & DllStructGetData($PI, "dwProcessId") & @CRLF)
		DllCall("kernel32.dll", "int", "CloseHandle", "ptr", DllStructGetData($PI, "hThread"))
		DllCall("kernel32.dll", "int", "CloseHandle", "ptr", DllStructGetData($PI, "hProcess"))
	Else
		ConsoleWrite("CreateProcessAsUserW / CreateProcessWithTokenW: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	EndIf
EndIf

If $pEnvBlock Then DllCall("userenv.dll", "int", "DestroyEnvironmentBlock", "ptr", $pEnvBlock)
DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hDupToken)
DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hToken)
DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hProc)


Func _GetEnvironmentBlock($sProcess, $dwSession)
	Local Const $MAXIMUM_ALLOWED1 = 0x02000000
	Local Const $dwAccess = BitOR(0x2, 0x8) ; TOKEN_DUPLICATE | TOKEN_QUERY

	; get PID of process in current session
	Local $aProcs = ProcessList($sProcess), $processPID = -1, $ret = 0
	For $i = 1 To $aProcs[0][0]
		$ret = DllCall("kernel32.dll", "int", "ProcessIdToSessionId", "dword", $aProcs[$i][1], "dword*", 0)
		If Not @error And $ret[0] And ($ret[2] = $dwSession) Then
			$processPID = $aProcs[$i][1]
			ExitLoop
		EndIf
	Next
	If $processPID = -1 Then Return 0 ; failed to get PID
	; open process
	Local $hProc = DllCall("kernel32.dll", "ptr", "OpenProcess", "dword", 0x02000000, "int", 0, "dword", $processPID)
	If @error Or Not $hProc[0] Then Return 0
	$hProc = $hProc[0]
	; open process token
	$hToken = DllCall($ghADVAPI32, "int", "OpenProcessToken", "ptr", $hProc, "dword", $dwAccess, "ptr*", 0)
	If @error Or Not $hToken[0] Then
		ConsoleWrite("OpenProcessToken: " & _WinAPI_GetLastErrorMessage() & @CRLF)
		DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hProc)
		Return 0
	EndIf
	$hToken = $hToken[3]
	; create a new environment block
	Local $pEnvBlock = DllCall("userenv.dll", "int", "CreateEnvironmentBlock", "ptr*", 0, "ptr", $hToken, "int", 1)
	If Not @error And $pEnvBlock[0] Then $ret = $pEnvBlock[1]
	; close handles
	DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hToken)
	DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hProc)
	Return $ret
EndFunc

Func _SetPrivilege($Privilege)
    Local $tagLUIDANDATTRIB = "int64 Luid;dword Attributes"
    Local $count = 1
    Local $tagTOKENPRIVILEGES = "dword PrivilegeCount;byte LUIDandATTRIB[" & $count * 12 & "]" ; count of LUID structs * sizeof LUID struct
    Local $TOKEN_ADJUST_PRIVILEGES = 0x20
    Local $SE_PRIVILEGE_ENABLED = 0x2

    Local $curProc = DllCall("kernel32.dll", "ptr", "GetCurrentProcess")
	Local $call = DllCall("advapi32.dll", "int", "OpenProcessToken", "ptr", $curProc[0], "dword", $TOKEN_ALL_ACCESS, "ptr*", "")
    If Not $call[0] Then Return False
    Local $hToken = $call[3]

    $call = DllCall("advapi32.dll", "int", "LookupPrivilegeValue", "str", "", "str", $Privilege, "int64*", "")
    Local $iLuid = $call[3]

    Local $TP = DllStructCreate($tagTOKENPRIVILEGES)
	Local $TPout = DllStructCreate($tagTOKENPRIVILEGES)
    Local $LUID = DllStructCreate($tagLUIDANDATTRIB, DllStructGetPtr($TP, "LUIDandATTRIB"))

    DllStructSetData($TP, "PrivilegeCount", $count)
    DllStructSetData($LUID, "Luid", $iLuid)
    DllStructSetData($LUID, "Attributes", $SE_PRIVILEGE_ENABLED)

    $call = DllCall("advapi32.dll", "int", "AdjustTokenPrivileges", "ptr", $hToken, "int", 0, "ptr", DllStructGetPtr($TP), "dword", DllStructGetSize($TPout), "ptr", DllStructGetPtr($TPout), "dword*", 0)
	If @error OR $call[0] = 0 Then
		ConsoleWrite("AdjustTokenPrivileges: " & _WinAPI_GetLastErrorMessage() & @CRLF)
		Return SetError(1,0,0)
	EndIf

    DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hToken)
    Return ($call[0] <> 0) ; $call[0] <> 0 is success
EndFunc

