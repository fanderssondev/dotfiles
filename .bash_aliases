# copy to clipboard
alias clip='xclip -sel clip -r'

# clear the terminal
alias c='clear'

# apt
alias aptall="sudo apt update && sudo apt dist-upgrade && sudo apt autoremove"
alias aptupd="sudo apt update"
alias aptupg="sudo apt update && sudo apt dist-upgrade"
alias aptaut="sudo apt autoremove"

# history
alias h='history'

# ~/scripts/vm_man.sh script
alias vm-man="~/scripts/vm_man.sh"

# email script
alias nee='/home/fredrik/scripts/email_new_employee.sh '

# dotfiles git alias
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# show date/time format in history
export HISTTIMEFORMAT="%F %T "

# create WIN home dir env
export WINHOME="/mnt/c/Users/fredrik.andersson"

# create WINHOME\Downloads dir env
export WINHOME_DOWNLOADS="/mnt/c/Users/fredrik.andersson/Downloads"

# use Windows ssh-agent
#alias ssh='ssh.exe'
#alias ssh-add='ssh-add.exe'

# 1Password alias
alias op="/mnt/c/Windows/op.exe"

