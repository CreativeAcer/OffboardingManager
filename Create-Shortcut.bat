@echo off
setlocal EnableDelayedExpansion

:: Get the script's directory
set "SCRIPT_DIR=%~dp0"

:: Run PowerShell script
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& '%SCRIPT_DIR%Create-OffboardingShortcut.ps1'"

if !ERRORLEVEL! EQU 0 (
    echo Shortcut created successfully!
) else (
    echo Failed to create shortcut.
    echo Please check if you have write permissions to the desktop.
)

pause