#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if command -v bundle >/dev/null 2>&1; then
  bundle check >/dev/null 2>&1 || bundle install
  bundle exec fastlane stores
else
  fastlane stores
fi
