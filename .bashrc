# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

shopt -s extglob

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export EDITOR=emacs
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=10000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'
alias nas='smbclient //192.168.1.36/home -U harfang%19830706'
alias emacs='/home/dm200/bin/myemacs'
alias wifion='sudo wifi_switch on'
alias wifioff='sudo wifi_switch off'


# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

PATH=/home/dm200/bin:/opt/bin:/sbin:$PATH

alias fbterm="LANG=zh_CN.UTF-8 fbterm"
alias agi="sudo apt-get install"
alias acs="sudo apt-cache search"
alias diary="diary /mnt/vfat/diary"
alias tibiji="w3m tibiji.com/autumnc"
alias qemacs="emacs -Q"

#pureline
source /home/dm200/pureline/pureline /home/dm200/.pureline.conf

mount|grep /mnt/vfat > /dev/null
if [ $? -eq 1 ]; then
    mount /mnt/vfat
fi

sudo loadkeys /usr/local/share/keymaps/dm200_console.map
sudo backlight 40

#case "$TERM" in
#  linux*)
#      alias fbterm='LANG=zh_CN.UTF-8 fbterm'
#      export TERM=fbterm
#      fbterm tmux
#	;;
#esac

# You can echo $(tty) to see for yourself, might be different for you
case $(tty) in
  /dev/tty[0-9]*)
    # $TERM must be set to fbterm before fbterm starts, AND in fbterm before tmux starts.
    export TERM='fbterm';
    alias fbterm='LANG=zh_CN.UTF-8 fbterm'
    fbterm
    ;;
# /dev/pts/* isn't always the same, but seems to always start at 0 or 1 in my config, hence the extra checks.    
  /dev/pts/0)
    export TERM='fbterm';
    # Set fbterm's grey-ish white to an actual white
    echo -en "\e[3;7;255;255;255}";
    tmux;
    ;;
  /dev/pts/1)
    if [[ -n $TMUX ]]
    then
      # Once in tmux, $TERM must be set to screen-256color to get that colory goodness.
      export TERM='screen-256color';
    else
      export TERM='fbterm';
      echo -en "\e[3;7;255;255;255}";
      tmux;
    fi
    ;;
  *)
esac

# Bonus colored bash prompt
source /home/dm200/bin/colors
#export PS1="\[$orange\]u\[$peach\]@\[$light_green\]\h\[$peach\]:\[$light_blue\]\w\[$peach\]\$ \[$reset\]"