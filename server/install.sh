#!/usr/bin/env bash
# server/install.sh — sätter upp terminalmiljön på en Ubuntu/Debian-server (x86_64).
# Körs PÅ servern efter server/push.sh:   ~/.dotfiles/server/install.sh
# Idempotent: säkert att köra om. Befintliga filer flyttas till *.bak-<datum>.
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"   # ~/.dotfiles
BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"

[[ "$(uname -m)" == x86_64 ]] || { echo "Bara x86_64 stöds (binär-URL:erna nedan)." >&2; exit 1; }

echo "== apt-paket =="
sudo apt-get update -q
sudo apt-get install -y -q zsh git curl xz-utils ripgrep fd-find bat direnv jq tldr tree zoxide

# Debian/Ubuntu döper om bat och fd p.g.a. namnkrockar — ge dem riktiga namn.
mkdir -p "$BIN" "$OPT"
[[ -x /usr/bin/batcat ]] && ln -sfn /usr/bin/batcat "$BIN/bat"
[[ -x /usr/bin/fdfind ]] && ln -sfn /usr/bin/fdfind "$BIN/fd"

echo "== Binärer från GitHub (apt-versionerna är för gamla eller saknas) =="
# fzf: apt har < 0.48, som saknar `fzf --zsh`. yq: apt-paketet är ett annat verktyg (python-yq).
# shortcut: fasta versioner, uppdateras inte automatiskt — höj numren här och kör om.
fetch() { curl -fsSL "$1"; }
gh="https://github.com"

fetch "$gh/junegunn/fzf/releases/download/v0.75.0/fzf-0.75.0-linux_amd64.tar.gz" | tar xz -C "$BIN" fzf
fetch "$gh/eza-community/eza/releases/download/v0.23.5/eza_x86_64-unknown-linux-gnu.tar.gz" | tar xz -C "$BIN" ./eza
fetch "$gh/dandavison/delta/releases/download/0.20.1/delta-0.20.1-x86_64-unknown-linux-gnu.tar.gz" \
    | tar xz -C "$BIN" --strip-components=1 delta-0.20.1-x86_64-unknown-linux-gnu/delta
fetch "$gh/charmbracelet/glow/releases/download/v3.0.0/glow_3.0.0_Linux_x86_64.tar.gz" \
    | tar xz -C "$BIN" --strip-components=1 glow_3.0.0_Linux_x86_64/glow
fetch "$gh/mikefarah/yq/releases/download/v4.54.3/yq_linux_amd64" > "$BIN/yq" && chmod +x "$BIN/yq"

# Helix behöver runtime/ bredvid binären; symlänken funkar eftersom hx följer den.
rm -rf "$OPT/helix" && mkdir -p "$OPT/helix"
fetch "$gh/helix-editor/helix/releases/download/25.07.1/helix-25.07.1-x86_64-linux.tar.xz" \
    | tar xJ -C "$OPT/helix" --strip-components=1
ln -sfn "$OPT/helix/hx" "$BIN/hx"

echo "== Oh My Zsh + plugin + tema =="
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(fetch https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
custom="$HOME/.oh-my-zsh/custom"
[[ -d "$custom/plugins/zsh-syntax-highlighting" ]] \
    || git clone -q --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom/plugins/zsh-syntax-highlighting"
[[ -d "$custom/themes/dracula" ]] \
    || git clone -q --depth 1 https://github.com/dracula/zsh.git "$custom/themes/dracula"
ln -sfn "$custom/themes/dracula/dracula.zsh-theme" "$custom/themes/dracula.zsh-theme"

echo "== Symlänkar =="
# link <källa i ~/.dotfiles> <mål>
link() {
    local src="$DIR/$1" dest="$2"
    [[ -e "$src" ]] || { echo "SAKNAS: $src" >&2; exit 1; }
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        mv -- "$dest" "$dest.bak-$(date +%Y%m%d-%H%M%S)"
        echo "sparade gamla $dest som .bak"
    fi
    mkdir -p -- "$(dirname -- "$dest")"
    ln -sfn "$src" "$dest"
    echo "länkad  $dest"
}
link server/.zshrc               "$HOME/.zshrc"
link server/.gitconfig           "$HOME/.gitconfig"
link git/.gitignore_global       "$HOME/.gitignore_global"
link zsh/.dir_colors             "$HOME/.dir_colors"
link config/helix/config.toml    "$HOME/.config/helix/config.toml"
link config/wezterm/.wezterm.lua "$HOME/.wezterm.lua"

if [[ ! -e "$HOME/.gitconfig.local" ]]; then
    cat > "$HOME/.gitconfig.local" <<'EOF'
# Git-identitet för den här servern. Fyll i och avkommentera.
#[user]
#    name = Ditt Namn
#    email = du@jobbet.se
EOF
    echo "skapad  ~/.gitconfig.local — fyll i namn och mejl"
fi

# bash startar zsh i stället för chsh: på servrar med AD/LDAP-konton får man inte byta skal.
if ! grep -q 'exec zsh' "$HOME/.bashrc" 2>/dev/null; then
    echo '[[ $- == *i* ]] && command -v zsh >/dev/null && exec zsh -l' >> "$HOME/.bashrc"
    echo "tillagt ~/.bashrc startar zsh"
fi

# Super+T → WezTerm (samma som config/gnome/media-keys.dconf hemma). Bara med GNOME-skrivbord.
mk=org.gnome.settings-daemon.plugins.media-keys
if command -v gsettings >/dev/null && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    p=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/wezterm/
    list="$(gsettings get $mk custom-keybindings)"
    if [[ "$list" == *"$p"* ]]; then
        :
    elif [[ "$list" == "@as []" || "$list" == "[]" ]]; then
        gsettings set $mk custom-keybindings "['$p']"
        gsettings set "$mk.custom-keybinding:$p" name 'WezTerm'
        gsettings set "$mk.custom-keybinding:$p" command 'wezterm'
        gsettings set "$mk.custom-keybinding:$p" binding '<Super>t'
        echo "genväg  Super+T → wezterm"
    else
        echo "OBS: egna genvägar finns redan, lägg Super+T → wezterm för hand (Inställningar → Tangentbord)."
    fi
fi

echo
echo "Klart. Logga ut och in igen (eller kör: exec zsh)."
