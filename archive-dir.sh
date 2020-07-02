#!/bin/sh

# Creates a tar archive from a directory.  Additionally an mtree is created for the archive.

set -eu

archive_dir="$1"
archive_base_name="$(basename "$archive_dir")"
archive_name="${archive_base_name}.tar.gz"
archive_path="$PWD/$archive_name"
mtree_name="${archive_base_name}.mtree"
mtree_path="$PWD/$mtree_name"
archive_basedir="$(dirname "$archive_dir")"

echo "Creating mtree: ${mtree_path} ..."

bsdtar -C "${archive_basedir}" -c -f "$mtree_path" \
	--format=mtree \
	--options='!all,use-set,type,uid,gid,size,time,cksum,md5,sha256,sha512,indent' \
	--uid 0 --gid 0 \
	"$archive_base_name"

echo "Creating archive: ${archive_path} ..."

bsdtar -C "${archive_basedir}" -c -f "$archive_path" @"${mtree_path}"
