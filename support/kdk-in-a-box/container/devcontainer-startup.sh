#!/usr/bin/bash

# Add the `kdk.local` dns alias to the hosts file so it points to localhost
echo '127.0.0.1 kdk.local' | sudo tee -a /etc/hosts

# run `git pull` to get the most recent khulnasoft commits for the current branch.
# Note: This will only run on the devcontainer _create_ (or when the script is manually run),
#  so this shouldn't run into any issues with changes a user has already made, since the khulnasoft
#  repository is the one within the container, and not the one on the host.
cd ~/khulnasoft-development-kit/khulnasoft/ && git pull

# run the `kdk-container-startup.sh` script to start up khulnasoft services
bash ~/kdk-container-startup.sh
