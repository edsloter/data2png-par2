# 1. Elevate the script to Administrator context while preserving the current folder scope
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Admin privileges required for dependency setup. Relaunching..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args" -Verb RunAs
    Exit
}

Write-Host "[*] Initializing environment pre-flight check..." -ForegroundColor Cyan

# 2. Verify MultiPar CLI binary files are present in the repository folder structure
$par2j64Path = Join-Path $PSScriptRoot "par2j64.exe"
$par2jPath   = Join-Path $PSScriptRoot "par2j.exe"
$par1jPath   = Join-Path $PSScriptRoot "par1j.exe"

Write-Host "[*] Scanning repository for MultiPar CLI utilities..." -ForegroundColor Cyan

$engineFound = $false
$targetEngine = ""

if (Test-Path $par2j64Path) {
    Write-Host "[+] Found 64-bit engine: par2j64.exe" -ForegroundColor Green
    $targetEngine = "par2j64.exe"
    $engineFound = $true
}
if (Test-Path $par2jPath) {
    Write-Host "[+] Found 32-bit engine: par2j.exe" -ForegroundColor Green
    if (-not $engineFound) { $targetEngine = "par2j.exe"; $engineFound = $true }
}
if (Test-Path $par1jPath) {
    Write-Host "[+] Found Legacy engine: par1j.exe" -ForegroundColor Green
    if (-not $engineFound) { $targetEngine = "par1j.exe"; $engineFound = $true }
}

if (-not $engineFound) {
    Write-Host "`n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
    Write-Host " ERROR: MultiPar CLI binaries are missing from the repo!" -ForegroundColor Red
    Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!`n" -ForegroundColor Red
    Write-Host "Please place your MultiPar command-line executables:" -ForegroundColor White
    Write-Host " (par2j64.exe, par2j.exe, or par1j.exe)" -ForegroundColor Yellow
    Write-Host "directly into the folder: $PSScriptRoot" -ForegroundColor White
    Exit 1
}

# Bind local repo engine dynamically to the temporary system environment PATH parameter
if ($env:Path -notlike "*$PSScriptRoot*") {
    $env:Path = "$env:Path;$PSScriptRoot"
}
Write-Host "[+] System Dependency: Using local MultiPar backend ($targetEngine)." -ForegroundColor Green


# 3. Targeted Deep Scan for User-Level Python (Bypasses Microsoft Store Broken App Aliases)
Write-Host "[*] Locating valid Python system context..." -ForegroundColor Cyan

$pythonCmd = ""
$actualUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$userPythonBase = "C:\Users\$actualUser\AppData\Local\Programs\Python"

# First, perform a targeted scan of the standard user AppData program path
if (Test-Path $userPythonBase) {
    # Scan for python.exe inside the versioned folders (e.g., Python311, Python312)
    $foundPython = Get-ChildItem -Path $userPythonBase -Filter "python.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($foundPython) {
        $pythonCmd = $foundPython.FullName
        Write-Host "[+] Found authentic Python executable via AppData Deep Scan: $pythonCmd" -ForegroundColor Green
    }
}

# If the deep scan didn't find anything, test the global system command but strictly filter out MS Store paths
if ([string]::IsNullOrEmpty($pythonCmd)) {
    $systemPython = Get-Command python -ErrorAction SilentlyContinue
    if ($systemPython -and ($systemPython.Source -notlike "*WindowsApps*")) {
        $pythonCmd = "python"
        Write-Host "[+] Using system-wide Python installation." -ForegroundColor Green
    }
    else {
        $systemPython3 = Get-Command python3 -ErrorAction SilentlyContinue
        if ($systemPython3 -and ($systemPython3.Source -notlike "*WindowsApps*")) {
            $pythonCmd = "python3"
            Write-Host "[+] Using system-wide Python3 installation." -ForegroundColor Green
        }
    }
}

# If everything fails, report a clear error and halt execution
if ([string]::IsNullOrEmpty($pythonCmd)) {
    Write-Host "`n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
    Write-Host " ERROR: Authentic Python installation could not be located." -ForegroundColor Red
    Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!`n" -ForegroundColor Red
    Write-Host "The script only sees the broken Microsoft Store app shortcuts." -ForegroundColor White
    Write-Host "Please ensure Python is installed and check 'Add python.exe to PATH' during installation." -ForegroundColor Yellow
    Exit 1
}


# 4. Check and install Python library requirements using the explicit path mapping verified above
Write-Host "[*] Verifying Pillow library inside target Python environment..." -ForegroundColor Cyan
& $pythonCmd -c "import PIL" 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "[*] Python Pillow library is missing. Initializing targeted dependency installer..." -ForegroundColor Cyan
    # Run pip as a module through the explicitly mapped python path to completely bypass environment path issues
    & $pythonCmd -m pip install --upgrade pip --quiet 2>$null
    & $pythonCmd -m pip install Pillow
    
    # Final confirmation check
    & $pythonCmd -c "import PIL" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] Critical Error: Pillow module installation failed automatically." -ForegroundColor Red
        Write-Host "Please run manually: $pythonCmd -m pip install Pillow" -ForegroundColor Yellow
        Exit 1
    }
}
Write-Host "[+] Python Dependency: Pillow verified." -ForegroundColor Green


# 5. Structural verification for core file asset 
$vaultScriptPath = Join-Path $PSScriptRoot "vault.py"
if (-not (Test-Path $vaultScriptPath)) {
    Write-Host "[!] Error: Core file matrix asset (vault.py) was not found in: $PSScriptRoot" -ForegroundColor Red
    Exit 1
}


# 6. Parse arguments or dump CLI layout guidelines if empty
if ($args.Count -eq 0) {
    Write-Host "`n[+] Environment Secure! Usage Example:" -ForegroundColor Green
    Write-Host ".\vault.ps1 encode -i <file> -o <out_dir> -p 30" -ForegroundColor White
    Exit 0
}

Write-Host "[+] Environment secure. Passing arguments to core system..." -ForegroundColor Green
Write-Host "--------------------------------------------------------"


# 7. Launch underlying core logic application task forwarding parameters safely
& $pythonCmd $vaultScriptPath $args
