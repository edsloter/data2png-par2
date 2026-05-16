import os
import sys
import math
import struct
import subprocess
import glob
import argparse
import shutil
from PIL import Image

def is_par2_installed():
    return shutil.which("par2j64.exe") is not None

def run_command(cmd, is_repair=False):
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Exit 0: Completely clean dataset (No repair needed)
        if result.returncode == 0:
            return True
            
        # MultiPar (par2j64) uses bitwise masks when repairs succeed with warnings.
        # Common success codes include 1, 257, 272, etc. If the log explicitly says
        # "Repaired successfully", we intercept it as a successful run.
        stdout_str = result.stdout.decode(errors='ignore') if result.stdout else ""
        if is_repair and ("Repaired successfully" in stdout_str or "No repair is needed" in stdout_str):
            return True
            
        print(f"\n[!] MultiPar Engine failed with exit code: {result.returncode}")
        if result.stdout:
            print(f"Engine Output:\n{stdout_str.strip()}")
        if result.stderr:
            print(f"Engine Error Log:\n{result.stderr.decode(errors='ignore').strip()}")
        return False
    except Exception as e:
        print(f"\n[!] Error attempting execution command sequence: {str(e)}")
        return False

def bytes_to_png(data, output_path, resolution):
    width, height = resolution
    bytes_per_frame = width * height * 3
    file_size = len(data)
    header = struct.pack('>Q', file_size)
    full_payload = header + data
    if len(full_payload) < bytes_per_frame:
        full_payload += b'\x00' * (bytes_per_frame - len(full_payload))
    else:
        full_payload = full_payload[:bytes_per_frame]
    img = Image.frombytes('RGB', (width, height), full_payload)
    img.save(output_path, 'PNG')

def png_to_bytes(png_path):
    if not os.path.exists(png_path):
        return None
    img = Image.open(png_path).convert('RGB')
    raw_stream = img.tobytes()
    if len(raw_stream) < 8:
        return b""
    file_size = struct.unpack('>Q', raw_stream[:8])[0]
    return raw_stream[8:8 + file_size]

def calculate_manifest(source_file, redundancy_pct, resolution):
    file_size = os.path.getsize(source_file)
    width, height = resolution
    bytes_per_frame = width * height * 3
    chunk_capacity = bytes_per_frame - 8
    data_chunks = math.ceil(file_size / chunk_capacity)
    approx_par2_bytes = (file_size) * (redundancy_pct / 100.0)
    par2_chunks = math.ceil(approx_par2_bytes / chunk_capacity)
    total_expected_pngs = data_chunks + par2_chunks + 1 
    
    print("=" * 50)
    print("             ENCODING PREVIEW MANIFEST          ")
    print("=" * 50)
    print(f" Source File:         {os.path.basename(source_file)}")
    print(f" File Size:           {file_size:,} bytes")
    print(f" Target Canvas Size:  {width}x{height} pixels")
    print(f" Target Redundancy:   {redundancy_pct}%")
    print("-" * 50)
    print(f" Payload PNG Data Slices:   {data_chunks}")
    print(f" Parity (PAR2) PNG Slices:  ~{par2_chunks + 1}")
    print(f" TOTAL PNG FILES TO GENERATE: {total_expected_pngs}")
    print("=" * 50)
    return total_expected_pngs

def encode_pure_png_vault(source_file, vault_dir, redundancy_pct, resolution):
    calculate_manifest(source_file, redundancy_pct, resolution)
    confirm = input("Proceed with encoding? (y/n): ").strip().lower()
    if confirm != 'y':
        print("Encoding canceled.")
        return

    if os.path.exists(vault_dir):
        shutil.rmtree(vault_dir)
    os.makedirs(vault_dir)
    
    tmp_dir = os.path.join(vault_dir, ".tmp_par2")
    os.makedirs(tmp_dir, exist_ok=True)
    
    with open(source_file, 'rb') as f:
        src_data = f.read()
        
    width, height = resolution
    bytes_per_pixel_frame = width * height * 3
    chunk_capacity = bytes_per_pixel_frame - 8
    total_chunks = math.ceil(len(src_data) / chunk_capacity)
    
    print(f"\n[*] Slicing raw bits into {total_chunks} data files...")
    data_filenames = []
    for i in range(total_chunks):
        start = i * chunk_capacity
        end = min(start + chunk_capacity, len(src_data))
        slice_data = src_data[start:end]
        slice_name = f"data_part_{i:04d}.bin"
        with open(os.path.join(tmp_dir, slice_name), "wb") as f_slice:
            f_slice.write(slice_data)
        data_filenames.append(slice_name)
        
    print(f"[*] Compiling MultiPar 64-bit correction frames...")
    original_cwd = os.getcwd()
    os.chdir(tmp_dir)
    
    par2_cmd = ["par2j64.exe", "c", f"/rr{redundancy_pct}", "recovery.par2"] + data_filenames
    success = run_command(par2_cmd)
    os.chdir(original_cwd)
    
    if not success:
        print("[!] Execution halted: Could not calculate PAR2 data blocks.")
        return
        
    all_workspace_files = sorted(os.listdir(tmp_dir))
    print(f"[*] Packaging final pure PNG archive vault...")
    for idx, fname in enumerate(all_workspace_files):
        with open(os.path.join(tmp_dir, fname), "rb") as f_in:
            file_bytes = f_in.read()
        
        sanitized_name = fname.replace(".", "_dot_")
        png_out_path = os.path.join(vault_dir, f"vault_frame_{idx:04d}_{sanitized_name}.png")
        bytes_to_png(file_bytes, png_out_path, resolution)
        os.remove(os.path.join(tmp_dir, fname))
        
    os.rmdir(tmp_dir)
    print(f"\n[+] Success! Pure image archive array fully created in: '{vault_dir}'")

