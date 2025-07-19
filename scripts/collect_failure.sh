#!/bin/bash
mkdir -p artifacts
git diff > artifacts/last_diff.patch
xcrun simctl spawn booted log collect \
  --output artifacts/device.log --last 1h
xcrun simctl crash list --json > artifacts/crashes.json
