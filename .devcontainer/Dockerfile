FROM ubuntu:20.04

# A note about ARGs ENVs
# These two entities have no differences in Dockerfile but:
# 1 Build time (devcontainer.json "build") has only access to ARGs.
# 2 Run time (cashed-setup.sh) has only access to ENVs.
# Also RUN commands that read environment variables have only access
# to ENVs as well.

# install all dependencies
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
     git sudo \
     #
     # openjdk https://github.com/docker-library/openjdk/blob/master/8/jdk/buster/Dockerfile
     bzip2 unzip xz-utils fontconfig libfreetype6 wget \
     ca-certificates p11-kit gpg gpgconf \
     # gpg dependencies
     gpg-agent dirmngr \
     #
     # flutter https://flutter.dev/docs/get-started/install/linux
     bash curl file git unzip xz-utils zip libglu1-mesa \
     clang cmake ninja-build pkg-config libgtk-3-dev \
     #
     # Android emulator cannot open without these three.
     libpulse0 libnss3 libasound2 \
     #
     # dart https://dart.dev/get-dart
     apt-transport-https \
     #
     # Tools used in cashed-setup.sh for convenience
     bash-completion gettext \ 
  && rm -rf /var/lib/{apt,dpkg,cache,log}

# Copying the kvm group id of the host was the only way I could find 
# to sync host's and image's kvm group id, before the containers creation.
# I also tried to create or change gid of kvm on container's run time,
# from within cashed-setup.sh, but that required to restart the container 
# in order for the remote shell to be aware of the changes. 
COPY kvm_gid /

# create user
ARG USER=pick-a-user-name-on-devcontainer-json
RUN useradd -s /bin/bash -m $USER \
  && echo $USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER \
  && chmod 0440 /etc/sudoers.d/$USER \
  # Create a kvm group and join the user. 
  # It's an android sdk prerequisite for user to have access
  # rights on mounted /dev/kvm in order to launch the emulator.
  && groupadd --system kvm --gid $(cat /kvm_gid) && rm /kvm_gid \
  && echo "KERNEL==\"kvm\", GROUP=\"kvm\", MODE=\"0660\"" >> /lib/udev/rules.d/50-udev-default.rules \
  && usermod --append --groups kvm $USER

# Any file or folder is desirable to be on image user's home folder
# may be placed on .devcontainer/user_home.
COPY --chown=$USER:$USER user_home/ /home/$USER

USER $USER
ENV USER $USER
WORKDIR /home/$USER

# downloads cache volume
ARG FLATCACHE=/home/$USER/.flatcache
RUN mkdir -p "$FLATCACHE"
VOLUME $FLATCACHE

## java
# source: https://github.com/docker-library/openjdk/blob/master/8/jdk/buster/Dockerfile
ENV JAVA_VERSION "8u302"
ARG JAVA_BASE=$FLATCACHE/java
ENV JAVA_HOME $JAVA_BASE/openjdk-8
ENV JAVA_CACHE $JAVA_BASE/cache
ENV JAVA_REPO "https://github.com/AdoptOpenJDK/openjdk8-upstream-binaries/releases/download/jdk8u302-b08/OpenJDK8U-jdk_x64_linux_8u302b08.tar.gz"
ENV PATH "$JAVA_HOME/bin:$PATH"

## gradle build artifacts that need downloading on every image rebuild
ENV GRADLE_USER_HOME $FLATCACHE/gradle

## android
ENV ANDROID_VERSION "30"
ENV ANDROID_BUILD_TOOLS_VERSION $ANDROID_VERSION.0.3
ARG ANDROID_BASE=$FLATCACHE/android
ENV ANDROID_SDK_ROOT $ANDROID_BASE/sdk
ENV ANDROID_HOME $ANDROID_SDK_ROOT
ENV ANDROID_PREFS_ROOT $ANDROID_BASE/config
ENV ANDROID_SDK_HOME $ANDROID_PREFS_ROOT
ENV ANDROID_EMULATOR_HOME $ANDROID_PREFS_ROOT/.android
ENV ANDROID_CACHE $ANDROID_BASE/cache
ENV ANDROID_REPO "https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip"
ENV ANDROID_ARCHITECTURE x86_64
ENV PATH "$ANDROID_SDK_ROOT/cmdline-tools/tools/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/platforms:$PATH"

# dart 
ENV DART_VERSION "2.13.4"
ENV DART_CHANNEL stable
ARG DART_BASE=$FLATCACHE/dart
ENV DART_SDK_ROOT $DART_BASE/sdk
ENV DART_CACHE $DART_BASE/cache
ENV PUB_CACHE $DART_BASE/pub_cache
ENV DART_REPO "https://storage.googleapis.com/dart-archive/channels/${DART_CHANNEL}/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip"
ENV PATH "$DART_SDK_ROOT/bin:$PUB_CACHE/bin:$PATH"

# flutter version manager FVM
ARG FLUTTER_VERSION="2.2.0"
ENV FLUTTER_VERSION $FLUTTER_VERSION
ENV FVM_HOME $FLATCACHE/flutter
ENV PATH "$FVM_HOME/default/bin:$PATH"

# preserve bash history after rebuild. Command liners approve :+1:
ENV HISTFILE $FLATCACHE/bash_history