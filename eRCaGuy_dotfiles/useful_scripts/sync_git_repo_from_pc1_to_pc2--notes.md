# This file is part of eRCaGuy_dotfiles: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles

Gabriel Staples
Sat. 15 Feb. 2020

------------------------------------------------------------------------------------------------------------------------
Notes to self on how to accomplish this "sync_git_repo_to_server.sh" script.
- THESE NOTES WERE WHAT I USED TO DESIGN AND WRITE THE SCRIPT. THEY HAVE NO DIRECT PURPOSE FOR A 
  USER OF THE SCRIPT.
------------------------------------------------------------------------------------------------------------------------

# Related:
1. Google search for "workflow to develop locally but build remotely" - https://www.google.com/search?q=workflow+to+develop+locally+but+build+remotely&oq=workflow+to+develop+locally+but+build+remotely&aqs=chrome..69i57.7154j0j7&sourceid=chrome&ie=UTF-8
    1. "Developing on a remote server _Without Jupyter and Vim_" - https://matttrent.com/remote-development/
2. Google search for "eclipse build work local build remote" - https://www.google.com/search?q=eclipse+build+work+local+build+remote&oq=eclipse+build+work+local+build+remote&aqs=chrome..69i57.230j0j9&sourceid=chrome&ie=UTF-8
    1. https://stackoverflow.com/questions/4216822/work-on-a-remote-project-with-eclipse-via-ssh

# References:
1. https://tecadmin.net/how-to-create-a-branch-in-remote-git-repository/
2. 

# Write script to:
1. `git status`, commit a "SYNC TO BUILD_MACHINE" commit if there are changes, 
2. do `git push --force origin <local_branch_name>:gabriel.staples_SYNC_TO_BUILD_MACHINE` branch [--force causes the remote branch to LOSE DATA, which is ok here]
    - this works too! `git push --force origin HEAD:gabriel.staples_SYNC_TO_BUILD_MACHINE` <=====
3. use ssh commands to pull it on the remote server:  
    See also: https://stackoverflow.com/questions/1125968/how-do-i-force-git-pull-to-overwrite-local-files/8888015#8888015
    ```bash
    git checkout gabriel.staples_SYNC_TO_BUILD_MACHINE
    git fetch origin gabriel.staples_SYNC_TO_BUILD_MACHINE
    git reset --hard origin gabriel.staples_SYNC_TO_BUILD_MACHINE
    ```
    then kick off the build manually on the remote server
4. Last step is to `git reset` back to before doing the "SYNC TO BUILD_MACHINE" commit on the local pc. 

See how this goes. If it works well, document it on Stack Overflow here:
https://stackoverflow.com/questions/4216822/work-on-a-remote-project-with-eclipse-via-ssh
Anywhere else to put it too?


TOOLS:

Get list of staged files:
See: https://stackoverflow.com/questions/33610682/git-list-of-staged-files/33610683#33610683
    
    git diff --name-only --cached

Get list of not staged, changed files:
See (Implicitly learned from here): https://stackoverflow.com/questions/33610682/git-list-of-staged-files/33610683#33610683

    git diff --name-only

Get list of untracked files:
See: https://stackoverflow.com/questions/3801321/git-list-only-untracked-files-also-custom-commands/3801554#3801554

    git ls-files --others --exclude-standard 


Get git root dir (so you can do `git commit -A` from this dir in case you are in a lower dir--ie: cd to the root FIRST, then `git commit -A`, then cd back to where you were)
See: https://stackoverflow.com/questions/957928/is-there-a-way-to-get-the-git-root-directory-in-one-command/957978#957978

    git rev-parse --show-toplevel

Get just the name of the currently-checked-out branch:  
See: https://stackoverflow.com/questions/6245570/how-to-get-the-current-branch-name-in-git/12142066#12142066  
-will simply output "HEAD" if in a 'detached HEAD' state (ie: not on any branch)

    git rev-parse --abbrev-ref HEAD

------

Note to self 1:51am 17 Feb. 2020:

On local machine:
Look for changes. Commit them to current local branch. Force Push them to remote SYNC branch. Uncommit them on local branch. Restore original state.
Done.


On remote machine:
Look for changes. Commit them to a new branch forked off current branch. Call it current_branch_SYNC_BAK_20200217-2310hrs13sec. 
Check out SYNC branch. Pull and hard reset. Done! We are ready to build now!









