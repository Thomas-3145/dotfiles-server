# .zshrc för jobbservern — avskalad kopia av zsh/.zshrc utan hemlabb, docker,
# k8s, anteckningar och moduler. Pushas med server/push.sh, länkas av server/install.sh.
# Ändrar du en funktion som finns i båda: uppdatera båda (de delar inte kod med flit,
# så att hemlabbsfiler aldrig behöver ligga på servern).

# =========================================================
# 1. OH-MY-ZSH
# =========================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="dracula"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto

mkdir -p ~/.zsh/cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Ingen ssh-agent-plugin här: på servern används agent forwarding från din dator.
plugins=(git zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# =========================================================
# 2. GRUNDINSTÄLLNINGAR & PATH
# =========================================================
export SERVER_DOTFILES="$HOME/.dotfiles"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=hx
export VISUAL=hx
export LANG=en_US.UTF-8

[[ -f "$HOME/.dir_colors" ]] && eval "$(dircolors -b "$HOME/.dir_colors")"

command -v fzf    &> /dev/null && source <(fzf --zsh)
command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"
command -v direnv &> /dev/null && eval "$(direnv hook zsh)"

# =========================================================
# 3. ALIAS
# =========================================================
if command -v eza &> /dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --git --group-directories-first'
    alias la='eza -la --git --group-directories-first'
else
    alias ls='ls --color=auto'
fi
alias rg="rg --smart-case"
alias grep="grep --color=auto"
alias cat='bat'
alias reload="source ~/.zshrc && echo 'Config laddad!'"

# tree med smart djup: `tree` = 2 nivåer, `tree 3` = 3 nivåer, `tree -L 4` funkar också.
unalias tree 2> /dev/null
tree() {
    if [[ "$1" == <-> ]]; then
        command tree -L "$1" "${@:2}"
    else
        command tree -L 2 "$@"
    fi
}

unalias md 2>/dev/null
md() {
    local dir="${1:?Användning: md <mapp>}"
    mkdir -p -- "$dir" && cd -- "$dir"
}

# =========================================================
# 4. PYTHON AUTO-VENV
# =========================================================
# Letar uppåt i trädet så att subkataloger i projektet inte avaktiverar.
autoload -U add-zsh-hook
function _auto_venv() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.venv" ]]; then
            if [[ "$VIRTUAL_ENV" != "$dir/.venv" ]]; then
                # Rör inte en miljö som användaren aktiverat manuellt.
                if [[ -n "$VIRTUAL_ENV" && "${_AUTO_VENV:-}" != "$VIRTUAL_ENV" ]]; then
                    return
                fi
                if [[ -n "${_AUTO_VENV:-}" ]] && typeset -f deactivate > /dev/null; then
                    deactivate
                fi
                source "$dir/.venv/bin/activate"
                _AUTO_VENV="$dir/.venv"
                echo ".venv aktiverad"
            fi
            return
        fi
        dir="${dir:h}"
    done
    if [[ -n "${_AUTO_VENV:-}" && "$VIRTUAL_ENV" == "$_AUTO_VENV" ]] \
        && typeset -f deactivate > /dev/null; then
        deactivate
        _AUTO_VENV=""
        echo ".venv avaktiverad"
    fi
}
add-zsh-hook chpwd _auto_venv
_auto_venv

# =========================================================
# 5. FUSKLAPP  (fusk / fusk <term> / fusk -a)
# =========================================================
FUSK_FILE="${FUSK_FILE:-$SERVER_DOTFILES/server/fusk.txt}"

_fusk_text() {
    [[ -r "$FUSK_FILE" ]] || { echo "fusk: hittar inte $FUSK_FILE" >&2; return 1; }
    echo -e "\n\e[1;34mSnabbkommandon\e[0m  \e[2m(fusk <term> filtrerar · fusk -a allt)\e[0m"
    local line cmd desc
    while IFS= read -r line; do
        case "$line" in
            '#'*)  continue ;;
            '')    echo "" ;;
            '['*']') echo -e "  \e[1;33m${line:1:-1}\e[0m" ;;
            '!'*)  echo -e "  \e[2m${line#!$'\t'}\e[0m" ;;
            *)     cmd="${line%%$'\t'*}"; desc="${line#*$'\t'}"
                   printf "  \e[36m%s\e[0m %s\n" "${(r:26:)cmd}" "$desc" ;;
        esac
    done < "$FUSK_FILE"
}

fusk() {
    if [ $# -eq 0 ]; then
        _fusk_text | fzf --ansi --no-sort --layout=reverse --height=80% --prompt='fusk> '
    elif [ "$1" = "-a" ]; then
        _fusk_text
    else
        _fusk_text | grep -iE --color=never "$*"
    fi
}

# =========================================================
# 6. GIT ALIASES  (ordnade efter typisk workflow)
# =========================================================

# --- 1. Synka & orientera ---
alias gb="git fetch --prune && git branch -a"
alias gpl="git pull --rebase --autostash"
alias gs="git status --short --branch"

gsync() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "gsync: inte i ett Git-repo" >&2; return 1
  }
  local default_branch
  default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  default_branch="${default_branch#origin/}"
  default_branch="${default_branch:-main}"
  git switch "$default_branch" \
    && git pull --rebase --autostash \
    && git fetch --prune \
    && git branch -a
}

