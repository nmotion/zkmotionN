@echo off
setlocal
setlocal enabledelayedexpansion
set ScriptHome=%~d0%~p0
set BinHome=%ScriptHome%\
set path=%ScriptHome%;%ScriptHome%\;%path%
set exitval=0

set DeviceName=LPCScrypt target
set BootImageWild=LPCScrypt*.hdr 
set updateImageWild=*REC.bin
 
set DfuLog=%temp%\dfu-util.log
call :getDfuVidPid
if "%DfuVidPid%" == "" goto :NoDfus

if "%1" == "" (
	call :getBootImage
) else (
	set BootImage=%1
) 

if "%BootImage%" == "" goto :NoBootImage

:DfuApp
::for %%i in (%BootImage%) do set ShortBootImage="%%~nxi"
::echo Booting %DeviceName% with %ShortBootImage%  
 echo  prepare to update
set boot_options=-d 0x1fc9:c -c 0 -i 0 -t 2048 -R -D "%BootImage%"

dfu-util %boot_options% >NUL 2>%DfuLog%
if %errorlevel% equ 0 (
::echo %DeviceName% booted
 echo  connect good! 
) else (
::  echo %DeviceName% boot failed:
echo some erro happend!
  type %DfuLog%
  set exitval=3
  exit /b %exitval%
)
goto :updatefirm

:Usage
echo Usage: %0
goto :end

:updatefirm
if "%2" == "" (
	call :getupdateImage
) else (
	set updateImage=%2
) 
choice /t 1 /d y /n >nul 
for %%i in (%updateImage%) do set ShortBootImage="%%~nxi"
 echo  update to %ShortBootImage% 
setlocal
setlocal enabledelayedexpansion
lpcscrypt erase BankB
lpcscrypt program "%updateImage%" BankB  65535
:end
 pause
exit /b %exitval%

:NoDfus
%echo Nothing to boot! %
echo Nothing to run or some error happend!
set exitval=1
goto :end

:NoBootImage
%echo No boot image found%
echo some erro happend!
set exitval=2
exit
::goto :end

:getDfuVidPid
for /f "skip=6 tokens=3" %%a in ('dfu-util -l') do (
  set DfuVidPid=%%a
)
:eof

:getBootImage
for /r "%BinHome%" %%f in (%BootImageWild%) do (
  set BootImage=%%f
)
:eof
:getupdateImage
for /r "%BinHome%" %%f in (%updateImageWild%) do (
  set updateImage=%%f
)
:eof
