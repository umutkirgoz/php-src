#!/bin/bash
# usage: cmp-rpms.sh <orig-dir> <new-dir> <orig-release> <new-release>
O=$1 N=$2 RO=$3 RN=$4
for o in $O/*.rpm; do
  b=$(basename $o); n=$N/${b/$RO/$RN}
  [ -f "$n" ] || { echo "MISSING $n"; continue; }
  norm() { sed -e "s/$RO/X/g; s/$RN/X/g"; }
  f=$(diff <(rpm -qlp $o 2>/dev/null | norm) <(rpm -qlp $n 2>/dev/null | norm))
  r=$(diff <(rpm -qp --requires $o 2>/dev/null | norm | sort -u) <(rpm -qp --requires $n 2>/dev/null | norm | sort -u))
  p=$(diff <(rpm -qp --provides $o 2>/dev/null | norm | sort -u) <(rpm -qp --provides $n 2>/dev/null | norm | sort -u))
  if [ -z "$f$r$p" ]; then echo "same     ${b%%-5.*}"; else echo "DIFF     ${b%%-5.*}"; [ -n "$f" ] && echo "$f" | sed 's/^/   files: /'; [ -n "$r" ] && echo "$r" | sed 's/^/   requires: /'; [ -n "$p" ] && echo "$p" | sed 's/^/   provides: /'; fi
done
