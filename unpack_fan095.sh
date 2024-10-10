#!/bin/bash
# shellcheck disable=SC2034
# shellcheck disable=SC2154
# shellcheck disable=SC2164
# shellcheck disable=SC2181

# 适用于出厂安卓13的机型
unpack_partiton="system odm system_ext product vendor mi_ext system_dlkm vendor_dlkm"
# 适用于升级到安卓13的机型
# unpack_partiton="system odm system_ext product vendor mi_ext"
# 适用于没有官方安卓13的机型
# unpack_partiton="system odm system_ext product vendor"

get_files_config() {
  mkdir -p "$GITHUB_WORKSPACE"/get_files/config
  cp -r "$GITHUB_WORKSPACE"/"$device"/config/* "$GITHUB_WORKSPACE"/get_files/config
}

get_system_files() {
  local source="$1"
  if [ "$(echo "$source" | cut -d"/" -f2)" = "system" ]; then
    source=/system"$source"
  fi
  path=${source%/*}
  mkdir -p "$GITHUB_WORKSPACE"/get_files"$path"
  if [ -f "$GITHUB_WORKSPACE"/"$device""$source" ]; then
    cp "$GITHUB_WORKSPACE"/"$device""$source" "$GITHUB_WORKSPACE"/get_files"$path"
  elif [ -d "$GITHUB_WORKSPACE"/"$device""$source" ]; then
    cp -r "$GITHUB_WORKSPACE"/"$device""$source" "$GITHUB_WORKSPACE"/get_files"$path"
  else
    echo "$source 不存在"
  fi
}

get_prop_files() {
  get_system_files "/system/build.prop"
  get_system_files "/vendor/build.prop"
  get_system_files "/system_ext/etc/build.prop"
  get_system_files "/odm/etc/build.prop"
  get_system_files "/product/etc/build.prop"
  if [ -f "$GITHUB_WORKSPACE"/"$device"/mi_ext/etc/build.prop ]; then
    get_system_files "/mi_ext/etc/build.prop"
  elif [ -f "$GITHUB_WORKSPACE"/"$device"/mi_ext/build.prop ]; then
    get_system_files "/mi_ext/build.prop"
  fi
}

unpack_vendor_boot() {
  mkdir -p "$GITHUB_WORKSPACE"/"$device"/vendor_boot
  cd "$GITHUB_WORKSPACE"/"$device"/vendor_boot
  "$GITHUB_WORKSPACE"/tools/magiskboot unpack -h "$GITHUB_WORKSPACE"/"$device"/vendor_boot.img
  comp=$("$GITHUB_WORKSPACE"/tools/magiskboot decompress ramdisk.cpio 2>&1 | grep -v 'raw' | sed -n 's;.*\[\(.*\)\];\1;p')
  if [ "$comp" ]; then
    mv -f ramdisk.cpio ramdisk.cpio."$comp"
    "$GITHUB_WORKSPACE"/tools/magiskboot decompress ramdisk.cpio."$comp" ramdisk.cpio
    rm -rf ramdisk.cpio."$comp"
    if [ $? != 0 ] && $comp --help 2>/dev/null; then
      $comp -dc ramdisk.cpio."$comp" >ramdisk.cpio
    fi
  fi
  mkdir -p ramdisk
  chmod 755 ramdisk
  cd ramdisk
  EXTRACT_UNSAFE_SYMLINKS=1 cpio -d -F ../ramdisk.cpio -i
  rm -rf ../ramdisk.cpio
  cd "$GITHUB_WORKSPACE"
}

get_product_files() {
  get_system_files "/product/media"
}

extract_files() {
  cp "$GITHUB_WORKSPACE"/info.txt "$GITHUB_WORKSPACE"/get_files

  get_product_files
  # get_files_config
  # get_prop_files

  ### device_features
  get_system_files "/product/etc/device_features"

  ### overlay
  # get_system_files "/mi_ext/product/overlay"
  # get_system_files "/odm/overlay"
  # get_system_files "/product/overlay"
  # get_system_files "/vendor/overlay"
}
