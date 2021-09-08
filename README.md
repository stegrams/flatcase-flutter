# Flatcase Flutter

A Flutter Development environment living in a [VSCode Remote Container][vscrc], that supports Android Virtual Devices (AVD's) and USB debugging.

## Goals

1. *Purity*: A fully functional development environment without impacting your local setup. 
2. *Cacheability*: Change and rebuild the environment without waiting to download and install again every package.

## System requirements
Target systems should have enough RAM and CPU power to build a Flutter mobile project.

Flatcase Flutter is currently tested only on an Ubuntu 20.04.3 LTS Dell laptop with 16 GB RAM and 1.8 up to 4.6 GHz 4 Cores 8 Threads CPU.

Target systems should also support KVM. Check your system by applying:
```
$ sudo apt install -y cpu-checker && kvm-ok
```
This should result:
```
Reading package lists... Done
Building dependency tree       
Reading state information... Done
... more installation messages here ...
...
INFO: /dev/kvm exists
KVM acceleration can be used
```

## Components
Flatcase Flutter basically consist of three files:

1. #### The Dockerfile:
   This will create the docker image that contains only package requirements, installed with ```apt-get```, and environment variable definitions like ```$PATH```.
2. #### The cached-setup script file:
   The interesting part of the setup is here. This script manages the new [named volume][nvolumes] created by ```devcontainer.json``` (see next). Actually it downloads, extracts and saves the main packages (Java, Android SDK and Flutter), when necessary, and runs some checks to ensure everything is up-to-date. Note that it doesn't install anything with ```apt-get```, it only saves to the right paths defined by the Dockerfile environment variables.
3. #### The devcontainer.json
   Automates the job of passing arguments, building the Docker image and running the container, creating and mounting the named volume, and then executing the ```cached-setup.sh``` from inside the running container. ```devcontainer.json``` is the file the VSCode Remote Containers expect to see. 

Please don't hesitate to read the content of these files. They contain useful comments to give you an insight of the whole process.

## Getting Started

1. Install, if not already there, the [Visual Studio Code][vsc]
2. Install the [Docker][docker]
3. Open VSCode and with [Ctr+Shift+X] open the extensions side panel. Search for the term ```remote containers``` and install [this extension][vscrc].
4. Clone or download this repository and copy the hidden folder ```.devcontainer``` to the root of your Flutter project or to an empty folder. You should be able to see hidden folders, or else consult your system's manual.
5. From inside VSCode, open the folder where the ```.devcontainer``` is located.

If a notification to [Reopen in Container] is not show up, then click to the leftmost side of the VSCode status bar, where a green icon with two arrows is located.

The first time you open in remote container, the process will take some time to complete. In my system, with a download speed of 5 Mbps, took about one hour and a half to connect and about 15 minutes for the first debug [F5] due to a [Flutter issue that downloads an older version of build tools][issue] but uses the latest available.
After that, the container reopens instantly when you start VSCode, and the Rebuild Container process takes only 21 sec if no new downloads are necessary, and about 40 sec to show up the emulator window with the project's main screen open.

In case you placed the ```.devcontainer``` to an empty folder, Flatcase Flutter will create a sample project for you, to give you the opportunity to test your new environment.

## Troubleshooting
1. #### Q: I see some "Warning: Mapping new ns ..." when the debugger launches the emulator. What to do?
    A: Ignore them. I haven't encountered yet any real problem coming out of these warnings.
2. #### Q: There are some "Shader compilation" errors on debug console that wasn't there the first time the debugger launched the emulator. Should I be concerned?
    A: No. But if you want to get rid of them, just uninstall your app from the emulator after stopping the debugger.

That's all! Happy coding folks!

[vscrc]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[vsc]: https://code.visualstudio.com/download
[docker]: https://docs.docker.com/get-docker/
[issue]: https://github.com/flutter/flutter/issues/83573
[nvolumes]: https://spin.atomicobject.com/2019/07/11/docker-volumes-explained/