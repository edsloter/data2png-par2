# data2png-par2
A secure, self-healing data archival tool that transforms any arbitrary file into a lossless grid of RGB pixel matrices (.png files), guarded by automated 64-bit multi-threaded MultiPar error correction.

# 🏺 Self-Healing Data-to-PNG Pixel Matrix Vault

A high-density, fault-tolerant binary steganography and data archiving engine. This system converts any arbitrary binary file (archives, executables, multimedia) into a losslessly structured sequence of RGB pixel maps (`.png` files). 

Unlike standard data-to-image scripts, this implementation incorporates a **100% self-healing architecture** utilizing a multi-threaded 64-bit MultiPar backend (`par2j64.exe`). If any of your generated PNG files are deleted, renamed, or corrupted (e.g., scribbled on in MS Paint), the decompression engine will completely heal the missing dataset automatically on the fly and restore your original binary file bit-for-bit.

---

## ✨ Features
* **Maximum RGB Density:** Packs 3 raw bytes per pixel across all color channels (Red, Green, Blue).
* **Pure Image Setup:** Parity and indexing data are translated into PNG files as well—no need to manage separate `.par2` configuration files.
* **Autonomous Self-Healing:** Powered by **MultiPar (`par2j64.exe`)**. Fully capable of rebuilding missing slices even if deep bit rot or hard sector deletion occurs.
* **Intelligent PowerShell Wrapper:** Dynamically bypasses broken Windows App Execution Aliases, intercepts hidden user-level Python path arrays, automatically elevates permissions, and verifies system dependencies before launch.
* **Pre-Flight Manifest Projection:** Displays an accurate calculation of your target image matrix footprint before executing disk-write sequences.

---

## 🛠️ Repository File Architecture
To execute successfully, maintain the following file layout in your working directory:
```text
📂 data2png-par2/
├── 📄 vault.ps1      # PowerShell Context Wrapper & Environment Configurator
├── 📄 vault.py       # Core Layout Processing Matrix & Slice Coordinator
├── 📄 vault.sh       # Linux Native Wrapper
└── ⚙️ par2j64.exe     # MultiPar 64-bit Command Line Processing Engine
```

---

## ⚙️ Operational Mechanics

1. **Encoding Execution Flow:**
   * Your target binary asset is chopped into standardized chunks.
   * `par2j64.exe` analyzes the blocks and builds Reed-Solomon error-correcting matrices.
   * The binary blocks and the parity blocks are assigned an 8-byte big-endian metadata header tracking their exact file size footprint.
   * Chunks are translated into lossless square RGB PNGs. Extensions are transformed to safe tokens (`_dot_`) to protect MultiPar's multiple-period file architectures from breaking.

2. **Decoding & Self-Healing Execution Flow:**
   * Pixel matrices across your target folder are parsed and mapped back to their byte coordinates inside a hidden `.tmp_repair` workspace.
   * The engine hooks into `par2j64.exe` to review data alignments against bitwise status flags (e.g., success code `272`).
   * If frames are missing or corrupted, the MultiPar matrix heals them completely onto your hard drive.
   * Verified slices are stitched together into your restored file, and the temporary folder is securely wiped.

---

## 🚀 Usage Guide & Syntax

Always run operations through the PowerShell wrapper script (`vault.ps1`). It will handle terminal elevation automatically.

### 📥 1. Encoding (File to PNG Matrix)
Translates a file into a folder of self-healing images.

```powershell
.\vault.ps1 encode -i <input_file> -o <output_directory> [-p <parity_pct>] [-r <resolution>]
```

#### Example Command:
```powershell
.\vault.ps1 encode -i "data.bin" -o ".\all_png_vault" -p 35 -r "1024x1024"
```

#### Manifest Preview Output:
```text
==================================================
             ENCODING PREVIEW MANIFEST          
==================================================
 Source File:         data.bin
 File Size:           189,439,111 bytes
 Target Canvas Size:  1024x1024 pixels
 Target Redundancy:   35%
--------------------------------------------------
 Payload PNG Data Slices:   61
 Parity (PAR2) PNG Slices:  ~23
 TOTAL PNG FILES TO GENERATE: 84
==================================================
Proceed with encoding? (y/n): y
```

### 📤 2. Decoding (PNG Vault to Restored File)
Re-assembles, verifies, auto-heals, and extracts your payload asset.

```powershell
.\vault.ps1 decode -i <input_directory> -o <output_file>
```

#### Example Command:
```powershell
.\vault.ps1 decode -i ".\all_png_vault" -o "restored_data.bin"
```

---

## 🎛️ Command Flags & Parameter Breakdown

### `encode` Mode Flags
* `-i`, `--input` (Required): The full or relative path to the source binary file you want to compress into an image matrix.
* `-o`, `--output-dir` (Required): Target folder directory path where the generated `.png` frame assets will be securely saved. **Note:** This folder is cleaned on execution.
* `-p`, `--parity` (Optional, Default: `30`): The fault-tolerance redundancy percentage calculation.
  * **`10`–`15`**: Low overhead, small file array, protects against minor bit rot.
  * **`25`–`35`**: Balanced sweet spot. Reconstructs missing files smoothly.
  * **`50`+**: Maximum security. You can delete up to half of the generated PNGs, and your data remains 100% restorable.
* `-r`, `--resolution` (Optional, Default: `1024x1024`): Frame canvas scale mapping format. Specify dimension configurations like `"1920x1080"` or square arrays like `"1024x1024"`.

### `decode` Mode Flags
* `-i`, `--input-dir` (Required): The folder containing the vault's sequential PNG file frames you want to read.
* `-o`, `--output-file` (Required): Clean storage file destination path where the reconstructed binary asset will be written.

---

## 🧪 Simulating a Fault-Tolerance Test
To confirm your system is running correctly:
1. Run the `encode` example command on a large file.
2. Open your `.\all_png_vault` folder and **completely delete 5 random PNG files**.
3. Open a 6th PNG file in **MS Paint**, draw a red line across it, and click save.
4. Execute the `decode` command. 

You will witness `par2j64.exe` step in, trace the damaged data channels, log a bitwise warning code `272` (confirming repair of altered pixel tracks), rebuild the missing images perfectly, and merge them into a bit-perfect copy of your source file.
