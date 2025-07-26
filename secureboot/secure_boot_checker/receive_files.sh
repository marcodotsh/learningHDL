#!/usr/bin/env bash

set -euo pipefail

# Source directory
SOURCE_DIR="$HOME/Git/Project_1_DHWA25_Zanzottera/neorv32-setups/neorv32/rtl/core"

# Files to copy
files_to_copy=(
  "neorv32_bootloader_image.vhd"
  "neorv32_secure_boot_checker_verification_image.vhd"
)

for filename in "${files_to_copy[@]}"; do
  source_file="$SOURCE_DIR/$filename"
  dest_file="./$filename"

  if [ -f "$source_file" ]; then
    # Copy the file verbosely to the current directory
    cp -v "$source_file" .

    # Replace 'neorv32.' with 'work.' in the destination file
    sed -i 's/neorv32\./work\./g' "$dest_file"
    echo "Replaced 'neorv32.' with 'work.' in $dest_file"

    # Remove 'library neorv32;'
    sed -i '/library neorv32;/d' "$dest_file"
    echo "Removed 'library neorv32;' from $dest_file"
  else
    echo "Warning: $source_file not found."
  fi
done

echo "Script finished."

# Extract bootloader size in words from neorv32_bootloader_image.vhd
# The size is the last word in the bootloader_init_secure_boot_info_c array
BOOTLOADER_SIZE_HEX=$(grep "Bootloader code size" neorv32_bootloader_image.vhd | sed -n 's/.*x"\([^"]*\)".*/\1/p')

if [ -z "$BOOTLOADER_SIZE_HEX" ]; then
    echo "Error: Could not extract bootloader size."
    exit 1
fi

echo "Extracted bootloader size: $BOOTLOADER_SIZE_HEX"

# Update the sha256 testbench with the new bootloader size
sed -i "s/words_to_read_i <= x\"[0-9a-fA-F]*\";/words_to_read_i <= x\"$BOOTLOADER_SIZE_HEX\";/" neorv32_secure_boot_sha256_tb.vhd
echo "Updated neorv32_secure_boot_sha256_tb.vhd"


# Extract RSA key size from neorv32_secure_boot_checker_verification_image.vhd
RSA_KEY_SIZE_BITS=$(grep "rsa_modulus_c" neorv32_secure_boot_checker_verification_image.vhd | sed -n 's/.*std_ulogic_vector(\([0-9]*\) downto.*/\1/p')

if [ -z "$RSA_KEY_SIZE_BITS" ]; then
    echo "Error: Could not extract RSA key size."
    exit 1
fi

# The size is the value from the vector definition + 1
RSA_KEY_SIZE=$((RSA_KEY_SIZE_BITS + 1))
echo "Extracted RSA key size: $RSA_KEY_SIZE bits"

# Update the secure boot checker with the new RSA key size
sed -i "s/constant RSA_KEY_SIZE : integer := [0-9]*;/constant RSA_KEY_SIZE : integer := $RSA_KEY_SIZE;/" neorv32_secure_boot_checker.vhd
echo "Updated neorv32_secure_boot_checker.vhd"


