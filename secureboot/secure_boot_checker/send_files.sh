#!/usr/bin/env bash

set -euo pipefail

# Destination directory
DEST_DIR="$HOME/Git/Project_1_DHWA25_Zanzottera/neorv32-setups/neorv32/rtl/core"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Find all .vhd files, excluding those ending with _tb.vhd
find . -maxdepth 1 -name "*.vhd" ! -name "*_tb.vhd" | while read file; do
  # Get just the filename from the path.
  filename=$(basename "$file")
  
  # Copy the file verbosely
  cp -v "$file" "$DEST_DIR/"

  # Full path of the destination file
  dest_file="$DEST_DIR/$filename"

  # Replace 'work.' with 'neorv32.' in the destination file
  sed -i 's/work\./neorv32\./g' "$dest_file"
  echo "Replaced 'work.' with 'neorv32.' in $dest_file"

  # Insert 'library neorv32;' before the first line containing 'neorv32.'
  # Check if the pattern exists to avoid inserting the line if it doesn't
  if grep -q 'neorv32\.' "$dest_file"; then
    sed -i '0,/use neorv32\./s//library neorv32;\n&/' "$dest_file"
    echo "Inserted 'library neorv32;' in $dest_file"
  fi
done

docker start hardware-dev

docker exec hardware-dev bash -c 'cd /workspaces/Project_1_DHWA25_Zanzottera/neorv32-setups/neorv32/rtl && bash generate_file_lists.sh'

echo "Script finished."
