# Usage: rgand foo bar baz -- matches lines containing ALL patterns
rgand() {
  local patterns=("$@")
  local result
  result=$(rg --no-heading "$1")
  shift
  for pattern in "$@"; do
    result=$(echo "$result" | rg "$pattern")
  done
  local args=()
  for pattern in "${patterns[@]}"; do
    args+=(-e "$pattern")
  done
  echo "$result" | rg --heading --color always "${args[@]}"
}

# Usage: rgor foo bar baz -- matches lines containing ANY pattern
rgor() {
  local args=()
  for pattern in "$@"; do
    args+=(-e "$pattern")
  done
  rg "${args[@]}"
}
