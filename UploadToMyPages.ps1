# UploadToMyPages.ps1
# Super simple: Double-click the matching .bat to run this.
# Picks an HTML file -> copies to your GitHub Pages repo -> commits & pushes -> copies the live URL.

$ErrorActionPreference = 'Stop'

# === Your GitHub Pages repo info (URL part) ===
$githubUser = "closingqueen"
$repoName   = "my-pages"

# SUPER SIMPLE: If this script lives inside the my-pages folder, use its own folder.
# This ties the uploader directly to your main folder - no fragile paths.
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$repoPath = $scriptDir

# If for some reason it's not, fall back to the known location or let user pick.
if (-not (Test-Path -LiteralPath (Join-Path $repoPath '.git'))) {
    $repoPath = "C:\Users\Jamie\Dropbox\Work_Companies (Selective Sync Conflict)\Acquire JDF\Coding Scripts\GitHub\my-pages"
    if (-not (Test-Path -LiteralPath (Join-Path $repoPath '.git'))) {
        Add-Type -AssemblyName System.Windows.Forms
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = "Select your 'my-pages' folder (contains .git)"
        $folderDialog.ShowNewFolderButton = $false
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $repoPath = $folderDialog.SelectedPath
        }
    }
}

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   Upload HTML -> GitHub Pages (persistent)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# --- Sanity checks ---
if (-not (Test-Path -LiteralPath $repoPath)) {
    Write-Host "ERROR: Could not find the repo folder at: $repoPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $repoPath '.git'))) {
    Write-Host "ERROR: The selected folder is not a git repo (missing .git)." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Pick the HTML file ---
Add-Type -AssemblyName System.Windows.Forms

$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = "Select HTML file to host on GitHub"
$dialog.Filter = "HTML files (*.html;*.htm)|*.html;*.htm|All files (*.*)|*.*"
$dialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
$dialog.Multiselect = $false

if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "Cancelled. No file chosen." -ForegroundColor Yellow
    Read-Host "Press Enter to close"
    exit
}

$sourcePath = $dialog.FileName
$fileName   = [System.IO.Path]::GetFileName($sourcePath)

Write-Host "Selected file : $fileName" -ForegroundColor Green
Write-Host ""

# --- Copy into the repo ---
$destPath = Join-Path -Path $repoPath -ChildPath $fileName
Copy-Item -LiteralPath $sourcePath -Destination $destPath -Force
Write-Host "Copied to repo folder." -ForegroundColor Green

# --- Git add / commit / push ---
Push-Location -LiteralPath $repoPath
try {
    & git add -- "$fileName" 2>$null

    $hasChanges = (& git status --porcelain -- "$fileName")
    if (-not $hasChanges) {
        Write-Host "No new changes (file is identical to what's already on GitHub)." -ForegroundColor Yellow
    } else {
        & git commit -m "Quick upload: $fileName" | Out-Null
        Write-Host "Committed locally." -ForegroundColor Green

        Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
        & git push origin main
        if ($LASTEXITCODE -ne 0) {
            throw "git push failed (exit code $LASTEXITCODE). Check your internet / credentials."
        }
        Write-Host "Pushed to GitHub!" -ForegroundColor Green
    }
} catch {
    Write-Host ""
    Write-Host "ERROR during git operations:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Gray
    Write-Host "  - Make sure Git is installed" -ForegroundColor Gray
    Write-Host "  - Run the script, then do a manual 'git push' once to login if needed" -ForegroundColor Gray
    Write-Host "  - Or install GitHub CLI (gh) and run: gh auth login" -ForegroundColor Gray
    Pop-Location
    Read-Host "Press Enter to exit"
    exit 1
} finally {
    Pop-Location
}

# --- Build the public URL ---
# Use proper encoding so spaces and special chars work in the browser link
$encoded = [System.Uri]::EscapeDataString($fileName)
$url = "https://$githubUser.github.io/$repoName/$encoded"

# Copy to clipboard
$copied = $false
try {
    Set-Clipboard -Value $url -ErrorAction Stop
    $copied = $true
} catch {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.Clipboard]::SetText($url)
        $copied = $true
    } catch {}
}

# --- Done ---
Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "   DONE!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your file is now hosted here:" -ForegroundColor White
Write-Host ""
Write-Host $url -ForegroundColor Cyan
Write-Host ""

if ($copied) {
    Write-Host "✓ Link copied to your clipboard - just paste it anywhere!" -ForegroundColor Green
} else {
    Write-Host "(Select the link above and copy it manually)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Note: First publish can take 10-60 seconds on GitHub's side." -ForegroundColor DarkGray
Write-Host "After that it is live forever (even if you close this window)." -ForegroundColor DarkGray
Write-Host ""
Read-Host "Press Enter to close this window"
