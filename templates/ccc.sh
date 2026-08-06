# --- put the genie in the box ------------------------------------------------
# Three letters to start Claude, from anywhere.
#
# A function rather than an alias, so `ccc "fix my spreadsheet"` passes the words
# straight through instead of dropping them.
#
# The `cd` is deliberate and it is why this is worth having: it starts you in the
# folder your work lives in, so you never have to know where you are before you
# can begin. If that folder is missing the `cd` fails quietly and Claude opens
# wherever you are, which is the right way round — the shortcut should never be
# the reason you cannot start.
#
# `ccc holiday-photos` opens that project. The name is only treated as a folder
# if a folder by that name is actually sitting in ~/projects, so
# `ccc "fix my spreadsheet"` still arrives as a sentence and not as a failed cd.
ccc() {
  cd ~/projects 2>/dev/null
  if [ -d "$1" ]; then
    cd "$1"
    shift
  fi
  claude "$@"
}
# -----------------------------------------------------------------------------
