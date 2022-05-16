#!/usr/bin/env python3

"""
Launch a Docker image with Ubuntu and LXDE window manager, and
automatically open up the URL in the default web browser.
It also sets up port forwarding for ssh.
"""

# Author: Xiangmin Jiao <xmjiao@gmail.com>

import sys
import subprocess
import time
import os

owner = "x11vnc"
proj = os.path.basename(sys.argv[0]).split('_')[0]
image = owner + "/docker-desktop"
tag = "latest"
projdir = "project"
workdir = "project"
volume = proj + "_project"


def parse_args(description):
    "Parse command-line arguments"

    import argparse

    # Process command-line arguments
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument('-i', '--image',
                        help='The Docker image to use. ' +
                        'The default is ' + image + '.',
                        default=image)

    parser.add_argument('-t', '--tag',
                        help='Tag of the image. The default is latest. ' +
                        'If the image already has a tag, its tag prevails.',
                        default=tag)

    parser.add_argument('-v', '--volume',
                        help='A data volume to be mounted at ~/" + projdir + ". ' +
                        'The default is ' + volume + '.',
                        default=volume)

    parser.add_argument('-w', '--workdir',
                        help='The starting work directory in container. ' +
                        'The default is ~/' + workdir + '.',
                        default=workdir)

    parser.add_argument('-p', '--pull',
                        help='Pull the latest Docker image. ' +
                        'The default is not to pull.',
                        action='store_true',
                        default=False)

    parser.add_argument('-r', '--reset',
                        help='Reset configurations to default.',
                        action='store_true',
                        default=False)

    parser.add_argument('-c', '--clear',
                        help='Clear the project data volume (please use with care).',
                        action='store_true',
                        default=False)

    parser.add_argument('-d', '--detach',
                        help='Run in background and print the container id.',
                        action='store_true',
                        default=False)

    parser.add_argument('-s', '--size',
                        help='The screen size, such as 1440x900, 1920x1080, 2560x1600, etc. ' +
                        'The default is to use the current screen size or 1920x1080.',
                        default="")

    parser.add_argument('-n', '--no-browser',
                        help='Do not start web browser. It is false by default, unless ' +
                        'the current screen size cannot be determined automatically.',
                        action='store_true',
                        default=False)

    parser.add_argument('--password',                        
                        help='Specify a password for VNC instead of generating a random one. ' +
                        'You can also set a password using the VNCPASS environment variable.',
                        default="")

    parser.add_argument('-N', '--nvidia',
                        help='Mount the Nvidia card for GPU computation. ' +
                        '(Linux only, experimental, sudo required).',
                        action='store_true',
                        default="")

    parser.add_argument('-V', '--verbose',
                        help='Enable verbose mode and print debug info to stderr.',
                        action='store_true',
                        default=False)

    parser.add_argument('-q', '--quiet',
                        help='Disable screen output (some Docker output cannot be disabled).',
                        action='store_true',
                        default=False)

    parser.add_argument('-A', '--args',
                        help='Additional arguments for the "docker run" command. ' +
                        'Useful for specifying additional resources or environment variables.',
                        default="")

    args = parser.parse_args()
    # Append tag to image if the image has no tag
    if args.image.find(':') < 0:
        if not args.tag:
            pass
        else:
            args.image += ':' + args.tag
    if args.password == '':
        args.password = os.getenv('VNCPASS', '')

    return args


def random_ports(port, n):
    """Generate a list of n random ports near the given port.

    The first 5 ports will be sequential, and the remaining n-5 will be
    randomly selected in the range [port-2*n, port+2*n].
    """
    import random

    for i in range(min(5, n)):
        yield port + i
    for i in range(n - 5):
        yield max(1, port + random.randint(-2 * n, 2 * n))


def id_generator(size=6):
    """Generate a container ID"""
    import random
    import string

    chars = string.ascii_lowercase
    return proj + "-" + (''.join(random.choice(chars) for _ in range(size)))


def find_free_port(port, retries):
    "Find a free port"
    import socket

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    for prt in random_ports(port, retries + 1):
        try:
            sock.bind(("127.0.0.1", prt))
            sock.close()
            return prt
        except socket.error:
            continue

    return ''


def wait_net_service(port, timeout=30):
    """ Wait for network service to appear.
    """
    import socket

    for _ in range(timeout * 10):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect(("127.0.0.1", port))
        except socket.error:
            sock.close()
            time.sleep(0.1)
            continue
        else:
            sock.close()
            time.sleep(3)
            return True


def get_screen_resolution():
    """Obtain the local screen resolution."""

    try:
        if sys.version_info.major > 2:
            import tkinter as tk
        else:
            import Tkinter as tk

        root = tk.Tk()
        root.withdraw()
        width, height = root.winfo_screenwidth(), root.winfo_screenheight()

        return str(width) + 'x' + str(height)
    except BaseException:
        return ""


