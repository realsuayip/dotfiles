function prompt-length() {
  emulate -L zsh
  local -i COLUMNS=${2:-COLUMNS}
  local -i x y=${#1} m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ))
    done
    while (( y > x + 1 )); do
      (( m = x + (y - x) / 2 ))
      (( ${${(%):-$1%$m(l.x.y)}[-1]} = m ))
    done
  fi
  typeset -g REPLY=$x
}

function fill-line() {
  emulate -L zsh
  prompt-length $1
  local -i left_len=REPLY
  prompt-length $2 9999
  local -i right_len=REPLY
  local -i pad_len=$((COLUMNS - left_len - right_len - ${ZLE_RPROMPT_INDENT:-1}))
  if (( pad_len < 1 )); then
    # Not enough space for the right part. Drop it.
    typeset -g REPLY=$1
  else
    local pad=${(pl.$pad_len.. .)}  # pad_len spaces
    typeset -g REPLY=${1}${pad}${2}
  fi
}

function get_virtualenv {
        if [ -n "$VIRTUAL_ENV" ] ; then
            source=$PWD
            target=$VIRTUAL_ENV

            common_part=$source
            result=""

            while [[ "${target#$common_part}" == "${target}" ]]; do
                common_part="$(dirname $common_part)"
                if [[ -z $result ]]; then
                    result=".."
                else
                    result="../$result"
                fi
            done

            if [[ $common_part == "/" ]]; then
                result="$result/"
            fi

            forward_part="${target#$common_part}"

            if [[ -n $result ]] && [[ -n $forward_part ]]; then
                result="$result$forward_part"
            elif [[ -n $forward_part ]]; then
                result="${forward_part:1}"
            fi
            echo "[${result}]"
        fi
}

function set-prompt() {
  emulate -L zsh
  local git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  git_branch=${git_branch//\%/%%}  # escape '%'
  virtualenv=${get_virtualenv}

  local top_left='%B%F{cyan}%~%f%b'
  local top_right="%B%F{red}${git_branch}%f%b$(get_virtualenv)"
  local bottom_left='%(?.😎.😳) '
  local bottom_right='%B%F{white}%T%f%b'

  local REPLY
  fill-line "$top_left" "$top_right"
  PROMPT=$REPLY$'\n'$bottom_left
  RPROMPT=$bottom_right
}

setopt no_prompt_{bang,subst} prompt_{cr,percent,sp}
autoload -Uz add-zsh-hook
add-zsh-hook precmd set-prompt
