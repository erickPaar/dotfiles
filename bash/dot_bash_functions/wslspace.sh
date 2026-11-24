# wslspace [-d]: Ubuntu's disk inside WSL, its disk file on C:, and C: itself.
# Run it before and after compacting ext4.vhdx. -d adds Docker's usage (takes a few seconds).
# Set WSLSPACE_VHDX to override the disk file path.
wslspace() {
  local vhdx="${WSLSPACE_VHDX:-}" f
  if [ -z "$vhdx" ]; then
    for f in /mnt/c/Users/*/AppData/Local/Packages/CanonicalGroupLimited.Ubuntu*/LocalState/ext4.vhdx; do
      [ -f "$f" ] && { vhdx=$f; break; }
    done
  fi
  local lu la ls cu ca cs vs free lp cp g y r b d x
  if [ -t 1 ]; then g=$'\e[32m' y=$'\e[33m' r=$'\e[31m' b=$'\e[1m' d=$'\e[2m' x=$'\e[0m'; fi
  _ds_h() { numfmt --to=iec --format='%.1f' "$1"; }
  _ds_bar() {  # percent -> coloured 20-cell bar
    local p=$1 n=$(( $1 / 5 )) c=$g
    (( n > 20 )) && n=20
    (( p >= 75 )) && c=$y; (( p >= 90 )) && c=$r
    printf '%s%s%s%s %3d%% used%s' "$c" "$(printf '%*s' "$n" '' | tr ' ' '#')" "$d" "$(printf '%*s' $((20 - n)) '' | tr ' ' '.')" "$p" "$x"
  }
  # Percentages match df: used / (used + available), so ext4's reserved space counts as full.
  read -r lu la ls < <(df -B1 --output=used,avail,size / | tail -1)
  read -r cu ca cs < <(df -B1 --output=used,avail,size /mnt/c | tail -1)
  lp=$(( lu * 100 / (lu + la) )); cp=$(( cu * 100 / (cu + ca) ))
  printf '%s%-18s%s %s  %s of %s\n' "$b" "Ubuntu (inside)" "$x" "$(_ds_bar $lp)" "$(_ds_h $lu)" "$(_ds_h $ls)"
  if [ -n "$vhdx" ] && vs=$(stat -c %s "$vhdx" 2>/dev/null); then
    free=$(( vs > lu ? vs - lu : 0 ))
    printf '%s%-18s%s %s on C:, compact could free about %s%s%s\n' "$b" "Ubuntu disk file" "$x" "$(_ds_h $vs)" "$b" "$(_ds_h $free)" "$x"
  else
    free=0
    printf '%s%-18s%s %snot found (set WSLSPACE_VHDX to its path)%s\n' "$b" "Ubuntu disk file" "$x" "$y" "$x"
  fi
  printf '%s%-18s%s %s  %s free of %s\n' "$b" "Windows C:" "$x" "$(_ds_bar $cp)" "$(_ds_h $ca)" "$(_ds_h $cs)"
  (( ca < 30 * 1024 ** 3 )) && printf '%sWARNING: C: has less than 30G free. WSL and Windows get unstable.%s\n' "$r" "$x"
  (( lp >= 90 )) && printf '%sWARNING: Ubuntu is over 90%% full.%s\n' "$r" "$x"
  (( free > 20 * 1024 ** 3 )) && printf '%sTip: compacting ext4.vhdx would give C: back about %s.%s\n' "$y" "$(_ds_h $free)" "$x"
  if [ "$1" = "-d" ] && command -v docker >/dev/null; then
    printf '\n%sDocker%s\n' "$b" "$x"
    timeout 30 docker system df --format '  {{printf "%-14s" .Type}} {{printf "%8s" .Size}}  reclaimable {{.Reclaimable}}' 2>/dev/null \
      || echo "  (Docker did not answer: not running, or the disk is busy)"
  fi
  unset -f _ds_h _ds_bar
  return 0
}
