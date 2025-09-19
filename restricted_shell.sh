#!/bin/bash

export CONTENT_ROOT="${CONTENT_ROOT:-$(pwd)/docs/content}"
export BASH_SILENCE_DEPRECATION_WARNING=1

WORKSPACE_ID=$(date +%s)_$(shuf -i 1000-9999 -n 1)
export WORKSPACE="/workspace/session_$WORKSPACE_ID"
mkdir -p "$WORKSPACE"

if [[ ! -d "$CONTENT_ROOT" ]]; then
    echo "Error: Content directory not found at $CONTENT_ROOT"
    exit 1
fi

exec bash --rcfile <(cat <<'RC'
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
BASH_SILENCE_DEPRECATION_WARNING=1

cd() {
    local target="${1:-$CONTENT_ROOT}"

    # Make absolute if relative
    if [[ "$target" != /* ]]; then
        target="$PWD/$target"
    fi

    # Resolve path and check if it exists
    local resolved
    resolved="$(builtin cd "$target" 2>/dev/null && pwd)" || {
        echo "cd: ${1:-$target}: No such file or directory"
        return 1
    }

    # Allow access to content root and workspace
    if [[ "$resolved" == "$CONTENT_ROOT"* ]] || [[ "$resolved" == "$WORKSPACE"* ]]; then
        builtin cd "$resolved"
    else
        echo "cd: Access restricted to docs/content and workspace directories"
        return 1
    fi
}

set_prompt() {
    if [[ "$PWD" == "$CONTENT_ROOT"* ]]; then
        local rel="${PWD#$CONTENT_ROOT}"
        rel="${rel#/}"
        if [[ -z "$rel" ]]; then
            PS1='> '
        else
            PS1="$rel> "
        fi
    elif [[ "$PWD" == "$WORKSPACE"* ]]; then
        local rel="${PWD#$WORKSPACE}"
        rel="${rel#/}"
        if [[ -z "$rel" ]]; then
            PS1='workspace> '
        else
            PS1="workspace/$rel> "
        fi
    else
        PS1='restricted> '
    fi
}

PROMPT_COMMAND=set_prompt

# Safe aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Helpful aliases for workspace
alias workspace='cd $WORKSPACE'
alias docs='cd $CONTENT_ROOT'


builtin cd "$CONTENT_ROOT"
set_prompt
RC
)