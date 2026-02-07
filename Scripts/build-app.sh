#!/usr/bin/env bash
#
# build-app.sh
#
# Builds the Hieroglyphs app using Swift Package Manager.
# This script provides a simple command-line interface to build the release
# configuration of the app.
#
# Usage:
#   ./Scripts/build-app.sh
#

set -e

swift build -c release
