#!/bin/bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Jalankan sebagai root"
  exit 1
fi

MNT="${1:-/mnt/windows}"
SAM="$MNT/Windows/System32/config/SAM"

if [ ! -f "$SAM" ]; then
  echo "File SAM tidak ditemukan di: $SAM"
  exit 1
fi

if ! command -v chntpw >/dev/null 2>&1; then
  echo "chntpw tidak ditemukan. Install paket ntfs-3g atau chntpw dulu."
  exit 1
fi

echo "Daftar user dari SAM:"
chntpw -l "$SAM"
echo

read -p "Masukkan nama user atau RID yang akan dijadikan admin: " USER
if [ -z "$USER" ]; then
  echo "User tidak boleh kosong."
  exit 1
fi

echo
echo "Menjadikan '$USER' sebagai administrator..."
chntpw -u "$USER" "$SAM"

echo
echo "Selesai. Periksa output chntpw"