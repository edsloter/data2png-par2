#!/bin/bash
# Exit immediately if any command exits with a non-zero status
set -e

echo "[*] Initializing environment pre-flight check (Linux/WSL)..."

# 1. Verify/Install native Linux par2 engine tool
if ! command -v par2 &> /dev/null; then
    echo "[!] 'par2' utility is missing. Attempting automated package installation..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update --fix-missing
        sudo apt-get install -y --fix-missing par2
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm par2cmdline
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y par2cmdline
    else
        echo "[!] Error: Package manager not recognized. Please manually install 'par2'."
        exit 1
    fi
else
    echo "[+] Linux System Dependency: 'par2' engine verified."
fi

# 2. Locate or install Linux Python 3 executable context
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "[!] Error: Python is not installed. Attempting recovery..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y python3 python3-pip
        PYTHON_CMD="python3"
    else
        echo "[!] Error: Native Python missing and auto-install is unsupported on this distro."
        exit 1
    fi
fi

# 3. Handle Python Pillow dependency installation natively via apt to bypass PEP 668 pip blocks
if ! "$PYTHON_CMD" -c "import PIL" &> /dev/null; then
    echo "[*] Python 'Pillow' library is missing. Resolving dependencies..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y python3-pil python3-pillow || "$PYTHON_CMD" -m pip install --break-system-packages Pillow
    else
        "$PYTHON_CMD" -m pip install Pillow
    fi
else
    echo "[+] Python Dependency: 'Pillow' verified."
fi

# 4. Verification for core script asset
if [ ! -f "vault.py" ]; then
    echo "[!] Error: Core file matrix asset (vault.py) was not found in this directory."
    exit 1
fi

# 5. Handle empty syntax layouts arguments check
if [ $# -eq 0 ]; then
    echo ""
    echo "[+] Environment Secure! Linux Usage Example:"
    echo "    chmod +x vault.sh"
    echo "    ./vault.sh encode -i <file> -o <out_dir> -p 35"
    exit 0
fi

echo "[+] Environment secure. Passing arguments to core system..."
echo "--------------------------------------------------------"

# 6. Run unified Python architecture core
exec "$PYTHON_CMD" vault.py "$@"
