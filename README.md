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

In case you placed the ```.devcontainer``` to an empty folder, Flatcase Flutter will create a sample project for you, to give you the chance to test your new environment.

## Initial times (see the next table for a sum up)
When you first open in remote container, the process will take some time to complete. In my system, with a download speed of 5 Mbps, took about one hour and a half to connect and about 24 minutes for the first debug [F5] due to assembling Gradle stuff (9 mins) and a [Flutter issue that downloads an older version of build tools][issue] (15 mins) but uses the latest available.
After that, container and emulator reopen almost instantly when you start VSCode, and when rebuilding, container takes only 21 sec to open if no new downloads are necessary, and emulator takes about 1 min 17 sec to show up with the project's main screen open.

### Initial times sum up 
 When \\\\ To       | Start Container | Debug Project |
:---------          |   :--------:    |  :---------:  |
**First Building**  |   1h 30' 00''   |  0h 24' 00''  |
**Starting VSCode** |   0h 00' 10''   |  0h 00' 32''  |
**Rebuilding**      |   0h 00' 21''   |  0h 01' 17''  |

## Target devices
Running and debugging a project, needs a connection with a software (AVD or web-javascript) or hardware (usually a smartphone) device. Especially hardware devices, need to be prepared before starting the debug process. 
Generally when you start debugging, Flutter will attempt to connect with the device is reported on the rightmost label of the status bar which is usually "No device" or "Web Server (web-javascript)". To prevent that, before debugging, click on that label and from the top popped up list, make the proper choice for your needs. 
Follows a small how-to for each case of device you may use.

### Web Server (web-javascript)
Since version 2, web platform became first class citizen in Flutter's stable channel. So, if you don't have any device available, you are probably seeing the "Web Server (web-javascript) reported on the status bar. Though in order to be able to debug your project on Chrome/ium, you have first to install [dart-debug-extension][chrmext] and click on it when asked from the debugger.

### Android Virtual Device (AVD) aka emulator
Note that AVDs are not immediately reported as connected from VSCode's status bar. They should be launched first. This is done by debugging [F5] your project or clicking the "No Device" label of the status bar, and then selecting from the top popped up list one of your created emulators, or choose to create a new one which would have the default name "flutter_emulator".

### Debugging on a physical device
Prerequisite to connect with a hardware device (usually a smartphone), is that device has enabled "Developer options" (consult your device manual), and the connection's (USB debugging or Wi-Fi "Wireless debugging") switch is ON, from device's "Developer options". Note. Wireless debugging is available only for Android versions 11 and newer.

### Local adb server 
If adb is installed on your local host, run from a local host shell ```adb kill-server```, a physical device cannot connect to two adb servers, local's and container's, at the same time. You may revoke it any time later with ```adb start-server```.

### Enabling USB Debugging.
1. Connect your phone via USB.
2. Confirm to "Allow USB debugging?" message on your phone.
3. Select from the VSCode popped up list your phone if it's not already selected.

### Enabling Wi-Fi Debugging.
This procedure consists of two parts, pair and connect:

#### Pairing part
Pairing is usually done once for each device, except if you delete
"forget" a pairing device.

##### On the phone's "Developer options".
1. Tab on the title, not the switch, of the option of "Wireless debugging"
   to open the corresponding screen.
2. Tab on the option "Pair device with pairing code" and note down the 
   6 digit "Wi-Fi pairing code", the IP address and port in the form of
   ```<ip>.<an>.<dr>.<ess>:<pairing port>```

##### On the VSCode terminal window execute:
3. ```adb pair <ip>.<an>.<dr>.<ess>:<pairing port>```
4. ```Enter pairing code: <Wi-Fi pairing code>```

#### Connecting part
5. On the phone's "Wireless debugging" screen, note down the 
   "IP address and port" in the form of ```<ip>.<an>.<dr>.<ess>:<connecting port>```.
   Note that connecting port differs from pairing port.
6. On the VSCode terminal window, execute:
      ```
      adb connect <ip>.<an>.<dr>.<ess>:<connecting port>
      ```
7. Select from the VSCode's top popped up list your phone if it's not already selected.
If everything have gone well, your device should be listed on available devices.

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
[chrmext]: https://chrome.google.com/webstore/detail/dart-debug-extension/eljbmlghnomdjgdjmbdekegdkbabckhm