#!/usr/bin/env bash

# This file runs on container, from devcontainer.json "onCreateCommand", before 
# the vscode attachment.
# 
# Q: Why on container and not on image build time, from Dockerfile?
#
# A: Because from build time, there is no access to volumes and I wanted 
# the main tool setup (Java, Android SDK, Flutter) to be cashed on a volume that
# I could modify-experiment with, without the need of downloading again all the 
# files on every rebuild.
# 
# Q: Why "onCreateCommand"?
# 
# "onCreateCommand" runs before VSCode connects on container, without the need
# of "waitFor". That allows the script to prepare the environment for the 
# VSCode extensions that depend on it.
# If the "postCreateCommand" was used instead, without a "waitFor" point at it,
# these extensions would need a container restart to be aware of the whole 
# environment setup that completed after they emerged.

# Volume location file:///var/lib/docker/volumes/flatcase-cache/_data

# Bash command note
# 
# mkdir -p (--parents) does not throw "cannot create directory File exists".
# rm -f (--force) does not throw "No such file or directory".

# kvm_gid only needed at build time to synchronize the kvm group id between
# docker image and host. 
# It's created on every connection to a container by .devcontainer.json's 
# "initializeCommand". 
rm -f .devcontainer/kvm_gid

# Evaluate env variables in settings (currently only NVM_HOME).
# Sadly this doesn't happen from VSCode per se.
settings=~/.vscode-server/data/Machine/settings.json
tmp=$(mktemp)
envsubst < $settings > $tmp && mv $tmp $settings

set -eux


# JAVA INSTALLATION

# src: https://github.com/docker-library/openjdk/blob/master/8/jdk/buster/Dockerfile
# If not exist or empty. "head -1" shortens the terminal printed output.
if [ ! -d "$JAVA_HOME" ] || [[ ! $(ls -A "$JAVA_HOME" | head -1) ]]; then
    mkdir -p "$JAVA_HOME" "$JAVA_CACHE"
    JAVA_TGZ="$JAVA_CACHE/openjdk.$JAVA_VERSION.tgz"
    if [ ! -f  "$JAVA_TGZ" ]; then
        rm --force "$JAVA_TGZ.asc"
        wget --progress=dot:giga -O "$JAVA_TGZ" "$JAVA_REPO"
        wget --progress=dot:giga -O "$JAVA_TGZ.asc" "$JAVA_REPO.sign"
    fi
	export GNUPGHOME="$(mktemp -d)"

    # pre-fetch Andrew Haley's (the OpenJDK 8 and 11 Updates OpenJDK project lead) 
    # key so we can verify that the OpenJDK key was signed by it
    # (https://github.com/docker-library/openjdk/pull/322#discussion_r286839190)
    # we pre-fetch this so that the signature it makes on the OpenJDK key can survive "import-clean" in gpg
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys EAC843EBD3EFDB98CC772FADA5CD6035332FA671
    # no-self-sigs-only: 
    # https://salsa.debian.org/debian/gnupg2/commit/c93ca04a53569916308b369c8b218dad5ae8fe07
	gpg --batch --keyserver keyserver.ubuntu.com --keyserver-options no-self-sigs-only \
        --recv-keys CA5F11C6CE22644D42C6AC4492EF8D39DC13168F
	gpg --batch --list-sigs --keyid-format 0xLONG CA5F11C6CE22644D42C6AC4492EF8D39DC13168F \
		| tee /dev/stderr \
		| grep '0xA5CD6035332FA671' \
		| grep 'Andrew Haley'
	gpg --batch --verify "$JAVA_TGZ.asc" "$JAVA_TGZ"
	gpgconf --kill all
	rm -rf "$GNUPGHOME"

	tar --extract \
		--file "$JAVA_TGZ" \
		--directory "$JAVA_HOME" \
		--strip-components 1

fi
# https://github.com/docker-library/openjdk/issues/331#issuecomment-498834472
find "$JAVA_HOME/lib" -name '*.so' -exec dirname '{}' ';' \
    | sort -u \
    | sudo tee /etc/ld.so.conf.d/docker-openjdk.conf > /dev/null
sudo ldconfig
# basic smoke test
javac -version
java -version


# ANDROID INSTALLATION