# --- 2. Byt/skapa branch ---
# gsw                 → fuzzy-välj (eller skriv nytt namn + Enter = skapa)
# gsw <namn>          → byt om den finns, annars skapa
# gsw -c <namn>       → tvinga skapa
unalias gsw 2>/dev/null
gsw() {
  if [ $# -eq 0 ]; then
    local out query branch
    # fzf --height i stället för fzf-tmux: fzf-binären från GitHub har inte med fzf-tmux.
    out=$(git branch --all --no-color | grep -v HEAD \
      | fzf --height 20 +m --print-query \
          --header="Enter=byt | skriv nytt namn + Enter=skapa") || return 1
    [[ -z "$out" ]] && return 1

    query=$(echo "$out" | head -1)
    branch=$(echo "$out" | sed -n '2p')

    if [[ -z "$branch" ]]; then
      git switch -c "$query" && git status --short --branch
    else
      branch=$(echo "$branch" | sed 's/.* //' | sed 's#remotes/[^/]*/##')
      git switch "$branch" && git status --short --branch
    fi
    return
  fi

  if [[ "$1" == -* ]]; then
    git switch "$@" && git status --short --branch
    return
  fi

  if git show-ref --verify --quiet "refs/heads/$1" \
     || git show-ref --verify --quiet "refs/remotes/origin/$1"; then
    git switch "$1" && git status --short --branch
  else
    git switch -c "$1" && git status --short --branch
  fi
}

# --- 3. Staging ---
alias ga="git add"
alias gaa="git add -A"

# --- 4. Granska innan commit ---
alias greview="git status --short --branch && echo '---' && git diff --staged"

# --- 5. Commit ---
alias gcm='git commit -m'

# --- 6. Pusha till remote ---
unalias gp 2>/dev/null
gp() {
  emulate -L zsh
  local branch default_branch
  branch=$(git symbolic-ref --quiet --short HEAD) || {
    echo "gp: detached HEAD — checka ut en branch först"; return 1
  }

  # Hämta ALLA refs: --force-with-lease jämför mot refs/remotes/origin/$branch.
  git fetch origin || return 1
  default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  default_branch="${default_branch#origin/}"
  default_branch="${default_branch:-main}"

  if [[ "$branch" == "$default_branch" ]]; then
    git pull --rebase --autostash && git push
    return
  fi

  git rebase "origin/$default_branch" || return 1

  if (( $(git rev-list --count HEAD ^"origin/$default_branch") == 0 )); then
    echo "gp: inget att pusha (redan i $default_branch)"
    return 0
  fi

  # Ny branch, eller origin/$branch ingår fortfarande i vår historik (rebasen
  # ändrade inget som redan pushats): vanlig push räcker.
  if ! git show-ref --verify --quiet "refs/remotes/origin/$branch" \
     || git merge-base --is-ancestor "origin/$branch" HEAD; then
    git push -u origin "$branch"
  else
    # Historiken har skrivits om (eller origin har commits vi saknar).
    # --force-with-lease  vägrar om origin flyttat sig sedan vår senaste fetch
    # --force-if-includes vägrar dessutom om vi inte faktiskt integrerat det
    #                     som ligger på origin (täpper till luckan när fetch
    #                     precis hämtat hem någon annans commit)
    local answer
    echo "gp: origin/$branch ingår inte i din historik, kräver force-with-lease."
    read -r "answer?Fortsätt? [j/N] "
    [[ "$answer" == [Jj] ]] || { echo "Avbrutet."; return 1; }
    git push --force-with-lease --force-if-includes -u origin "$branch"
  fi
}

# --- 7. Ångra ---
alias gundo="git undo"                      # kräver git-config alias 'undo'

# --- 8. Städa efter merge ---
# gdone <branch>  byt till main + synka + radera mergad branch
# Är remote-branchen borta ([gone]) räknas den som mergad och raderas med -D,
# så squash-mergar fungerar. Annars krävs att den ingår i main: git branch -d
# räcker inte, den jämför mot branchens egen upstream och släpper då igenom allt pushat.
gdone() {
  local branch="${1:?Användning: gdone <branch>}"
  [[ "$branch" != main && "$branch" != master ]] || {
    echo "gdone: vägrar radera standardbranchen" >&2; return 1
  }
  git check-ref-format --branch "$branch" >/dev/null 2>&1 || {
    echo "Ogiltigt branchnamn: $branch" >&2; return 1
  }
  gsync || return 1
  if [[ "$(git for-each-ref --format='%(upstream:track)' "refs/heads/$branch")" == "[gone]" ]]; then
    git branch -D -- "$branch"   # borta på GitLab = mergad, även vid squash
  elif git merge-base --is-ancestor "refs/heads/$branch" HEAD; then
    git branch -d -- "$branch"   # finns kvar på remote men är mergad
  else
    echo "gdone: $branch är inte mergad i $(git branch --show-current), inget raderat" >&2
    return 1
  fi
}
