#!/bin/bash
[ -f .env ]  && source .env
TARGET=${1:-build/}

echo "Building to $TARGET..."

# Copy static resources
cp favicon.ico $TARGET/

# Copy libs
mkdir $TARGET/lib
cp -r lib/{jquery.min.js,bootstrap/bootstrap.min.js} $TARGET/lib
cp -r lib/bootstrap/img $TARGET
cat lib/bootstrap/css/{united,bootstrap-responsive}.min.css > $TARGET/lib/bootstrap.css

# Compile HTML files
read -d '' LOCALS <<JSON
  {
    "order_server": "${ORDER_SERVER:-https://www.btproof.com/}",
    "contact": "${CONTACT:-hello@btproof.com}"
  }
JSON

echo "Building HTML with locals: $LOCALS"
jade --obj "$LOCALS" --out "$TARGET" views/{index,technical}.jade

# Compile JavaScript
echo "Building JavaScript..."
coffee -cp script/timestamp.coffee > /tmp/.btproof-timestamp.js
uglifyjs \
  lib/jsbn.js lib/crypto-js/{core,lib-typedarrays,sha256,ripemd160}.js lib/bitcoin/base58.js \
  /tmp/.btproof-timestamp.js \
  | uglifyjs -m \
  > $TARGET/timestamp.js
rm /tmp/.btproof-timestamp.js

coffee -cp script/order.coffee | uglifyjs -m > $TARGET/order.js

# Compile CSS
echo "Building Stylus..."
stylus < style.styl > $TARGET/style.css

