@ECHO OFF
ECHO Processing CLSID permissions
SET SETACLX64=C:\windows\system32\setaclx64.exe
FOR /F "tokens=1,2,3,4,5 delims=\" %%A IN ('REG.EXE query HKLM\SOFTWARE\Classes\CLSID\') DO (
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E" -ot reg -actn setowner -ownr "n:S-1-5-32-544;s:y" -rec yes -silent
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E" -ot reg -actn ace -ace "n:S-1-5-32-544;p:full;s:y;i:so,sc;m:set;w:dacl" -rec yes -silent
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E" -ot reg -actn ace -ace "n:S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464;p:full;s:y;i:so,sc;m:revoke;w:dacl" -rec yes -silent
)

FOR /F "tokens=1,2,3,4,5 delims=\" %%A IN ('REG.EXE query HKCR\CLSID\') DO (
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E" -ot reg -actn setowner -ownr "n:S-1-5-32-544;s:y" -rec yes -silent
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E" -ot reg -actn ace -ace "n:S-1-5-32-544;p:full;s:y;i:so,sc;m:set;w:dacl" -rec yes -silent
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E" -ot reg -actn ace -ace "n:S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464;p:full;s:y;i:so,sc;m:revoke;w:dacl" -rec yes -silent
)

FOR /F "tokens=1,2,3,4,5,6 delims=\" %%A IN ('REG.EXE query HKLM\SOFTWARE\Classes\Wow6432Node\CLSID\') DO (
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E\%%F" -ot reg -actn setowner -ownr "n:S-1-5-32-544;s:y" -rec yes -silent
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E\%%F" -ot reg -actn ace -ace "n:S-1-5-32-544;p:full;s:y;i:so,sc;m:set;w:dacl" -rec yes -silent
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E\%%F" -ot reg -actn ace -ace "n:S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464;p:full;s:y;i:so,sc;m:revoke;w:dacl" -rec yes -silent
)

FOR /F "tokens=1,2,3,4,5,6 delims=\" %%A IN ('REG.EXE query HKCR\Wow6432Node\CLSID\') DO (
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E\%%F" -ot reg -actn setowner -ownr "n:S-1-5-32-544;s:y" -rec yes -silent
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E\%%F" -ot reg -actn ace -ace "n:S-1-5-32-544;p:full;s:y;i:so,sc;m:set;w:dacl" -rec yes -silent
	%SETACLX64% -on "%%A\%%B\%%C\%%D\%%E\%%F" -ot reg -actn ace -ace "n:S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464;p:full;s:y;i:so,sc;m:revoke;w:dacl" -rec yes -silent
)

ECHO Complete
	
	
