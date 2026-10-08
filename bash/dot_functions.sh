# Source all function files from ~/.bash_functions/
for f in ~/bash/.bash_functions/*.sh; do
  [ -f "$f" ] && . "$f"
done
