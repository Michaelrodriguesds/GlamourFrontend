#!/bin/bash
set -e
curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -o /tmp/flutter.tar.xz
tar -xf /tmp/flutter.tar.xz -C $HOME
export PATH="$HOME/flutter/bin:$PATH"
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release