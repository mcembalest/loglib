#!/bin/bash

# Restricted shell for loglibrary documentation content
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CONTENT_ROOT="$SCRIPT_DIR/docs/content"
export BASH_SILENCE_DEPRECATION_WARNING=1

# Ensure content directory exists
if [[ ! -d "$CONTENT_ROOT" ]]; then
    echo "Error: Content directory not found at $CONTENT_ROOT"
    exit 1
fi

exec bash --rcfile <(cat <<'RC'
BASH_SILENCE_DEPRECATION_WARNING=1

cd() {
    local target="${1:-$CONTENT_ROOT}"
    
    # Sanitize input - remove dangerous characters and sequences
    target="${target//\.\./}"  # Remove .. sequences
    target="${target//\;/}"    # Remove semicolons
    target="${target//\&/}"    # Remove ampersands
    target="${target//\|/}"    # Remove pipes
    target="${target//\$/}"    # Remove dollar signs
    target="${target//\`/}"    # Remove backticks
    
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
    
    # Ensure path is within allowed content root
    if [[ "$resolved" == "$CONTENT_ROOT"* ]]; then
        builtin cd "$resolved"
    else
        echo "cd: Access restricted to docs/content directory"
        return 1
    fi
}

set_prompt() {
    local rel="${PWD#$CONTENT_ROOT}"
    rel="${rel#/}"
    if [[ -z "$rel" ]]; then
        PS1='docs> '
    else
        PS1="docs/$rel> "
    fi
}

PROMPT_COMMAND=set_prompt

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

builtin cd "$CONTENT_ROOT"
set_prompt
RC
)
