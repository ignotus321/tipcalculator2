#!/bin/bash

# Author: Gabriel Staples

# This file is part of eRCaGuy_dotfiles: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles

# sync_git_repo_from_pc1_to_pc2.sh
#
# Sometimes you need to develop software on one machine (ex: a decent laptop, running an IDE like
# Eclipse) while building on a remote server machine (ex: a powerful desktop, or a paid cloud-based
# server such as AWS or Google Cloud--like this guy: https://matttrent.com/remote-development/). The
# problem, however, is "how do I sync from the machine I work on to the machine I build on?". This
# script answers that problem. It uses git to sync from one to the other. Git is preferred over
# rsync or other sync tools since they try to sync *everything* and on large repos they take FOREVER
# (dozens of minutes, to hours)! This script is lightning-fast (seconds) and ***safe***, because it
# always backs up any uncommitted changes you have on either PC1 or PC2 before changing anything!
#
# A typical run might take <= ~30 seconds to 1 minute, and require ~25 MB of data (which you care
# about if running on a hotspot on your cell phone).
#
# Run it from the *client* machine where you develop code (PC1), NOT the server where you will build
# the code (PC2)!
#
# It MUST be run from a directory inside the repo you are syncing FROM.

# -------------
# INSTALLATION:
# -------------
#
# See also: "README_git-sync_repo_from_pc1_to_pc2.md" for more information.
#
# 1. Copy the ".bash_aliases_private" file to your home directory:
#           cp -i path/to/eRCaGuy_dotfiles/home/.sync_git_repo_private ~
# 2. Edit the copy of that file in your home dir ("~/.sync_git_repo_private") as desired,
#    updating the variables in it with your custom information.
# 3. Ensure all your ssh keys are set up on both PC1 and PC2. This includes A) the keys to push/pull
#    to/from your remote git repos, and B) the keys required to ssh from PC1 into PC2.
# 4. Manually `git clone` your repo onto both PC1 and PC2.
# 5. On PC1, create symlinks in ~/bin to this sync script so you can run it from anywhere:
#           cd /path/to/here
#           mkdir -p ~/bin
#           ln -s "${PWD}/sync_git_repo_from_pc1_to_pc2.sh" ~/bin/gs_sync_git_repo_from_pc1_to_pc2
# 6. See the help menu for more details on the command:
#           gs_sync_git_repo_from_pc1_to_pc2 -h
# 7. Now cd into a repo on PC1 that you want to sync from PC1 (ex: some light development machine)
#    to PC2 (ex: some powerful build machine), and run this script:
#           gs_sync_git_repo_from_pc1_to_pc2
#    You can run the sync script whenever you have changes you want to push from PC1 to PC2 for
#    building or testing!
# 8. Done! About a minute later the sync will be complete. Pay attention to the output messages
#    to see what `git` is doing behind the scenes, and to ensure it worked and no errors occurred.

# References:
# 1. For main notes & reference links see "sync_git_repo_from_pc1_to_pc2--notes.md"
# 1. Bash numerical comparisons:
#    https://stackoverflow.com/questions/18668556/comparing-numbers-in-bash/18668580#18668580
# 1. How to create a branch in a remote git repository:
#    https://tecadmin.net/how-to-create-a-branch-in-remote-git-repository/
# 1. [example of a previous bash program I wrote, to aid myself as I write in bash]:
#    https://github.com/ElectricRCAircraftGuy/PDF2SearchablePDF/blob/master/pdf2searchablepdf.sh

# Background Research:
# 1. Google search for "workflow to develop locally but build remotely" -
#    https://www.google.com/search?q=workflow+to+develop+locally+but+build+remotely&oq=workflow+to+develop+locally+but+build+remotely&aqs=chrome..69i57.7154j0j7&sourceid=chrome&ie=UTF-8
#   1. *****"Developing on a remote server _Without Jupyter and Vim_" - https://matttrent.com/remote-development/
# 1. Google search for "eclipse work local build remote" -
#    https://www.google.com/search?q=eclipse+work+local+build+remote&oq=eclipse+work+local+build+remote&aqs=chrome..69i57.218j0j9&sourceid=chrome&ie=UTF-8
#   1. https://stackoverflow.com/questions/4216822/work-on-a-remote-project-with-eclipse-via-ssh

# NOTES TO SELF:
# Tests to run:
# 1) Test `echo "Detected there is no commit to reset."` below!
#       touch file
#       git add file
#       rm file
#       git status
#       # now, 'file' is both staged for commit AND deleted, so `git add -A` followed by `git commit`
#       # would have `git commit` error out and say: "nothing to commit, working tree clean".
#       # So, let's get into this situation and ensure my script still works ok and handles this
#       # edge case!
#       gs_sync_git_repo_from_pc1_to_pc2

