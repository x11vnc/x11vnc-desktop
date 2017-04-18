#!/bin/bash
# User can pass e.g. --env HOST_UID=1003 so that UID in the container matches
# with the UID on the host. This is useful for Linux users, Mac and Windows
# already do transparent mapping of shared volumes.
if [ "$HOST_UID" ]; then
    usermod -u $HOST_UID $DOCKER_USER 2> /dev/null
fi
if [ "$HOST_GID" ]; then
    groupmod -g $HOST_GID $DOCKER_GROUP 2> /dev/null
fi

# This makes sure that all directories in HOME are accessible by the user.
# This helps avoiding issues wiht mounted volumes.
source /etc/container_environment.sh
find $DOCKER_HOME -type d -maxdepth 1 | sed "1d" | xargs chown $DOCKER_USER:$DOCKER_GROUP 2> /dev/null || true

# It is important for $HOME/.ssh to have correct ownership
chown -R $DOCKER_USER $DOCKER_HOME/.ssh
