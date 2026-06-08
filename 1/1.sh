#!/bin/bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Jalankan sebagai root"
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 /dev/sdXN [mount-point] [backup-dir]"
  exit 1
fi

WIN_DEV="$1"
MNT="${2:-/mnt/windows}"
BACKUP_DIR="${3:-/tmp/win-reg-backup}"

mkdir -p "$MNT" "$BACKUP_DIR"

existing_mount=$(findmnt -n -o TARGET --source "$WIN_DEV" 2>/dev/null || true)
if [ -n "$existing_mount" ]; then
  echo "Device $WIN_DEV sudah ter-mount di $existing_mount"
  MNT="$existing_mount"
else
  echo "Mount partisi Windows: $WIN_DEV -> $MNT"
  if command -v ntfs-3g >/dev/null 2>&1; then
    if ! mount -o rw,uid=0,gid=0 "$WIN_DEV" "$MNT" 2>/dev/null; then
      echo "Gagal mount RW, mencoba RO"
      mount -o ro "$WIN_DEV" "$MNT"
    fi
  else
    mount -o ro "$WIN_DEV" "$MNT"
  fi
fi

readonly_mount=$(findmnt -n -o OPTIONS --target "$MNT" | tr ',' '\n' | grep -qw ro && echo yes || echo no)

CFG="$MNT/Windows/System32/config"
if [ ! -d "$CFG" ]; then
  echo "Tidak menemukan registry Windows di $CFG"
  umount "$MNT" 2>/dev/null || true
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d%H%M%S)
for hive in SAM SYSTEM; do
  if [ -f "$CFG/$hive" ]; then
    cp "$CFG/$hive" "$BACKUP_DIR/${hive}.bak.$TIMESTAMP"
    echo "Backup $hive dibuat di: $BACKUP_DIR/${hive}.bak.$TIMESTAMP"
  else
    echo "Hive $hive tidak ditemukan"
  fi
done

if [ "$readonly_mount" = "yes" ]; then
  echo
  echo "Volume ter-mount sebagai read-only."
  echo "Untuk mengedit SAM, partisi harus ter-mount read-write."
  echo "Coba gunakan ntfs-3g atau pastikan Windows tidak dalam hibernasi/fast startup."
  exit 1
fi

echo
echo "Menjalankan chntpw untuk membuka SAM..."
echo "Gunakan perintah chntpw untuk mengedit user/password."
echo

chntpw -e "$CFG/SAM"

echo
echo "Selesai. Lepaskan mount jika perlu:"
echo "  umount $MNT"