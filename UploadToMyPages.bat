@echo off
REM Super simple double-click launcher for the GitHub HTML uploader.
REM This opens file picker, uploads the chosen HTML to your my-pages repo,
REM then gives you a permanent shareable link that works after you close this window.

title Upload HTML to GitHub Pages

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0UploadToMyPages.ps1"

echo.
echo (Window will stay open until you press a key in the PowerShell window)
pause >nul
