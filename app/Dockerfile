FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    ca-certificates \
    bash \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME \
    && cd $FLUTTER_HOME \
    && git checkout 3.41.9

# Android SDK command line tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
    && cd /tmp \
    && wget -O cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip \
    && unzip cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
    && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
    && rm cmdline-tools.zip

# Install Android SDK packages
RUN yes | sdkmanager --licenses
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0"

RUN flutter config --no-analytics
RUN flutter doctor

WORKDIR /app

CMD ["bash", "-c", "flutter pub get && flutter build apk --release --no-tree-shake-icons"]