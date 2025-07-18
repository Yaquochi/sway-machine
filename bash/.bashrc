# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

export LIBVIRT_DEFAULT_URI='qemu:///system'

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:~/go/bin
export PATH="$HOME/.cargo/bin:$PATH"
export HELIX_RUNTIME=~/src/helix/runtime

export TERM=xterm-256color
export VISUAL=vi
export EDITOR="$VISUAL"

eval "$(zoxide init bash)"
eval "$(fzf --bash)"
