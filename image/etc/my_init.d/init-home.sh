#!/bin/bash
# User can pass e.g. --env HOST_UID=1003 so that UID in the container matches
# with the UID on the host. This is useful for Linux users. Mac and Windows
# already do transparent mapping of shared volumes.
if [ "$HOST_UID" -a "$DOCKER_UID" != "$HOST_UID" ]; then
    usermod -u $HOST_UID $DOCKER_USER 2> /dev/null
fi
if [ "$HOST_GID" -a "$DOCKER_GID" != "$HOST_GID" ]; then
    groupmod -g $HOST_GID $DOCKER_GROUP 2> /dev/null
fi

if [ -e '/etc/container_environment.sh' ]; then
    source /etc/container_environment.sh
fi

# Make sure that all the directories in $HOME are accessible by the user.
if [ -n "$HOST_UID" -a "$DOCKER_UID" != "$HOST_UID" -o \
    -n "$HOST_GID" -a "$DOCKER_GID" != "$HOST_GID" ]; then
    find $DOCKER_HOME -maxdepth 1 -type d -not -path "./shared" | sed "1d" | \
        xargs chown $DOCKER_USER:$DOCKER_GROUP 2> /dev/null || true

    # It is important for $HOME/.ssh to have correct ownership
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME/.ssh
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME/.config
elif [ -d $DOCKER_HOME/project ]; then
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME/project
fi
