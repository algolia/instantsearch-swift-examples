#!/usr/bin/env ksh

set -e

SELF_ROOT=$(cd $(dirname "$0") && pwd)
PROJECT_ROOT=$(cd "$SELF_ROOT/.." && pwd)

# Static content.
echo "Generating static documentation..."
$PROJECT_ROOT/doc/make-static-doc.js

# Reference documentation.
echo "Generating reference documentation..."
$SELF_ROOT/jazzy.sh
