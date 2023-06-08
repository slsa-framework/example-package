#!/bin/bash

set -euo pipefail

# shellcheck source=/dev/null
source "./.github/workflows/scripts/badges/e2e-badges.sh"

e2e_update_badge_passing
