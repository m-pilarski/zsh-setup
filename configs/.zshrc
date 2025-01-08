# Options
setopt correct extendedglob nocaseglob rcexpandparam nocheckjobs \
       numericglobsort nobeep appendhistory histignorealldups \
       autocd inc_append_history histignorespace

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' menu select
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

HISTFILE=~/.zhistory
HISTSIZE=10000
SAVEHIST=10000

WORDCHARS=${WORDCHARS//\/[&.;]}

# Keybindings
bindkey -e
bindkey '^[[7~' beginning-of-line '^[[H' beginning-of-line
bindkey '^[[8~' end-of-line '^[[F' end-of-line
bindkey '^[[2~' overwrite-mode '^[[3~' delete-char
bindkey '^[[C' forward-char '^[[D' backward-char
bindkey '^[[5~' history-beginning-search-backward
bindkey '^[[6~' history-beginning-search-forward
bindkey '^[Oc' forward-word '^[Od' backward-word
bindkey '^[[1;5D' backward-word '^[[1;5C' forward-word
bindkey '^H' backward-kill-word '^[[Z' undo

# Aliases
alias cp="cp -i"
alias df="df -h"
alias free="free -m"
alias gitu="git add . && git commit && git push"
alias ls='ls $LS_OPTIONS'

# Colors for `ls` and man pages
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
export LESS=-R
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;47;34m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;36m'

# Plugins
source ~/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.local/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Terminal title
function title {
  emulate -L zsh
  setopt prompt_subst
  [[ "$EMACS" == *term* ]] && return

  : ${2=$1}
  case "$TERM" in
    xterm*|putty*|rxvt*|konsole*|ansi|mlterm*|alacritty|kitty|wezterm|st*)
      print -Pn "\e]2;${2:q}\a\e]1;${1:q}\a"
      ;;
    screen*|tmux*)
      print -Pn "\ek${1:q}\e\\"
      ;;
    *)
      if [[ -n "$terminfo[fsl]" && -n "$terminfo[tsl]" ]]; then
        echoti tsl; print -Pn "$1"; echoti fsl
      fi
      ;;
  esac
}

ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<..<%~%<<"
ZSH_THEME_TERM_TITLE_IDLE="%n@%m:%~"

function mzc_termsupport_precmd { [[ "${DISABLE_AUTO_TITLE:-}" == true ]] || title $ZSH_THEME_TERM_TAB_TITLE_IDLE $ZSH_THEME_TERM_TITLE_IDLE; }
function mzc_termsupport_preexec { [[ "${DISABLE_AUTO_TITLE:-}" == true ]] || title '$CMD' '%100>...>$LINE%<<'; }

autoload -U add-zsh-hook
add-zsh-hook precmd mzc_termsupport_precmd
add-zsh-hook preexec mzc_termsupport_preexec

# Functions
function zsh_urlencode {
  emulate -L zsh
  local opts in_str="$@" url_str=""
  zparseopts -D -E -a opts r m P

  local spaces_as_plus=$([[ -z $opts[(r)-P] ]] && echo 1 || echo 0)
  local reserved=';/?:@&=+$,'
  local mark='_.!~*''()-'
  local dont_escape="[A-Za-z0-9${reserved}${mark}]"

  for (( i = 1; i <= ${#in_str}; i++ )); do
    local byte="$in_str[i]"
    [[ "$byte" =~ "$dont_escape" ]] && url_str+="$byte" || url_str+="${spaces_as_plus:++}${spaces_as_plus:+%$(printf '%02X' "'$byte")}"
  done
  echo -E "$url_str"
}

function mzc_termsupport_cwd {
  printf "\e]7;%s\a" "file://$(zsh_urlencode -P $HOST)$(zsh_urlencode -P $PWD)"
}

add-zsh-hook precmd mzc_termsupport_cwd

# Theming
autoload -U compinit colors zcalc
compinit -d
colors

source ~/.local/share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme
source ~/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