# Clear the cached sdk to build it again with the updated version of cmdline tools.
ANDROID_ZIP="$ANDROID_CACHE/$(basename $ANDROID_REPO)"
[ ! -f "$ANDROID_ZIP" -a -d "$ANDROID_SDK_ROOT" ] && rm -rf "$ANDROID_SDK_ROOT"

# NOTE! The default ANDROID_PREFS_ROOT value is not the ~/.android but the ~/
# If ANDROID_PREFS_ROOT is not created, Android SDK will revert to default.
mkdir -p "$ANDROID_CACHE" "$ANDROID_SDK_ROOT/cmdline-tools" "$ANDROID_PREFS_ROOT"

if [ ! -d "$ANDROID_SDK_ROOT/cmdline-tools/tools" ]; then
    [ ! -f "$ANDROID_ZIP" ] && wget --progress=dot:giga -O "$ANDROID_ZIP" "$ANDROID_REPO"
    unzip -qq -d "$ANDROID_CACHE" "$ANDROID_ZIP"
    mv "$ANDROID_CACHE/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/tools"
fi
# Preserve the avd auth to prevent the annoying self destroyed "Allow USB debugging?"
# message on a cached android emulator, that drops the connections as unauthorized.
# These files have been copied (see Dockerfile) from workspace's .devcontainer/user_home folder.
cp -rf ~/.android "$ANDROID_PREFS_ROOT"
# # src: https://github.com/matsp/docker-flutter
yes "y" | sdkmanager "build-tools;$ANDROID_BUILD_TOOLS_VERSION"
yes "y" | sdkmanager "platforms;android-$ANDROID_VERSION"
yes "y" | sdkmanager "platform-tools"
yes "y" | sdkmanager "emulator"
yes "y" | sdkmanager "system-images;android-$ANDROID_VERSION;google_apis_playstore;$ANDROID_ARCHITECTURE"
yes "y" | sdkmanager --licenses

## To create and launch an emulator use: 
#   avdmanager create avd --name flatcase_emu --package "system-images;android-$ANDROID_VERSION;google_apis_playstore;$ANDROID_ARCHITECTURE"
#   emulator -avd flatcase_emu
## Or, more easily with flutter
#   flutter emulators --create --name flatcase_emu
#   flutter emulators --launch flatcase (no need to write the full name)

## To delete an emulator 
#   avdmanager delete avd --name flatcase_emu
## No way AFAIK currently to delete an avd with flutter

## To list all created emulators
#   avdmanager list avd
## Or
#   flutter emulators


# DART INSTALLATION

# Clear the cached sdk to download and/or extract the updated version.
DART_ZIP="$DART_CACHE/dartsdk-$DART_CHANNEL-$DART_VERSION.zip"
[ ! -f "$DART_ZIP" -a -d "$DART_SDK_ROOT" ] && rm -rf "$DART_SDK_ROOT"

if [ ! -d "$DART_SDK_ROOT" ]; then
    mkdir -p "$DART_CACHE"
    [ ! -f "$DART_ZIP" ] && wget --progress=dot:giga -O "$DART_ZIP" "$DART_REPO"
    unzip -qq -d "$DART_CACHE" "$DART_ZIP"
    mv "$DART_CACHE/dart-sdk" "$DART_SDK_ROOT"
fi
dart --disable-analytics


# FLUTTER INSTALLATION (via FVM https://fvm.app/docs/getting_started/overview)

dart pub global activate fvm
fvm install $FLUTTER_VERSION
fvm global $FLUTTER_VERSION
# Gives bash the ability to autocomplete flutter subcommands with tab.
flutter bash-completion | sudo tee /etc/bash_completion.d/flutter > /dev/null
flutter config --no-analytics --no-enable-web

# Create a sample if no project exists or just the items of Flatcase Flutter repo.
if [ "$(ls -A)" == ".devcontainer" -o "$(ls -A | xargs)" == ".devcontainer .git LICENSE README.md" ]; then
    flutter create --project-name flatcase .
    mkdir .vscode && cp .devcontainer/vscode-launch.json .vscode/launch.json
    sed -i 's/Flutter Demo/Flatcase Demo/' lib/main.dart
fi

if [ -f pubspec.yaml ]; then
    flutter clean 
    flutter pub get
fi

# If user hasn't created any emulators yet, create one
if [ ! "$(avdmanager list avd -c)" ]; then
    flutter emulators --create --name flatcase_emu
fi
