#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# SSH key setup for GitHub + Bitbucket
#
# - Generates a separate ed25519 key per host (revoking one won't impact
#   the other; lets you scope access independently)
# - Writes ~/.ssh/config entries with IdentitiesOnly so each host uses the
#   right key even with many keys in the agent
# - Idempotent: skips key generation / config blocks that already exist
# - Non-interactive safe: falls back to git config email, then $USER@$HOSTNAME
# ---------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logs go to stderr so functions can safely return data on stdout.
info()    { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
success() { echo -e "${GREEN}[OK]${NC} $1" >&2; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

HOSTS=(
    # alias|hostname|key-suffix
    "github.com|github.com|github"
    "bitbucket.org|bitbucket.org|bitbucket"
)

ensure_ssh_dir() {
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    [ -f "$SSH_CONFIG" ] || touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
}

resolve_email() {
    # Priority: $SSH_KEY_EMAIL > git global email > interactive prompt > fallback
    local email="${SSH_KEY_EMAIL:-}"
    [ -z "$email" ] && email="$(git config --global user.email 2>/dev/null || true)"

    if [ -z "$email" ]; then
        if [ -t 0 ]; then
            read -rp "Enter email for SSH key comment: " email
        fi
    fi

    if [ -z "$email" ]; then
        email="$(whoami)@$(hostname)"
        warn "No email available — using $email as key comment"
    fi

    echo "$email"
}

generate_key() {
    local suffix="$1" email="$2"
    local key_path="$SSH_DIR/id_ed25519_${suffix}"

    if [ -f "$key_path" ]; then
        success "SSH key for $suffix already exists ($key_path)"
        return
    fi

    info "Generating ed25519 key for $suffix..."
    ssh-keygen -t ed25519 -C "$email ($suffix)" -f "$key_path" -N "" -q
    chmod 600 "$key_path"
    chmod 644 "$key_path.pub"
    success "Generated $key_path"
}

add_ssh_config_block() {
    local host_alias="$1" host_name="$2" suffix="$3"
    local key_path="$SSH_DIR/id_ed25519_${suffix}"

    if grep -qE "^[[:space:]]*Host[[:space:]]+${host_alias}[[:space:]]*$" "$SSH_CONFIG"; then
        success "~/.ssh/config already has Host entry for $host_alias"
        return
    fi

    info "Adding ~/.ssh/config block for $host_alias..."
    # Ensure file ends with a newline before appending.
    [ -s "$SSH_CONFIG" ] && [ "$(tail -c1 "$SSH_CONFIG"; echo x)" != $'\nx' ] && echo "" >> "$SSH_CONFIG"
    cat >> "$SSH_CONFIG" <<EOF

Host $host_alias
    HostName $host_name
    User git
    IdentityFile $key_path
    IdentitiesOnly yes
    AddKeysToAgent yes
EOF
    success "Added Host $host_alias to ~/.ssh/config"
}

add_keys_to_agent() {
    # Start an agent for this shell if none is reachable.
    if ! ssh-add -l >/dev/null 2>&1; then
        if [ -z "${SSH_AUTH_SOCK:-}" ]; then
            info "Starting ssh-agent for this session..."
            eval "$(ssh-agent -s)" >/dev/null
        fi
    fi

    for entry in "${HOSTS[@]}"; do
        local suffix="${entry##*|}"
        local key_path="$SSH_DIR/id_ed25519_${suffix}"
        [ -f "$key_path" ] || continue
        if ssh-add "$key_path" 2>/dev/null; then
            success "Added $key_path to ssh-agent"
        else
            warn "Could not add $key_path to ssh-agent (passphrase or no agent)"
        fi
    done
}

print_public_keys() {
    echo "" >&2
    echo -e "${GREEN}========================================${NC}" >&2
    echo -e "${GREEN}  Add these public keys to your accounts${NC}" >&2
    echo -e "${GREEN}========================================${NC}" >&2

    for entry in "${HOSTS[@]}"; do
        local alias="${entry%%|*}"
        local suffix="${entry##*|}"
        local pub="$SSH_DIR/id_ed25519_${suffix}.pub"
        [ -f "$pub" ] || continue
        echo "" >&2
        echo -e "${YELLOW}--- $alias ---${NC}" >&2
        cat "$pub" >&2
    done

    echo "" >&2
    echo -e "  ${BLUE}GitHub:${NC}    https://github.com/settings/ssh/new" >&2
    echo -e "  ${BLUE}Bitbucket:${NC} https://bitbucket.org/account/settings/ssh-keys/" >&2
    echo "" >&2
    echo -e "  Test once added:  ${BLUE}ssh -T git@github.com${NC}  /  ${BLUE}ssh -T git@bitbucket.org${NC}" >&2
    echo "" >&2
}

main() {
    echo "" >&2
    echo -e "${GREEN}========================================${NC}" >&2
    echo -e "${GREEN}  SSH Key Setup (GitHub + Bitbucket)    ${NC}" >&2
    echo -e "${GREEN}========================================${NC}" >&2
    echo "" >&2

    ensure_ssh_dir
    local email
    email="$(resolve_email)"
    info "Key comment email: $email"

    for entry in "${HOSTS[@]}"; do
        local alias="${entry%%|*}"
        local host="$(echo "$entry" | cut -d'|' -f2)"
        local suffix="${entry##*|}"
        generate_key "$suffix" "$email"
        add_ssh_config_block "$alias" "$host" "$suffix"
    done

    add_keys_to_agent
    print_public_keys
}

main "$@"
