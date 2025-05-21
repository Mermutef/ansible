#!/bin/bash
set -euo pipefail

RELEASE_VERSION=3.5.2

curl -fLOOO "https://github.com/woodpecker-ci/woodpecker/releases/download/v$RELEASE_VERSION/woodpecker-{server,agent,cli}-$RELEASE_VERSION.x86_64.rpm"

apt-get --fix-broken install ./woodpecker-{server,agent,cli}-$RELEASE_VERSION.x86_64.rpm
