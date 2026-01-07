#!/bin/bash
# Auto-partition script for Arch install
# Layout: [root p1] [swap p99] [efi p100]
# Root first = can expand by shrinking swap from front
set -e

# =============================================================================
# CONSTANTS
# =============================================================================

SECTOR_SIZE=512
GPT_OVERHEAD_SECTORS=34
ALIGNMENT_SECTOR=2048

PARTITION_NUM_ROOT=1
PARTITION_NUM_SWAP=99
PARTITION_NUM_EFI=100

DEFAULT_EFI_SIZE="256M"
DEFAULT_SWAP_SIZE="8G"

# =============================================================================
# DISK DETECTION
# =============================================================================

find_largest_disk() {
  lsblk -dnbo NAME,SIZE,TYPE | awk '$3=="disk" {print $2, $1}' | sort -rn | head -1 | awk '{print $2}'
}

get_disk_size_bytes() {
  lsblk -dnbo SIZE "/dev/$1"
}

get_partition_prefix() {
  local disk=$1
  if [[ "$disk" == nvme* ]]; then
    echo "p"
  else
    echo ""
  fi
}

# =============================================================================
# SIZE CONVERSIONS
# =============================================================================

bytes_to_human() {
  local bytes=$1
  if (( bytes >= 1099511627776 )); then
    echo "$(( bytes / 1099511627776 ))TB"
  elif (( bytes >= 1073741824 )); then
    echo "$(( bytes / 1073741824 ))GB"
  else
    echo "$(( bytes / 1048576 ))MB"
  fi
}

human_to_bytes() {
  local size=$1
  local num=${size%[GMKgmk]*}
  local unit=${size##*[0-9]}
  case ${unit^^} in
    G) echo $(( num * 1073741824 )) ;;
    M) echo $(( num * 1048576 )) ;;
    K) echo $(( num * 1024 )) ;;
    *) echo "$num" ;;
  esac
}

bytes_to_sectors() {
  echo $(( $1 / SECTOR_SIZE ))
}

# =============================================================================
# SECTOR CALCULATIONS
# =============================================================================

calculate_partition_sectors() {
  local disk_bytes=$1
  local efi_bytes=$2
  local swap_bytes=$3

  local total_sectors=$(bytes_to_sectors "$disk_bytes")
  local efi_sectors=$(bytes_to_sectors "$efi_bytes")
  local swap_sectors=$(bytes_to_sectors "$swap_bytes")

  # Layout from end of disk backwards: [root] [swap] [efi] [gpt backup]
  EFI_END=$(( total_sectors - GPT_OVERHEAD_SECTORS ))
  EFI_START=$(( EFI_END - efi_sectors + 1 ))

  SWAP_END=$(( EFI_START - 1 ))
  SWAP_START=$(( SWAP_END - swap_sectors + 1 ))

  ROOT_START=$ALIGNMENT_SECTOR
  ROOT_END=$(( SWAP_START - 1 ))
}

# =============================================================================
# USER INTERACTION
# =============================================================================

prompt_for_sizes() {
  echo "Enter sizes (e.g., 256M, 8G, 1T):"
  echo ""
  read -p "EFI size [$DEFAULT_EFI_SIZE]: " EFI_SIZE
  EFI_SIZE=${EFI_SIZE:-$DEFAULT_EFI_SIZE}

  read -p "Swap size [$DEFAULT_SWAP_SIZE]: " SWAP_SIZE
  SWAP_SIZE=${SWAP_SIZE:-$DEFAULT_SWAP_SIZE}
}

