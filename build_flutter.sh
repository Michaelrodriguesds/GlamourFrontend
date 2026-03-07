#!/bin/bash
set -e

echo ">>> Instalando dependências do sistema..."
apt-get update -qq
apt-get install -y curl git unzip xz-utils zip libglu1-mesa

echo ">>> Baixando Flutter ${FLUTTER_VERSION}..."
curl -o flutter.tar.xz \
  "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

tar xf flutter.tar.xz
export PATH="$PATH:$(pwd)/flutter/bin"

echo ">>> Configurando Flutter Web..."
flutter config --enable-web
flutter pub get

echo ">>> Buildando para Web..."
flutter build web --release

echo ">>> Build finalizado com sucesso!"