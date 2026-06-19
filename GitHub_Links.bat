@echo off
setlocal

echo ============================================
echo   SELECT A PROPERTY HTML FILE TO UPLOAD
echo ============================================

:: Open file picker
set "psCommand=Add-Type -AssemblyName System.Windows.Forms;$f=New-Object System.Windows.Forms.OpenFileDialog;$f.Filter='HTML Files (*.html)|*.html';$f.ShowDialog()|Out-Null;$f.FileName"
for /f "usebackq delims=" %%A in (`powershell -command "%psCommand%"`) do set "SELECTED=%%A"

if "%SELECTED%"=="" (
    echo No file selected.
    pause
    exit /b
)

echo.
echo FILE SELECTED:
echo %SELECTED%
echo.

:: Copy selected file into repo folder
copy "%SELECTED%" "%~dp0" >nul

set "FILENAME=%SELECTED%"
for %%f in ("%SELECTED%") do set "BASENAME=%%~nxf"

echo ============================================
echo   UPLOADING SELECTED FILE TO GITHUB
echo ============================================

git add "%BASENAME%"
git commit -m "Auto-upload single property page: %BASENAME%"
git push origin main

echo.
echo ============================================
echo   LINK FOR THIS FILE
echo ============================================

echo https://closingqueen.github.io/my-pages/%BASENAME%

echo.
echo ============================================
echo   DONE. ONLY THIS LINK SHOWN ABOVE.
echo ============================================
pause
