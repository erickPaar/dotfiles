# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# eza is the maintained fork of exa; use whichever is installed
_exa=$(command -v eza || command -v exa)
if [ -n "$_exa" ]; then
  alias l="$_exa -ll --color=always --group-directories-first"
  alias ls="$_exa -al --header --icons --group-directories-first"
fi
unset _exa

alias idea='nohup $HOME/dev/tools/idea-IU-252.26830.84/bin/idea > /tmp/idea.log 2>&1 &'

alias cs='xclip -selection clipboard'       #copy to clipboard. ex: echo 123 | cs
alias vs='xclip -o -selection clipboard'    #paste from clipboard.
alias cs_from_file='xclip -selection clipboard <'    # Copy file content to clipboard. Usage: cs_from_file filename
alias vs_into_file='xclip -o -selection clipboard >'  # Paste clipboard into a file. Usage: vs_into_file filename

# Query Runner - PostgreSQL query management tool
alias qr="$HOME/dev/venv/bin/qr"

alias tracker='$HOME/dev/projects/personal/bimester-tracker/.venv/bin/tracker'
#alias jt='$HOME/bin/jtd'
alias jt='java -jar $HOME/dev/projects/personal/jvm-test-daemon/jtd-cli/build/libs/jtd.jar'

alias fd=fdfind
alias fda='fdfind --no-ignore --hidden'

alias claude-mem='$HOME/.bun/bin/bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# Set WezTerm tab title (usable by Claude Code or manually)
alias tabtitle='wezterm cli set-tab-title'
