#!/bin/sh

# Reads extern functions from extern.list, where they appear in the
# format source_file:func_name.  Generates a header file custom-made
# for each directory under lib/src, for inclusion in any file that has
# 'extern "C"'.  Writes that header onto stdout.

# We aren't using the source_file part of each line of
# multidim/extern.list, but we might in the future, say if we want to
# generate headers on a per-file, rather than per-directory basis.

# This script is meant to be run by the Makefile in every
# lib/src/*/multidim directory, directing stdout to .. i.e.  to the
# directory that has the files that will want to include .  If there's
# no extern.list file, then it's up to Makefile to not run this
# script.

# This won't work if there are a really large number of such functions.
# Should probably rewrite this script in Perl or Python.

if test $# -ne 3; then
  echo "-----------------------------------------------------"
  echo "Usage: $0 lib_src_dir min_spacedim max_spacedim      "
  echo "-----------------------------------------------------"
  exit 1
fi
lib_src_dir=$1
min_spacedim=$2
max_spacedim=$3

getExternFuncs() {
    retval=""

    while read line; do
        retval="$retval $line"
    done < ./extern.list

    echo $retval
}

extern_funcs=`getExternFuncs`

compile_guard=LAST_${lib_src_dir}_ExternC_Mangler_H_SPACEDIM

echo "//////////////////////////////////////////////////////////////////////////////////"
echo "// Do not hand-edit this file.                                                  //"
echo "// It was generated by lib/utils/multidim/mangle_externs.sh, which was called   //"
echo "// in turn by bootstrap.                                                        //"
echo "//////////////////////////////////////////////////////////////////////////////////"

echo "#ifdef CH_MULTIDIM"

echo "  #ifndef $compile_guard"
echo "    #define $compile_guard 0"
echo "  #endif"
echo ""
echo "  #if CH_SPACEDIM != $compile_guard"
echo "    #undef $compile_guard"

#
# Undefine all symbols
#
first_sym=`echo $extern_funcs | awk '{print $1}' | cut -d: -f2`
echo "    #ifdef $first_sym"
for line in $extern_funcs; do
    file=`echo $line | cut -d: -f1`
    func=`echo $line | cut -d: -f2`
    echo "      #undef $func"
done
echo "    #endif"

#
# Make dim-specific definitions
#
echo "    #if   CH_SPACEDIM == 0"   # Just so the rest can be elifs.
dim=$min_spacedim
while test $dim -le $max_spacedim ; do
    CH_XD=CH_${dim}D
    echo "    #elif CH_SPACEDIM == $dim"
    for line in $extern_funcs; do
        file=`echo $line | cut -d: -f1`
        func=`echo $line | cut -d: -f2`
        echo "      #define $func ${CH_XD}_$func"
    done
    echo "      #define $compile_guard $dim"
    dim=`expr $dim + 1`
done
echo     "    #endif"
echo     "  #endif"
echo     "#endif"
