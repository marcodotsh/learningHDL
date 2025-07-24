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
