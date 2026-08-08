# --- put the genie in the box ------------------------------------------------
# Three letters to start Claude, from anywhere.
#
# There are two versions below. The one that is switched on is the one WITHOUT
# a `#` in front of it. To change your mind, move the `#` to the other line and
# open a new terminal window. That is the whole thing.
#
# The difference is whether it stops and asks you before every single command.
#
#   Without asking — you agree to the work in conversation, it says what it is
#   about to do and you say yes, and then it gets on with it. Setting a machine
#   up is hundreds of commands; approving them one at a time means you stop
#   reading and start pressing enter, which is worse than not being asked.
#
#   Asking every time — safer, and much slower. Choose this if you would rather
#   see each command before it runs.
#
# That is a real trade, and it is why this does not belong on a work computer.
#
# It deliberately does not move you anywhere. Which folder you are in matters,
# and `cd` is the one command worth learning on day one.

# Gets on with the work.
alias ccc='claude --dangerously-skip-permissions'

# Asks you before every command. Slower, safer.
# alias ccc='claude'
# -----------------------------------------------------------------------------