def handle_interrupt(container):
    """Handle keyboard interrupt"""
    try:
        print("Press Ctrl-C again to terminate the container: ")
        time.sleep(5)
        print('Invalid response. Resuming...')
    except KeyboardInterrupt:
        print('*** Stopping the container ' + container)
        if platform.system() == "Windows":
            subprocess.check_output(["docker", "stop", container])
        else:
            subprocess.Popen(["docker", "exec", container,
                              "killall", "my_init"],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        sys.exit(0)


if __name__ == "__main__":
    import webbrowser
    import platform
    import glob

    args = parse_args(description=__doc__)
    config = proj + '_' + args.tag + '_config'

    if args.quiet:
        def print(*args, **kwargs):
            "Do nothing"
            pass

        def stdout_write(*args, **kwargs):
            "Do nothing"
            pass

        def stderr_write(*args, **kwargs):
            "Do nothing"
            pass
    else:
        def stdout_write(*args, **kwargs):
            "Call sys.stderr.write"
            sys.stdout.write(*args, **kwargs)

        def stderr_write(*args, **kwargs):
            "Call sys.stderr.write"
            sys.stderr.write(*args, **kwargs)

    pwd = os.getcwd()
    homedir = os.path.expanduser('~')
    if platform.system() == "Linux":
        if subprocess.check_output(['groups']).find(b'docker') < 0:
            print('You are not a member of the docker group. Please add')
            print('yourself to the docker group using the following command:')
            print('   sudo addgroup $USER docker')
            print('Then, log out and log back in before you can use Docker.')
            sys.exit(-1)
        uid = str(os.getuid())
        gid = str(os.getgid())
        if uid == '0':
            print('You are running as root. This is not safe. ' +
                  'Please run as a regular user.')
            sys.exit(-1)
    else:
        uid = ""
        gid = ""

    try:
        if args.verbose:
            stdout_write("Check whether Docker is up and running.\n")
        img = subprocess.check_output(['docker', 'images', '-q', args.image])
    except BaseException:
        stderr_write("Docker failed. Please make sure docker was properly " +
                     "installed and has been started.\n")
        sys.exit(-1)

    if args.pull or not img:
        try:
            if args.verbose:
                stdout_write("Pulling latest docker image " +
                             args.image + '.\n')
            err = subprocess.call(["docker", "pull", args.image])
        except BaseException:
            err = -1

        if err:
            sys.exit(err)

        # Delete dangling image
        if img and subprocess.check_output(['docker', 'images', '-f',
                                            'dangling=true',
                                            '-q']).find(img) >= 0:
            subprocess.Popen(["docker", "rmi", "-f", img.decode('utf-8')[:-1]])

    docker_user = "ubuntu"
    docker_home = "/home/" + docker_user

    if args.reset:
        try:
            if args.verbose:
                stdout_write("Removing old docker volume " + config + ".\n")
            output = subprocess.check_output(
                ["docker", "volume", "rm", "-f", config])
        except subprocess.CalledProcessError as e:
            stderr_write(e.output.decode('utf-8'))

    volumes = ["-v", pwd + ":" + docker_home + "/shared",
               "-v", config + ":" + docker_home + "/.config"]

    if os.path.exists(homedir + "/.gnupg"):
        volumes += ["-v", homedir + "/.gnupg" +
                    ":" + docker_home + "/.gnupg"]

    # Mount .gitconfig to Docker image
    if os.path.isfile(homedir + "/.gitconfig"):
        volumes += ["-v", homedir + "/.gitconfig" +
                    ":" + docker_home + "/.gitconfig_host"]

    if args.volume:
        if args.clear:
            try:
                if args.verbose:
                    stdout_write(
                        "Removing old docker volume " + config + ".\n")
                output = subprocess.check_output(["docker", "volume",
                                                  "rm", "-f", args.volume])
            except subprocess.CalledProcessError as e:
                stderr_write(e.output.decode('utf-8'))

        volumes += ["-v", args.volume + ":" + docker_home + "/" + projdir]

    if args.workdir[0] == '/':
        volumes += ["-w", args.workdir]
    else:
        volumes += ["-w", docker_home + "/" + args.workdir]

    stderr_write("Starting up docker image...\n")
    if subprocess.check_output(["docker", "--version"]). \
            find(b"Docker version 1.") >= 0:
        rmflag = "-t"
    else:
        rmflag = "--rm"

    # Determine size of the desktop
    if not args.size:
        size = get_screen_resolution()
        if not size:
            # Set default size and disable webbrowser
            size = "1920x1080"
            args.no_browser = True
    else:
        size = args.size

    # Generate a container ID
    container = id_generator()

    envs = ["--hostname", container,
            "--env", "VNCPASS=" + args.password,
            "--env", "RESOLUT=" + size,
            "--env", "HOST_UID=" + uid,
            "--env", "HOST_GID=" + gid]

    # Find a free port for ssh tunning
    port_ssh = str(find_free_port(2222, 50))
    if not port_ssh:
        stderr_write("Error: Could not find a free port.\n")
        sys.exit(-1)
    envs += ["-p", port_ssh + ":22"]

    # Create directory .ssh if not exist
    if not os.path.exists(homedir + "/.ssh"):
        os.mkdir(homedir + "/.ssh")

    if platform.system() != 'Windows':
        volumes += ["-v", homedir + "/.ssh" + ":" + docker_home + "/.ssh"]
    else:
        # On Windows, cannot use ~/.ssh directly. Mount it into ~/.ssh-host.
        volumes += ["-v", homedir + "/.ssh" + ":" + docker_home + "/.ssh-host"]

    devices = []
    if args.nvidia:
        for d in glob.glob('/dev/nvidia*'):
            devices += ['--device', d + ':' + d]

    # Start the docker image in the background and pipe the stderr
    port_http = str(find_free_port(6080, 50))
    port_vnc = str(find_free_port(5950, 50))

    if not port_http or not port_vnc:
        stderr_write("Error: Could not find a free port.\n")
        sys.exit(-1)

    cmd = ["docker", "run", "-d", rmflag, "--name", container,
                     "--shm-size", "2g", "-p", port_http + ":6080",
                     "-p", port_vnc + ":5900"] + \
        envs + volumes + devices + args.args.split() + \
        ['--security-opt', 'seccomp=unconfined', '--cap-add=SYS_PTRACE',
         args.image, "startvnc.sh >> " +
         docker_home + "/.log/vnc.log"]

    if args.verbose:
        stdout_write(' '.join(cmd[:-1]) + ' "' + cmd[-1] + '"\n')

    subprocess.call(cmd)

    wait_for_url = True

    # Wait for user to press Ctrl-C
    while True:
        try:
            if wait_for_url:
                # Wait until the file is not empty
                while not subprocess.check_output(["docker", "exec", container,
                                                   "cat", docker_home +
                                                   "/.log/vnc.log"]):
                    time.sleep(1)

                p = subprocess.Popen(["docker", "exec", container,
                                      "tail", "-F",
                                      docker_home + "/.log/vnc.log"],
                                     stdout=subprocess.PIPE,
                                     stderr=subprocess.PIPE,
                                     universal_newlines=True)

                # Monitor the stdout to extract the URL
                for stdout_line in iter(p.stdout.readline, ""):
                    ind = stdout_line.find("http://localhost:")

                    if ind >= 0:
                        # Open browser if found URL
                        url = stdout_line.replace(":6080/",
                                                  ':' + port_http + "/")
                        stdout_write(url)

                        passwd = stdout_line[url.find('password=') + 9:]
                        stdout_write("\nFor a better experience, use VNC Viewer (" +
                                     'http://realvnc.com/download/viewer)\n' +
                                     "to connect to localhost:%s with password %s\n" %
                                     (port_vnc, passwd))

                        if platform.system() == 'Windows':
                            # Copy ssh config files
                            subprocess.check_output(["docker", "exec", container,
                                    "rsync", "-rog", "--chown=ubuntu:ubuntu", "--chmod=600",
                                    "/home/ubuntu/.ssh-host/", "/home/ubuntu/.ssh/"])

                        stdout_write("You can also log into the container using the command\n    ssh -X -p " + port_ssh + " " +
                                     docker_user + "@localhost -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no\n" +
                                     "with an authorized key in " +
                                     homedir + "/.ssh/authorized_keys.\n")

                        if not args.no_browser:
                            wait_net_service(int(port_http))
                            webbrowser.open(url[ind:-1])

                        p.stdout.close()
                        p.terminate()
                        wait_for_url = False
                        break
                    else:
                        stdout_write(stdout_line)

            if args.detach:
                print('Started container ' + container + ' in background.')
                print('To terminate it, use "docker stop ' + container + '".')
                sys.exit(0)

            print("Press Ctrl-C to terminate the container.")
            # Wait until the container exits or Ctlr-C is pressed
            subprocess.run(["docker", "exec", container,
                            "tail", "-f", "-n", "0", docker_home + "/.log/vnc.log"])
            sys.exit(0)

        except subprocess.CalledProcessError:
            try:
                # If Docker process no long exists, exit
                if args.verbose:
                    stdout_write(
                        "Check whether the docker container is running.\n")
                if not subprocess.check_output(['docker', 'ps',
                                                '-q', '-f',
                                                'name=' + container]):
                    stdout_write('Docker container ' +
                                 container + ' is no longer running\n')
                    sys.exit(-1)
                else:
                    time.sleep(1)
                    continue
            except subprocess.CalledProcessError:
                stderr_write('Docker container ' +
                             container + ' is no longer running\n')
                sys.exit(-1)
            except KeyboardInterrupt:
                handle_interrupt(container)

            continue
        except KeyboardInterrupt:
            handle_interrupt(container)
        except OSError:
            sys.exit(-1)