def decode_pure_png_vault(vault_dir, output_restored_path):
    if not os.path.exists(vault_dir):
        print(f"Error: Target directory '{vault_dir}' does not exist.")
        return
    png_files = sorted([f for f in os.listdir(vault_dir) if f.endswith('.png')])
    if not png_files:
        print("Error: Target folder does not contain any vault PNG files.")
        return
        
    tmp_dir = os.path.join(vault_dir, ".tmp_repair")
    if os.path.exists(tmp_dir):
        shutil.rmtree(tmp_dir)
    os.makedirs(tmp_dir, exist_ok=True)
    
    print("[*] Reconstituting binary arrays out of pixel maps...")
    for png in png_files:
        parts = png.split('_')
        if len(parts) < 4:
            continue
        
        joined_raw_name = "_".join(parts[3:])
        if joined_raw_name.endswith(".png"):
            joined_raw_name = joined_raw_name[:-4]
            
        orig_name = joined_raw_name.replace("_dot_", ".")
        
        raw_bytes = png_to_bytes(os.path.join(vault_dir, png))
        if raw_bytes is not None:
            with open(os.path.join(tmp_dir, orig_name), "wb") as f_out:
                f_out.write(raw_bytes)
                
    print("[*] Launching system self-healing check matrix via par2j64...")
    original_cwd = os.getcwd()
    os.chdir(tmp_dir)
    repair_cmd = ["par2j64.exe", "r", "recovery.par2"]
    repair_success = run_command(repair_cmd, is_repair=True)
    os.chdir(original_cwd)
    
    if not repair_success:
        print("[!] Critical Failure: Corruption parameters out of repair boundary.")
        shutil_cleanup(tmp_dir)
        return
        
    print("[*] Validation passed. Synchronizing components into target binary format...")
    binary_slices = sorted(glob.glob(os.path.join(tmp_dir, "data_part_*.bin")))
    with open(output_restored_path, 'wb') as f_final:
        for slice_path in binary_slices:
            with open(slice_path, 'rb') as f_slice:
                f_final.write(f_slice.read())
                
    shutil_cleanup(tmp_dir)
    print(f"\n[+] Extraction Complete! Restored original payload to: {output_restored_path}")

def shutil_cleanup(folder):
    if os.path.exists(folder):
        shutil.rmtree(folder)

def main():
    if not is_par2_installed():
        sys.exit(1)
    parser = argparse.ArgumentParser(description="Convert files into self-healing lossless PNG arrays.")
    subparsers = parser.add_subparsers(dest="mode", required=True)
    
    enc_parser = subparsers.add_parser("encode")
    enc_parser.add_argument("-i", "--input", required=True)
    enc_parser.add_argument("-o", "--output-dir", required=True)
    enc_parser.add_argument("-p", "--parity", type=int, default=30)
    enc_parser.add_argument("-r", "--resolution", default="1024x1024")

    dec_parser = subparsers.add_parser("decode")
    dec_parser.add_argument("-i", "--input-dir", required=True)
    dec_parser.add_argument("-o", "--output-file", required=True)

    args = parser.parse_args()
    if args.mode == "encode":
        w, h = map(int, args.resolution.lower().split('x'))
        encode_pure_png_vault(args.input, args.output_dir, args.parity, (w, h))
    elif args.mode == "decode":
        decode_pure_png_vault(args.input_dir, args.output_file)

if __name__ == "__main__":
    main()