# ==================================================================================================
# PROGRAM PARAMETERS
# ==================================================================================================

VERSION="0.2.0"
AUTHOR="Gabriel Staples"

RETURN_CODE_SUCCESS=0
RETURN_CODE_ERROR=1

SCRIPT_NAME="$(basename "$0")"
README_URL="https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/blob/master/useful_scripts/README_git-sync_repo_from_pc1_to_pc2.md"
SOURCE_CODE_URL="https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/blob/master/useful_scripts/sync_git_repo_from_pc1_to_pc2.sh"
VERSION_STR_SHORT="sync_git_repo_from_pc1_to_pc2 (run as '$SCRIPT_NAME') version $VERSION"

VERSION_STR_LONG="
$VERSION_STR_SHORT
Author = $AUTHOR
Readme = $README_URL
Source Code = $SOURCE_CODE_URL
See '$SCRIPT_NAME -h' for more info.
"

HELP_STR="\
$VERSION_STR_SHORT

Purpose: synchronize a git repo from one computer (\"PC1\") to another (\"PC2\"). This is useful,
for example, to edit and write code on a local laptop (\"PC1\") while building on a more-powerful,
remote desktop (\"PC2\").

Usage:

    $SCRIPT_NAME [pc2_target_name [cmd]]

            Synchronize the git repo (whose directory you are currently in when running the command)
            on the local computer (\"PC1\") to the remote 'pc2_target_name' computer
            (\"PC2\"). Then, optionally run the command 'cmd' on PC2 in its target git repository
            path (ie: directory) when done.

            The input paramter 'pc2_target_name' is optional, UNLESS you want to pass in a 'cmd' to
            run when done, in which case 'pc2_target_name' is mandatory and must come before 'cmd',
            as shown above.

            You must set and configure your 'pc2_target_name' options as 'TARGET' variables inside
            your custom  \"~/.sync_git_repo_private\" file. If 'pc2_target_name' is not passed as
            an argument to this program call, it defaults to 'DEFAULT_TARGET' which you must also
            set inside your custom \"~/.sync_git_repo_private\" file.

            When the repo is done synchronizing from PC1 to PC2, it will run 'cmd' on PC2 in the
            directory of the target git repository on PC2.

    $SCRIPT_NAME
            Run the script with the target set to the value of 'DEFAULT_TARGET', as defined by the
            user in their custom \"~/.sync_git_repo_private\" file.

    $SCRIPT_NAME -t
            Print all user-defined 't'argets the user has defined inside
            \"~/.sync_git_repo_private\".

    $SCRIPT_NAME -h
            print this help menu

    $SCRIPT_NAME -?
            print this help menu

    $SCRIPT_NAME -v
            print the author and version

Private Usage
(these are calls the script itself automatically makes):

    $SCRIPT_NAME --update_pc2 <pc2_git_repo_target_dir> <sync_branch>
            Finish synchronizing the changes from GitHub to PC2 in PC2's 'pc2_git_repo_target_dir',
            from the remote 'sync_branch'. The script itself calls this automatically on PC2 via an
            ssh command to PC2, when needed.

Examples:

    $SCRIPT_NAME
            Syncrhonize PC1 to PC2 where PC2 is the \"default\" target.
    $SCRIPT_NAME default
            Same as above, except explicitly specify \"default\" target.
    $SCRIPT_NAME desktop
            Synchronize to user-defined \"desktop\" target.
    $SCRIPT_NAME desktop2
            Synchronize to user-defined \"desktop2\" target.

  With an optional 'cmd' parameter:

    $SCRIPT_NAME default 'time bazel build //...'; gs_alert
            Synchronize from PC1 to PC2, where PC2 is the explicitly-named 'default' target, AND
            then run the command 'time bazel build //...' on PC2 in the target repo directory
            on that PC when done synchronizing! Finally, when all of that finishes, run the
            'gs_alert' alias to beep and open a popup to indicate the operation is complete.
            Note: the 'gs_alert' alias is found here:
            https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/blob/master/home/.bash_aliases

Readme:
    $README_URL

Source Code:
    $SOURCE_CODE_URL
"

# ANSI Color Codes
# See this file, approximately here:
# https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/blob/master/useful_scripts/git-diffn.sh#L126
COLOR_OFF="\033[m"
COLOR_RED="\033[31m"
COLOR_GRN="\033[32m"
COLOR_BLU="\033[34m"
COLOR_CYA="\033[36m"

# ==================================================================================================
# FUNCTION DEFINITIONS
# ==================================================================================================

# echo (print) the passed-in text in red
echo_red() {
    echo -e "${COLOR_RED}$@${COLOR_OFF}"
}

# echo (print) the passed-in text in green
echo_grn() {
    echo -e "${COLOR_GRN}$@${COLOR_OFF}"
}

# echo (print) the passed-in text in blue
echo_blu() {
    echo -e "${COLOR_BLU}$@${COLOR_OFF}"
}

# echo (print) the passed-in text in cyan
echo_cya() {
    echo -e "${COLOR_CYA}$@${COLOR_OFF}"
}

print_help() {
    echo "$HELP_STR" | less -RFX
}

print_version() {
    echo "$VERSION_STR_LONG"
}


# Run this always--this function shall get called every run
run_always() {
    # See my answer here:
    # https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel/60157372#60157372
    PATH_TO_THIS_SCRIPT="$(realpath "$0")"
    echo "PATH_TO_THIS_SCRIPT = \"$PATH_TO_THIS_SCRIPT\""
    echo "Running on PC user@hostname: $USER@$HOSTNAME"
}

parse_args() {
    PC_TO_RUN_ON="pc1"
    pc2_target_name="default"
    pc2_target_cmd=""

    # 1. Intended for private usage

    # Call only `--update_pc2` function if desired (ie: when running this script from PC2 only!)
    # Calling syntax: `./sync_git_repo_from_pc1_to_pc2.sh --update_pc2 <pc2_git_repo_target_dir> <sync_branch>'
    if [ "$1" == "--update_pc2" ]; then  # see `man test` or `man [` for meaning of `[ ]`.
        if [ $# -eq 3 ]; then
            PC_TO_RUN_ON="pc2"
            PC2_GIT_REPO_TARGET_DIR="$2"
            SYNC_BRANCH="$3"
            return $RETURN_CODE_SUCCESS
        else
            echo_red "ERROR: '--update_pc2' command missing 2nd and/or 3rd arguments!"
            exit $RETURN_CODE_ERROR
        fi
    fi

    # 2. Public usage

    # Help menu
    if [ "$1" == "-h" ] || [ "$1" == "-?" ]; then
        print_help
        exit $RETURN_CODE_SUCCESS
    # Version
    elif [ "$1" == "-v" ]; then
        print_version
        exit $RETURN_CODE_SUCCESS
    # Print targets
    elif [ "$1" == "-t" ]; then
        read_user_parameters
        echo ""
        print_targets
        exit $RETURN_CODE_SUCCESS
    fi

    # Reminder to self: see bash associative array tutorial here!:
    # https://www.artificialworlds.net/blog/2012/10/17/bash-associative-array-examples/

    if [ "$#" -eq "1" ];  then
        pc2_target_name="$1"
    elif [ "$#" -eq "2" ];  then
        pc2_target_name="$1"
        pc2_target_cmd="$2"
    elif [ "$#" -gt "2" ];  then
        echo_red "ERROR: too many arguments!"
        exit $RETURN_CODE_ERROR
    fi
}

print_targets() {
    echo "Valid targets you have already defined inside \"~/.sync_git_repo_private\" include:"
    for target in "${!PC2_USERNAME[@]}"; do
        echo "  $target"
    done
}

# Read the parameters from the user's "~/.sync_git_repo_private" file.
read_user_parameters() {
    # See bash associative array tutorial here!:
    # https://www.artificialworlds.net/blog/2012/10/17/bash-associative-array-examples/
    # See also `help declare`. NB: `-g` makes these variables global; otherwise they would be
    # local to this function only!
    # - Note: use `unset` to delete a variable. Ex: `unset PC2_USERNAME`.
    declare -gA PC2_USERNAME
    declare -gA PC2_HOSTNAME
    declare -gA PC2_TARGETDIR
    declare -gA PC2_SYNCBRANCH

    # Export these variables so that these will be the variables the user is setting in
    # their custom "~/.sync_git_repo_private" file.
    export PC2_USERNAME
    export PC2_HOSTNAME
    export PC2_TARGETDIR
    export PC2_SYNCBRANCH

    if [ -f ~/.sync_git_repo_private ]; then
        # Source this file only if it exists
        . ~/.sync_git_repo_private
    else
        echo_red "\
ERROR! You must have a copy of the \"eRCaGuy_dotfiles/home/.sync_git_repo_private\" file in
\"~/.sync_git_repo_private\", with your custom configuration settings in it. Please see the
installation instructions in the top of this script for installation details. Script location:
\"$PATH_TO_THIS_SCRIPT\"."
        exit $RETURN_CODE_ERROR
    fi

    # Copy defaults into the associative array:
    if [ -n "$DEFAULT_TARGET" ]; then

        PC2_USERNAME["default"]="${PC2_USERNAME["$DEFAULT_TARGET"]}"
        PC2_HOSTNAME["default"]="${PC2_HOSTNAME["$DEFAULT_TARGET"]}"
        PC2_TARGETDIR["default"]="${PC2_TARGETDIR["$DEFAULT_TARGET"]}"
        PC2_SYNCBRANCH["default"]="${PC2_SYNCBRANCH["$DEFAULT_TARGET"]}"
    else
        echo_red "\
ERROR: you must set the 'DEFAULT_TARGET' variable in \"~/.sync_git_repo_private\" to something."
        exit $RETURN_CODE_ERROR
    fi

    PC2_SSH_USERNAME="${PC2_USERNAME["$pc2_target_name"]}"
    PC2_SSH_HOST="${PC2_HOSTNAME["$pc2_target_name"]}"
    PC2_GIT_REPO_TARGET_DIR="${PC2_TARGETDIR["$pc2_target_name"]}"
    SYNC_BRANCH="${PC2_SYNCBRANCH["$pc2_target_name"]}"

    echo "pc2_target_name = $pc2_target_name"
    echo "DEFAULT_TARGET (called with \"default\") = $DEFAULT_TARGET"

    echo "PC2_SSH_USERNAME = $PC2_SSH_USERNAME"
    echo "PC2_SSH_HOST = $PC2_SSH_HOST"
    echo "PC2_GIT_REPO_TARGET_DIR = $PC2_GIT_REPO_TARGET_DIR"
    echo "SYNC_BRANCH = $SYNC_BRANCH"

    # Ensure target name is valid and that none of these variables are empty strings.
    if [ -z "$PC2_SSH_USERNAME" ] || [ -z "$PC2_SSH_HOST" ] || [ -z "$PC2_GIT_REPO_TARGET_DIR" ] ||
    [ -z "$SYNC_BRANCH" ]; then
        echo_red "ERROR: invalid 'pc2_target_name' (\"$pc2_target_name\") passed to this program."
        echo_red "  Please add this target to your custom \"~/.sync_git_repo_private\" file, or"
        echo_red "  choose a valid target already defined in that file, and try again."
        print_targets
        exit $RETURN_CODE_ERROR
    fi
}

# A function to obtain the temporary directory we will use, given a directory to a git repo.
# Call syntax: `get_temp_dir "$REPO_ROOT_DIR`
# Example: if REPO_ROOT_DIR="~/dev/myrepo", then this function will return (echo out) "~/dev/myrepo_temp" as
#   the temp directory
get_temp_dir () {
    REPO_ROOT_DIR="$1"                      # Ex: /home/gabriel/dev/eRCaGuy_dotfiles
    BASENAME="$(basename "$REPO_ROOT_DIR")" # Ex: eRCaGuy_dotfiles
    DIRNAME="$(dirname "$REPO_ROOT_DIR")"   # Ex: /home/gabriel/dev
    TEMP_DIR="${DIRNAME}/${BASENAME}_temp"  # this is where temp files will be stored
    echo "$TEMP_DIR"
}

# (Runs on both PC1 and PC2):
# Create a temporary directory to store the results, & check the git repo for changes--very similar
# to what a human is doing when calling `git status`. This function determines if any local,
# uncommitted changes or untracked files exist.
create_temp_and_check_for_changes() {
    # Get git root dir (so you can do `git commit -A` from this dir in case you are in a lower
    # dir--ie: cd to the root FIRST, then `git commit -A`, then cd back to where you were). See:
    # https://stackoverflow.com/questions/957928/is-there-a-way-to-get-the-git-root-directory-in-one-command/957978#957978
    REPO_ROOT_DIR="$(git rev-parse --show-toplevel)" # Ex: /home/gabriel/dev/eRCaGuy_dotfiles
    # echo "REPO_ROOT_DIR = $REPO_ROOT_DIR" # debugging

    # Make a temp dir one level up from REPO_ROOT_DIR, naming it "repo-name_temp"
    TEMP_DIR="$(get_temp_dir "$REPO_ROOT_DIR")"
    # echo "TEMP_DIR = $TEMP_DIR" # debugging
    mkdir -p "$TEMP_DIR"

    echo "Storing temp files in \"$TEMP_DIR\"."

    # See if any changes exist (as normally shown by `git status`).
    # If any changes do exist, back up the file paths which are:
    # 1) changed and staged
    # 2) changed and not staged
    # 3) untracked

    FILES_STAGED="$TEMP_DIR/1_staged.txt"
    FILES_NOT_STAGED="$TEMP_DIR/2_not_staged.txt"
    FILES_UNTRACKED="$TEMP_DIR/3_untracked.txt"

    # 1) Get list of changed and staged files:
    # See: https://stackoverflow.com/questions/33610682/git-list-of-staged-files/33610683#33610683
    git diff --name-only --cached > "$FILES_STAGED"
    num_staged=$(cat "$FILES_STAGED" | wc -l)
    echo "  num_staged = $num_staged"

    # 2) Get list of changed and not staged files:
    # See (Implicitly learned from here): https://stackoverflow.com/questions/33610682/git-list-of-staged-files/33610683#33610683
    git diff --name-only > "$FILES_NOT_STAGED"
    num_not_staged=$(cat "$FILES_NOT_STAGED" | wc -l)
    echo "  num_not_staged = $num_not_staged"

    # 3) Get list of untracked files:
    # See: https://stackoverflow.com/questions/3801321/git-list-only-untracked-files-also-custom-commands/3801554#3801554
    git ls-files --others --exclude-standard > "$FILES_UNTRACKED"
    num_untracked=$(cat "$FILES_UNTRACKED" | wc -l)
    echo "  num_untracked = $num_untracked"

    total=$[$num_staged + $num_not_staged + $num_untracked]
    echo "  total = $total"
}

# Load the 'pc2_actual_commit_hash' variable with the actual commit hash currently checked-out
# on pc2!
get_pc2_actual_commit_hash() {
    pc2_actual_commit_hash="unknown"
    # NB: do NOT use `-t` here with `ssh`, or else the `pc2_actual_commit_hash` will have some sort
    # of hidden char(s) in it or something and fail to match the actual commit hash from pc1, even
    # when they really *do* match!
    pc2_actual_commit_hash="$(ssh $PC2_SSH_USERNAME@$PC2_SSH_HOST \
    "cd \"$PC2_GIT_REPO_TARGET_DIR\"; git rev-parse HEAD")"

    # Obtain return code from `ssh`; see: https://stackoverflow.com/a/38533260/4561887
    ret_code="$?"
    if [ "$ret_code" -ne "$RETURN_CODE_SUCCESS" ]; then
        echo_red "ERROR: Failed to get pc2 actual commit hash! Please try again."
        exit $ret_code
    fi
}

# On local machine:
# Summary: Look for changes. Commit them to current local branch. Force Push them to remote SYNC
# branch. Uncommit them on local branch. Restore original state by re-staging any files that were
# previously staged. Done.
sync_pc1_to_remote_branch () {
    echo ""
    echo "============================"
    echo "Syncing PC1 to remote branch"
    echo "============================"
    echo "Preparing to push current branch with all changes (including staged, unstaged, & untracked files)"
    echo "  to remote sync branch."

    synced_commit_hash="NONE"

    create_temp_and_check_for_changes

    # Commit uncommitted changes (if any exist) into a temporary commit we will uncommit later
    made_temp_commit=false
    if [ "$total" -gt "0" ]; then
        # Uncommitted changes *do* exist!
        made_temp_commit=true

        echo "Making a temporary commit of all uncommitted changes."
        cd "$REPO_ROOT_DIR"
        # Prepare a multi-line commit message in a variable first, then do the commit w/this msg.
        # See *my own answer here!*:
        # https://stackoverflow.com/questions/29933349/how-can-i-make-git-commit-messages-divide-into-multiple-lines/60826932#60826932
        commit_msg="AUTOMATIC COMMIT TO SYNC TO PC2 (BUILD MACHINE)"

        # Staged files
        num="$num_staged"
        file_names_path="$FILES_STAGED"
        if [ "$num" -gt "0" ]; then
            if [ "$num" -eq "1" ]; then
                verbiage="1. This ${num} file was **staged** & is now committed:"
            else
                verbiage="1. These ${num} files were **staged** & are now committed:"
            fi
            commit_msg="$(printf "${commit_msg}\n\n${verbiage}")"
            file_names="$(cat "$file_names_path")"
            commit_msg="$(printf "${commit_msg}\n\n${file_names}")"
        fi

        # Not staged files
        num="$num_not_staged"
        file_names_path="$FILES_NOT_STAGED"
        if [ "$num" -gt "0" ]; then
            if [ "$num" -eq "1" ]; then
                verbiage="2. This ${num} file was changed but **not staged** & is now committed:"
            else
                verbiage="2. These ${num} files were changed but **not staged** & are now committed:"
            fi
            commit_msg="$(printf "${commit_msg}\n\n${verbiage}")"
            file_names="$(cat "$file_names_path")"
            commit_msg="$(printf "${commit_msg}\n\n${file_names}")"
        fi

        # Untracked files
        num="$num_untracked"
        file_names_path="$FILES_UNTRACKED"
        if [ "$num" -gt "0" ]; then
            if [ "$num" -eq "1" ]; then
                verbiage="3. This ${num} file was **untracked** & is now committed:"
            else
                verbiage="3. These ${num} files were **untracked** & are now committed:"
            fi
            commit_msg="$(printf "${commit_msg}\n\n${verbiage}")"
            file_names="$(cat "$file_names_path")"
            commit_msg="$(printf "${commit_msg}\n\n${file_names}")"
        fi

        git add -A
        error_msg="$(git commit -m "$commit_msg")"
        echo "$error_msg"
        error_msg_last_line="$(echo "$error_msg" | tail -n1)"
        if [ "$error_msg_last_line" == "nothing to commit, working tree clean" ]; then
            echo "Detected there is no commit to reset."
            made_temp_commit=false
        fi
    fi

    # Print out and store current commit hash; how to get hash of current commit:
    # see: https://stackoverflow.com/questions/949314/how-to-retrieve-the-hash-for-the-current-commit-in-git/949391#949391
    synced_commit_hash="$(git rev-parse HEAD)"

    # Only push the changes if pc2 doesn't already have these changes!
    # - TODO: **ALSO** consider checking to see if the commit we are about to push is already on the
    #   remote server, and if it is, there is NOT a need to push to the remote server even though
    #   there IS a need to pull the new changes onto PC2. Note: think about this though: this may
    #   not actually be a scenario we will ever see in practice, so maybe this isn't necessary
    #   after-all.
    get_pc2_actual_commit_hash
    if [ "$synced_commit_hash" == "$pc2_actual_commit_hash" ]; then
        need_to_sync_to_pc2="false"
        echo "NOTHING TO DO. PC2 already has the changes from PC1!:"
        echo "  synced_commit_hash from pc1 = $synced_commit_hash"
        echo "  pc2_actual_commit_hash      = $pc2_actual_commit_hash"
    else
        # The current commit hash on pc2 does NOT equal what's on pc1, so DO sync pc1's changes
        # to the remote branch.
        echo "Force pushing commit ${synced_commit_hash} to remote \"$SYNC_BRANCH\" branch."
        echo "ENSURE YOU HAVE YOUR PROPER SSH KEYS FOR GITHUB LOADED INTO YOUR SSH AGENT"
        echo "  (w/'ssh-add <my_github_key>') OR ELSE THIS WILL FAIL!"
        # TODO: figure out if origin is even available (ex: via a ping or something), and if not, error out right here!
        git push --force origin "HEAD:$SYNC_BRANCH" # MAY NEED TO COMMENT OUT DURING TESTING

        # Obtain return code from the last cmd (`git push`); see:
        # https://stackoverflow.com/a/38533260/4561887
        ret_code="$?"
        if [ "$ret_code" -ne "$RETURN_CODE_SUCCESS" ]; then
            echo_red "ERROR: FAILED to 'git push'! Please try again."
            exit $ret_code
        fi

        echo "Done syncing PC1 to remote branch."
    fi

    # Uncommit the temporary commit we committed above
    if [ "$made_temp_commit" = "true" ]; then
        echo "Uncommitting the temporary commit we made above."
        git reset HEAD~

        # Now re-stage any files that were previously staged
        # See: 1) https://stackoverflow.com/questions/4227994/how-do-i-use-the-lines-of-a-file-as-arguments-of-a-command/4229346#4229346
        # and  2) *****https://www.cyberciti.biz/faq/unix-howto-read-line-by-line-from-file/
        # and  3) *****+ [my own ans I just made now]:
        #         https://stackoverflow.com/questions/4227994/how-do-i-use-the-lines-of-a-file-as-arguments-of-a-command/60276836#60276836
        if [ "$num_staged" -gt "0" ]; then
            echo "Re-staging (via 'git add') any files that were previously staged."
            # `git add` each file that was staged before in order to stage it again like it was
            # - See link 3 just above for how this works
            while IFS= read -r line
            do
                echo "  git add \"$line\""
                git add "$line"
            done < "$FILES_STAGED"
        fi
    fi
}

# This is the main command to run on PC2 via ssh from PC1 in order to sync the remote branch to PC2!
# Call syntax: `update_pc2 "$PC2_GIT_REPO_TARGET_DIR"`
update_pc2 () {
    echo "---\"update_pc2\" script start---"

    PC2_GIT_REPO_TARGET_DIR="$1"

    cd "$PC2_GIT_REPO_TARGET_DIR"
    create_temp_and_check_for_changes

    # 1st, back up any uncommitted changes that may exist

    if [ "$total" -gt "0" ]; then
        # Uncommitted changes *do* exist!
        echo "Uncommitted changes exist in PC2's repo, so committing them to new branch to save them in case"
        echo "  they are important."

        # Produce a new branch name to back up these uncommitted changes.

        # Get just the name of the currently-checked-out branch:
        # See: https://stackoverflow.com/questions/6245570/how-to-get-the-current-branch-name-in-git/12142066#12142066
        # - Will simply output "HEAD" if in a 'detached HEAD' state (ie: not on any branch)
        current_branch_name=$(git rev-parse --abbrev-ref HEAD)

        timestamp="$(date "+%Y%m%d-%H%Mhrs-%Ssec")"
        new_branch_name="${current_branch_name}_SYNC_BAK_${timestamp}"

        echo "Creating branch \"$new_branch_name\" to store all uncommitted changes."
        git checkout -b "$new_branch_name"

        echo "Committing all changes to branch \"$new_branch_name\"."
        git add -A
        git commit -m "DO BACKUP OF ALL UNCOMMITTED CHANGES ON PC2 (TARGET PC/BUILD MACHINE)"
    fi

    # 2nd, check out the sync branch and pull latest changes just pushed to it from PC1

    # Hard-pull from the remote server to fully overwrite local copy of this branch.
    # See: https://stackoverflow.com/questions/1125968/how-do-i-force-git-pull-to-overwrite-local-files/8888015#8888015
    # TODO: figure out if origin is even available (ex: via a ping or something), and if not, error out right here!
    echo "ENSURE YOU HAVE YOUR PROPER SSH KEYS FOR GITHUB LOADED INTO YOUR SSH AGENT"
    echo "  (w/'ssh-add <my_github_key>') OR ELSE THESE FOLLOWING STEPS WILL FAIL!"
    echo "Force pulling from remote \"${SYNC_BRANCH}\" branch to overwrite local copy of this branch."
    echo "  1/4: 'git fetch origin \"${SYNC_BRANCH}\"'"
    git fetch origin "${SYNC_BRANCH}"           # MAY NEED TO COMMENT OUT DURING TESTING
    echo "  2/4: 'git checkout \"origin/${SYNC_BRANCH}\"'"
    git checkout "origin/${SYNC_BRANCH}"        # MAY NEED TO COMMENT OUT DURING TESTING
    echo "  3/4: 'git branch -D \"${SYNC_BRANCH}\"'"
    git branch -D "${SYNC_BRANCH}"              # MAY NEED TO COMMENT OUT DURING TESTING
    echo "  4/4: 'git checkout -b \"${SYNC_BRANCH}\"'"
    git checkout -b "${SYNC_BRANCH}"            # MAY NEED TO COMMENT OUT DURING TESTING

    echo "---\"update_pc2\" script end---"
}

# On remote machine:
# Summary: Look for changes. Commit them to a new branch forked off of current branch. Call it
# current_branch_SYNC_BAK_20200217-2310hrs. Check out ${SYNC_BRANCH} branch. Pull and hard reset.
# Done! We are ready to build now!
sync_remote_branch_to_pc2 () {
    echo ""
    echo "============================"
    echo "Syncing remote branch to PC2"
    echo "============================"

    # rsync a copy of this script over to a temp dir on PC2
    TEMP_DIR="$(get_temp_dir "$PC2_GIT_REPO_TARGET_DIR")"
    # echo "TEMP_DIR = \"$TEMP_DIR\"" # Debugging
    echo "Making temp dir on PC2: \"$TEMP_DIR\"."
    ssh $PC2_SSH_USERNAME@$PC2_SSH_HOST "mkdir -p \"$TEMP_DIR\""
    echo "Copying this script to temp dir."
    rsync "$PATH_TO_THIS_SCRIPT" "$PC2_SSH_USERNAME@$PC2_SSH_HOST:$TEMP_DIR/"

    script_filename="$(basename "$PATH_TO_THIS_SCRIPT")"
    script_path_on_pc2="$TEMP_DIR/$script_filename"
    # echo "script_path_on_pc2 = $script_path_on_pc2" # Debugging

    echo "Calling script on PC2 to sync from remote branch to PC2."
    # NB: the `-t` flag to `ssh` tells it that it is an interactive shell. Some commands which use
    # `screen` internally require the `-t` flag when being called over ssh. Using `-t` also has the
    # effect of causing it to print out "Connection to $HOSTNAME closed" whenever the cmd is over.
    # See `man ssh` to read more about the -t flag. Also see here:
    # https://malcontentcomics.com/systemsboy/2006/07/send-remote-commands-via-ssh.html
    # and here: https://www.cyberciti.biz/faq/unix-linux-execute-command-using-ssh/
    ssh -t $PC2_SSH_USERNAME@$PC2_SSH_HOST  "$script_path_on_pc2 --update_pc2 \
    \"$PC2_GIT_REPO_TARGET_DIR\" \"$SYNC_BRANCH\""

    # Obtain return code from `ssh`; see: https://stackoverflow.com/a/38533260/4561887
    ret_code="$?"
    if [ "$ret_code" -ne "$RETURN_CODE_SUCCESS" ]; then
        echo_red "ERROR: FAILED TO SYNC! Please try again."
        exit $ret_code
    fi

    # Ensure the commit hash on PC2 is now what we expect
    get_pc2_actual_commit_hash
    if [ "$synced_commit_hash" != "$pc2_actual_commit_hash" ]; then
        # failure: print 1 as green and 1 as red
        echo -e "synced_commit_hash from pc1 = ${COLOR_GRN}${synced_commit_hash}${COLOR_OFF}"
        echo -e "pc2_actual_commit_hash      = ${COLOR_RED}${pc2_actual_commit_hash}${COLOR_OFF}"

        echo_red "ERROR: FAILED TO SYNC! Mismatch in pc1 synced commit hash vs pc2 actual commit hash."
        echo_red "Please try again."
        exit $RETURN_CODE_ERROR
    fi

    # success: print both as green
    echo -e "synced_commit_hash from pc1 = ${COLOR_GRN}${synced_commit_hash}${COLOR_OFF}"
    echo -e "pc2_actual_commit_hash      = ${COLOR_GRN}${pc2_actual_commit_hash}${COLOR_OFF}"

    echo_grn "Done syncing remote branch to PC2. It should be ready to be built on PC2 now!"
}

# Main code to run on PC1
main_pc1 () {
    DIR_START="$(pwd)"
    # echo "DIR_START = $DIR_START" # debugging

    need_to_sync_to_pc2="true"
    sync_pc1_to_remote_branch
    if [ "$need_to_sync_to_pc2" == "true" ]; then
        sync_remote_branch_to_pc2
    fi

    # Optional, but not a bad habit: cd back to where we started in case we ever add additional code
    # after this and expect to be in the dir where we started
    cd "$DIR_START"

    echo       ""
    echo       "=========================================================================================="
    echo       "SUMMARY:"
    echo       "=========================================================================================="
    echo       "  Commit hash synced:"
    echo_grn   "      From PC1:   ${synced_commit_hash}"
    echo_grn   "      Now on PC2: ${pc2_actual_commit_hash}"
    # For printf help, see: https://stackoverflow.com/questions/994461/right-align-pad-numbers-in-bash/994471#994471
    # and: http://www.cplusplus.com/reference/cstdio/printf/
    printf "  From PC1: %-35s Repo root: %s\n" "${USER}@${HOSTNAME}:" "${REPO_ROOT_DIR}"
    printf "  To PC2:   %-35s Repo root: %s\n" "${PC2_SSH_USERNAME}@${PC2_SSH_HOST}:" "${PC2_GIT_REPO_TARGET_DIR}"

    timestamp="$(date "+%Y.%m.%d %H:%Mhrs:%Ssec")"
    echo -e "  ${COLOR_GRN}Synchronization to PC2 completed successfully${COLOR_OFF} at timestamp: $timestamp"

    # Only run the target command on PC2 if one has been specified
    if [ -n "$pc2_target_cmd" ]; then
        echo -e  "Running cmd '${COLOR_BLU}${pc2_target_cmd}${COLOR_OFF}' on PC2 in directory \"$PC2_GIT_REPO_TARGET_DIR\":"
        echo -e  "    ssh -t $PC2_SSH_USERNAME@$PC2_SSH_HOST \"cd '$PC2_GIT_REPO_TARGET_DIR' && ${COLOR_BLU}${pc2_target_cmd}${COLOR_OFF}\""
        echo_blu "----"
        ssh -t $PC2_SSH_USERNAME@$PC2_SSH_HOST "cd '$PC2_GIT_REPO_TARGET_DIR' && $pc2_target_cmd"
        echo_blu "----"
    fi

    echo_blu "END!"
}

# ==================================================================================================
# MAIN PROGRAM ENTRY POINT
# ==================================================================================================

run_always "$@"
parse_args "$@"

if [ "$PC_TO_RUN_ON" == "pc1" ]; then
    read_user_parameters
    # Note: use `time` cmd in front to output the total time this process took when it ends!
    time main_pc1
elif [ "$PC_TO_RUN_ON" == "pc2" ]; then
    update_pc2 "$PC2_GIT_REPO_TARGET_DIR"
fi
