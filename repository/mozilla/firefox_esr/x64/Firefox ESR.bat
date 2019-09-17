:: Purpose:       Installs a package
:: Requirements:  Run this script with Administrator rights
:: Author:        vocatus on reddit.com/r/sysadmin ( vocatus.gate@gmail.com ) // PGP key ID: 0x07d1490f82a211a2
:: History:       1.0.4 ! Remove pre-existing autoconfig.js to prevent installation hang. Thanks to u/dimm0k
::                1.0.3 + Add additional uninstall commands make sure we fully remove old versions first. Thanks to github:abulgatz
::                1.0.2 * Add command line argument to preserve shortcuts, default to False
::                1.0.1 * Expand Desktop shortcut deletion mask to sweep all subdirectories under the base user profile directory
::                1.0.0 + Initial write


::::::::::
:: Prep :: -- Don't change anything in this section
::::::::::
@echo off
set SCRIPT_VERSION=1.0.4
set SCRIPT_UPDATED=2019-09-17
:: Get the date into ISO 8601 standard date format (yyyy-mm-dd) so we can use it
FOR /f %%a in ('WMIC OS GET LocalDateTime ^| find "."') DO set DTS=%%a
set CUR_DATE=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%

:: This is useful if we start from a network share; converts CWD to a drive letter
pushd "%~dp0"
cls

:: Check for command-line argument
set PRESERVE_SHORTCUTS=no
for %%i in (%*) do ( if /i %%i==--preserve-shortcuts set PRESERVE_SHORTCUTS=yes )


:::::::::::::::
:: VARIABLES :: -- Set these to your desired values
:::::::::::::::
:: Log location and name. Do not use trailing slashes (\)
set LOGPATH=%SystemDrive%\Logs
set LOGFILE=

:: Package to install. Do not use trailing slashes (\)
::if     exist "%ProgramFiles(x86)%" set BINARY="Firefox Setup 48.0.0 x64.exe"
::if not exist "%ProgramFiles(x86)%" set BINARY="Firefox Setup 48.0.0 x86.exe"
set BINARY=Mozilla Firefox ESR.exe
set FLAGS=/INI="%CD%\configuration.ini"

:: Create the log directory if it doesn't exist
if not exist %LOGPATH% mkdir %LOGPATH%


::::::::::::::::::
:: INSTALLATION ::
::::::::::::::::::
:: Kill Firefox first
%SystemDrive%\windows\system32\taskkill.exe /F /IM firefox.exe /T 2>NUL
wmic process where name="firefox.exe" call terminate 2>NUL

:: Remove old version first
IF EXIST "%ProgramFiles%\Mozilla Firefox\uninstall\helper.exe" "%ProgramFiles%\Mozilla Firefox\uninstall\helper.exe" /S
IF EXIST "%ProgramFiles(x86)%\Mozilla Firefox\uninstall\helper.exe" "%ProgramFiles(x86)%\Mozilla Firefox\uninstall\helper.exe" /S
wmic product where "name like 'Mozille Firefox%%'" call uninstall /nointeractive

:: Install the package from the local folder (if all files are in the same directory)
"%BINARY%" %FLAGS%

:: Install customizations, built with CCK2. Remove old config first, if present
if exist "%ProgramFiles(x86)%\Mozilla Firefox\defaults\pref\autoconfig.js" del /f /s "%ProgramFiles(x86)%\Mozilla Firefox\defaults\pref\autoconfig.js" 2>NUL
if exist "%ProgramFiles%\Mozilla Firefox\defaults\pref\autoconfig.js" del /f /s "%ProgramFiles%\Mozilla Firefox\defaults\pref\autoconfig.js" 2>NUL
if exist "%ProgramFiles(x86)%\Mozilla Firefox\" xcopy /s /e /y "autoconfig\*" "%ProgramFiles(x86)%\Mozilla Firefox"
if exist "%ProgramFiles%\Mozilla Firefox\" xcopy /s /e /y "autoconfig\*" "%ProgramFiles%\Mozilla Firefox"

:: Remove desktop icons
if %PRESERVE_SHORTCUTS%==no (
	del /f /s "%SystemDrive%\Users\*Firefox.lnk" 2>nul
)

:: Pop back to original directory. This isn't necessary in stand-alone runs of the script, but is needed when being called from another script
popd

:: Return exit code to SCCM/PDQ Deploy/etc
exit /B %EXIT_CODE%