display_partition_plan() {
  local disk=$1
  local root_human=$2
  local swap_size=$3
  local efi_size=$4
  local part_root=$5
  local part_swap=$6
  local part_efi=$7

  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  PARTITION PLAN: /dev/$disk"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "  Physical layout on disk:"
  echo "  [root p$PARTITION_NUM_ROOT: $root_human] [swap p$PARTITION_NUM_SWAP: $swap_size] [efi p$PARTITION_NUM_EFI: $efi_size]"
  echo ""
  printf "  %-20s %-10s %s\n" "$part_root" "$root_human" "Linux filesystem (ext4)"
  printf "  %-20s %-10s %s\n" "$part_swap" "$swap_size" "Linux swap"
  printf "  %-20s %-10s %s\n" "$part_efi" "$efi_size" "EFI System (FAT32)"
  echo ""
  echo "═══════════════════════════════════════════════════════════"
}

confirm_destructive_operation() {
  local disk=$1
  echo ""
  echo "  ⚠️  THIS WILL DESTROY ALL DATA ON /dev/$disk"
  echo ""
  read -p "  Continue? [y/N]: " CONFIRM
  [[ "${CONFIRM,,}" == "y" ]]
}

# =============================================================================
# PARTITIONING
# =============================================================================

wipe_disk() {
  sgdisk --zap-all "/dev/$1"
}

create_partitions() {
  local disk=$1
  
  sgdisk -n ${PARTITION_NUM_ROOT}:${ROOT_START}:${ROOT_END} \
         -t ${PARTITION_NUM_ROOT}:8300 \
         -c ${PARTITION_NUM_ROOT}:"Linux root" "/dev/$disk"
  
  sgdisk -n ${PARTITION_NUM_SWAP}:${SWAP_START}:${SWAP_END} \
         -t ${PARTITION_NUM_SWAP}:8200 \
         -c ${PARTITION_NUM_SWAP}:"Linux swap" "/dev/$disk"
  
  sgdisk -n ${PARTITION_NUM_EFI}:${EFI_START}:${EFI_END} \
         -t ${PARTITION_NUM_EFI}:ef00 \
         -c ${PARTITION_NUM_EFI}:"EFI System" "/dev/$disk"
  
  partprobe "/dev/$disk"
  sleep 1
}

format_partitions() {
  local part_root=$1
  local part_swap=$2
  local part_efi=$3

  mkfs.ext4 -F "$part_root"
  mkswap "$part_swap"
  mkfs.fat -F32 "$part_efi"
}

# =============================================================================
# MAIN
# =============================================================================

DISK=$(find_largest_disk)
DISK_BYTES=$(get_disk_size_bytes "$DISK")
DISK_HUMAN=$(bytes_to_human "$DISK_BYTES")
PART_PREFIX=$(get_partition_prefix "$DISK")

echo ""
echo "Found largest disk: /dev/$DISK ($DISK_HUMAN)"
echo ""

prompt_for_sizes

EFI_BYTES=$(human_to_bytes "$EFI_SIZE")
SWAP_BYTES=$(human_to_bytes "$SWAP_SIZE")
ROOT_BYTES=$(( DISK_BYTES - EFI_BYTES - SWAP_BYTES ))
ROOT_HUMAN=$(bytes_to_human "$ROOT_BYTES")

calculate_partition_sectors "$DISK_BYTES" "$EFI_BYTES" "$SWAP_BYTES"

PART_ROOT="/dev/${DISK}${PART_PREFIX}${PARTITION_NUM_ROOT}"
PART_SWAP="/dev/${DISK}${PART_PREFIX}${PARTITION_NUM_SWAP}"
PART_EFI="/dev/${DISK}${PART_PREFIX}${PARTITION_NUM_EFI}"

display_partition_plan "$DISK" "$ROOT_HUMAN" "$SWAP_SIZE" "$EFI_SIZE" "$PART_ROOT" "$PART_SWAP" "$PART_EFI"

if ! confirm_destructive_operation "$DISK"; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "Partitioning /dev/$DISK..."
wipe_disk "$DISK"
create_partitions "$DISK"

echo "Formatting partitions..."
format_partitions "$PART_ROOT" "$PART_SWAP" "$PART_EFI"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  DONE"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Now run:"
echo "  ./install.sh $PART_EFI $PART_SWAP $PART_ROOT"
echo ""
