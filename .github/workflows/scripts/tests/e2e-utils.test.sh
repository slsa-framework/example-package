#!/bin/bash

source "./.github/workflows/scripts/e2e-assert.sh"

source "./.github/workflows/scripts/e2e-utils.sh"

# version_major

# no leading zeros, with minor/patch
e2e_assert_eq "$(version_major "v1.2.3")" "1" "version_major v1.2.3"
# leading zeros, with minor/patch
e2e_assert_eq "$(version_major "v0001.2.3")" "1" "version_major v0001.2.3"
# no leading zeros, without minor/patch
e2e_assert_eq "$(version_major "v1")" "1" "version_major v1"
# leading zeros, without minor/patch
e2e_assert_eq "$(version_major "v0001")" "1" "version_major v0001"
# no leading zeros, without minor/patch, with rc
e2e_assert_eq "$(version_major "v1-rc.4")" "1" "version_major v1-rc.4"
# leading zeros, without minor/patch, with rc
e2e_assert_eq "$(version_major "v0001-rc.4")" "1" "version_major v0001-rc.4"
# no major version
e2e_assert_eq "$(version_major "-rc.4")" "" "version_major -rc.4"
# empty
e2e_assert_eq "$(version_major "")" "" "version_major ''"

# version_minor

# no leading zeros, with patch
e2e_assert_eq "$(version_minor "v1.2.3")" "2" "version_minor v1.2.3"
# leading zeros, with patch
e2e_assert_eq "$(version_minor "v1.0002.3")" "2" "version_minor v1.0002.3"
# no leading zeros, without patch
e2e_assert_eq "$(version_minor "v1.2")" "2" "version_minor v1.2"
# leading zeros, without patch
e2e_assert_eq "$(version_minor "v1.0002")" "2" "version_minor v1.0002"
# no leading zeros, without patch, with rc
e2e_assert_eq "$(version_minor "v1.2-rc.4")" "2" "version_minor v1.2-rc.4"
# leading zeros, without patch, with rc
e2e_assert_eq "$(version_minor "v1.0002-rc.4")" "2" "version_minor v1.0002-rc.4"
# no minor version
e2e_assert_eq "$(version_minor "-rc.4")" "" "version_minor -rc.4"
# empty
e2e_assert_eq "$(version_minor "")" "" "version_minor ''"

# version_patch

# no leading zeros
e2e_assert_eq "$(version_patch "v1.2.3")" "3" "version_patch v1.2.3"
# leading zeros
e2e_assert_eq "$(version_patch "v1.2.0003")" "3" "version_patch v1.2.0003"
# no leading zeros, with rc
e2e_assert_eq "$(version_patch "v1.2.3-rc.4")" "3" "version_patch v1.2.3-rc.4"
# leading zeros, with rc
e2e_assert_eq "$(version_patch "v1.2.0003-rc.4")" "3" "version_patch v1.2.0003-rc.4"
# no patch version
e2e_assert_eq "$(version_patch "-rc.4")" "" "version_patch -rc.4"
# empty
e2e_assert_eq "$(version_patch "")" "" "version_patch ''"

# version_pre

# no leading zeros
e2e_assert_eq "$(version_pre "v1.2.3-rc.4")" "rc.4" "version_pre v1.2.3-rc.4"
# leading zeros
e2e_assert_eq "$(version_pre "v1.2.3-rc.0004")" "rc.0004" "version_pre v1.2.3-rc.0004"
# arbitrary
e2e_assert_eq "$(version_pre "v1.2.3-alpha")" "alpha" "version_pre v1.2.3-alpha"
# no pre
e2e_assert_eq "$(version_pre "v1.2.3")" "" "version_pre v1.2.34"
# empty
e2e_assert_eq "$(version_pre "")" "" "version_pre ''"

# version_rc

# no leading zeros
e2e_assert_eq "$(version_rc "v1.2.3-rc.4")" "4" "version_rc v1.2.3.rc.4"
# leading zeros
e2e_assert_eq "$(version_rc "v1.2.3-rc.0004")" "4" "version_rc v1.2.3-rc.0004"
# malformed rc
e2e_assert_eq "$(version_rc "v1.2.3-rc4")" "" "version_rc v1.2.3-rc4"
e2e_assert_eq "$(version_rc "v1.2.3-alpha")" "" "version_rc v1.2.3-alpha"
# no rc
e2e_assert_eq "$(version_rc "v1.2.3")" "" "version_rc v1.2.34"
# empty
e2e_assert_eq "$(version_rc "")" "" "version_rc ''"

# version_eq

e2e_assert_command_success version_eq "" ""

# no leading zeros, with minor/patch
e2e_assert_command_success version_eq "v1.2.3" "v1.2.3"
# leading zeros, with minor/patch
e2e_assert_command_success version_eq "v0001.2.3" "v1.2.3"
e2e_assert_command_success version_eq "v1.2.3" "v0001.2.3"
e2e_assert_command_success version_eq "v1.0002.3" "v1.2.3"
e2e_assert_command_success version_eq "v1.2.3" "v1.0002.3"
e2e_assert_command_success version_eq "v1.2.0003" "v1.2.3"
e2e_assert_command_success version_eq "v1.2.3" "v1.2.0003"

# no leading zeros, without minor/patch
e2e_assert_command_success version_eq "v1" "v1"
e2e_assert_command_success version_eq "v1" "v1.0.0"
e2e_assert_command_success version_eq "v1.0.0" "v1"
# leading zeros, without minor/patch
e2e_assert_command_success version_eq "v0001" "v0001"
e2e_assert_command_success version_eq "v0001.0.0" "v0001"
e2e_assert_command_success version_eq "v0001" "v0001.0.0"
e2e_assert_command_success version_eq "v1.000.0" "v1.0.0"
e2e_assert_command_success version_eq "v1.0.0" "v1.000.0"
e2e_assert_command_success version_eq "v1.0.000" "v1.0.0"
e2e_assert_command_success version_eq "v1.0.0" "v1.0.000"

# no leading zeros, without patch
e2e_assert_command_success version_eq "v1.2" "v1.2"
e2e_assert_command_success version_eq "v1.2.0" "v1.2"
e2e_assert_command_success version_eq "v1.2" "v1.2.0"
# leading zeros, without patch
e2e_assert_command_success version_eq "v0001.2" "v1.2"
e2e_assert_command_success version_eq "v1.2" "v0001.2"
e2e_assert_command_success version_eq "v0001.2" "v1.2.0"
e2e_assert_command_success version_eq "v1.2.0" "v0001.2"
e2e_assert_command_success version_eq "v1.0002" "v1.2"
e2e_assert_command_success version_eq "v1.2" "v1.0002"
e2e_assert_command_success version_eq "v1.0002" "v1.2.0"
e2e_assert_command_success version_eq "v1.2.0" "v1.0002"

# with rc
e2e_assert_command_success version_eq "v1.2.3-rc.4" "v1.2.3-rc.4"
e2e_assert_command_success version_eq "v1.2.3-rc.0004" "v1.2.3-rc.4"
e2e_assert_command_success version_eq "v1.2.3-rc.4" "v1.2.3-rc.0004"

e2e_assert_command_failure version_eq "v1.2.3" "v1.2.3-rc.4"
e2e_assert_command_failure version_eq "v1.2.3-rc.4" "v1.2.3"
e2e_assert_command_failure version_eq "v1.2.3" "v1.2.3-alpha"
e2e_assert_command_failure version_eq "v1.2.3-alpha" "v1.2.3"

# different pre
e2e_assert_command_failure version_eq "v1.2.3-alpha" "v1.2.3-beta"
e2e_assert_command_failure version_eq "v1.2.3-beta" "v1.2.3-alpha"

# version_gt

# equal
e2e_assert_command_failure version_gt "v1.2.3" "v1.2.3"
e2e_assert_command_failure version_gt "v1.0" "v1"
e2e_assert_command_failure version_gt "v1" "v1.0"
e2e_assert_command_failure version_gt "v1.0.0" "v1"
e2e_assert_command_failure version_gt "v1" "v1.0.0"
e2e_assert_command_failure version_gt "v1.2.3-rc.4" "v1.2.3-rc.4"
e2e_assert_command_failure version_gt "v1.2.3-rc.04" "v1.2.3-rc.4"
e2e_assert_command_failure version_gt "v1.2.3-rc.4" "v1.2.3-rc.04"

# major
e2e_assert_command_success version_gt "v2.2.3" "v1.2.3"
e2e_assert_command_failure version_gt "v1.2.3" "v2.2.3"

# minor
e2e_assert_command_success version_gt "v1.3.3" "v1.2.3"
e2e_assert_command_failure version_gt "v1.2.3" "v1.3.3"

# patch
e2e_assert_command_success version_gt "v1.2.4" "v1.2.3"
e2e_assert_command_failure version_gt "v1.2.3" "v1.2.4"

# rc
e2e_assert_command_success version_gt "v1.2.3-rc.5" "v1.2.3-rc.4"
e2e_assert_command_failure version_gt "v1.2.3-rc.4" "v1.2.3-rc.5"
e2e_assert_command_success version_gt "v1.2.3" "v1.2.3-rc.4"
e2e_assert_command_failure version_gt "v1.2.3-rc.4" "v1.2.3"

# rc & pre
e2e_assert_command_success version_gt "v1.2.3-rc.4" "v1.2.3-alpha"
e2e_assert_command_failure version_gt "v1.2.3-alpha" "v1.2.3-rc.4"

# pre
e2e_assert_command_success version_gt "v1.2.3-beta" "v1.2.3-alpha"
e2e_assert_command_failure version_gt "v1.2.3-alpha" "v1.2.3-beta"

# version_gte

# equal
e2e_assert_command_success version_ge "v1.2.3" "v1.2.3"
e2e_assert_command_success version_ge "v1.0" "v1"
e2e_assert_command_success version_ge "v1" "v1.0"
e2e_assert_command_success version_ge "v1.0.0" "v1"
e2e_assert_command_success version_ge "v1" "v1.0.0"
e2e_assert_command_success version_ge "v1.2.3-rc.4" "v1.2.3-rc.4"
e2e_assert_command_success version_ge "v1.2.3-rc.04" "v1.2.3-rc.4"
e2e_assert_command_success version_ge "v1.2.3-rc.4" "v1.2.3-rc.04"

# major
e2e_assert_command_success version_ge "v2.2.3" "v1.2.3"
e2e_assert_command_failure version_ge "v1.2.3" "v2.2.3"

# minor
e2e_assert_command_success version_ge "v1.3.3" "v1.2.3"
e2e_assert_command_failure version_ge "v1.2.3" "v1.3.3"

# patch
e2e_assert_command_success version_ge "v1.2.4" "v1.2.3"
e2e_assert_command_failure version_ge "v1.2.3" "v1.2.4"

# rc
e2e_assert_command_success version_ge "v1.2.3-rc.5" "v1.2.3-rc.4"
e2e_assert_command_failure version_ge "v1.2.3-rc.4" "v1.2.3-rc.5"
e2e_assert_command_success version_ge "v1.2.3" "v1.2.3-rc.4"
e2e_assert_command_failure version_ge "v1.2.3-rc.4" "v1.2.3"

# rc & pre
e2e_assert_command_success version_ge "v1.2.3-rc.4" "v1.2.3-alpha"
e2e_assert_command_failure version_ge "v1.2.3-alpha" "v1.2.3-rc.4"

# pre
e2e_assert_command_success version_ge "v1.2.3-beta" "v1.2.3-alpha"
e2e_assert_command_failure version_ge "v1.2.3-alpha" "v1.2.3-beta"

# version_lt

# equal
e2e_assert_command_failure version_lt "v1.2.3" "v1.2.3"
e2e_assert_command_failure version_lt "v1.0" "v1"
e2e_assert_command_failure version_lt "v1" "v1.0"
e2e_assert_command_failure version_lt "v1.0.0" "v1"
e2e_assert_command_failure version_lt "v1" "v1.0.0"
e2e_assert_command_failure version_lt "v1.2.3-rc.4" "v1.2.3-rc.4"
e2e_assert_command_failure version_lt "v1.2.3-rc.04" "v1.2.3-rc.4"
e2e_assert_command_failure version_lt "v1.2.3-rc.4" "v1.2.3-rc.04"

# major
e2e_assert_command_success version_lt "v1.2.3" "v2.2.3"
e2e_assert_command_failure version_lt "v2.2.3" "v1.2.3"

# minor
e2e_assert_command_success version_lt "v1.2.3" "v1.3.3"
e2e_assert_command_failure version_lt "v1.3.3" "v1.2.3"

# patch
e2e_assert_command_success version_lt "v1.2.3" "v1.2.4"
e2e_assert_command_failure version_lt "v1.2.4" "v1.2.3"

# rc
e2e_assert_command_success version_lt "v1.2.3-rc.4" "v1.2.3-rc.5"
e2e_assert_command_failure version_lt "v1.2.3-rc.5" "v1.2.3-rc.4"
e2e_assert_command_success version_lt "v1.2.3-rc.4" "v1.2.3"
e2e_assert_command_failure version_lt "v1.2.3" "v1.2.3-rc.4"

# rc & pre
e2e_assert_command_success version_lt "v1.2.3-alpha" "v1.2.3-rc.4"
e2e_assert_command_failure version_lt "v1.2.3-rc.4" "v1.2.3-alpha"

# pre
e2e_assert_command_success version_lt "v1.2.3-alpha" "v1.2.3-beta"
e2e_assert_command_failure version_lt "v1.2.3-beta" "v1.2.3-alpha"

# version_le

# equal
e2e_assert_command_success version_le "v1.2.3" "v1.2.3"
e2e_assert_command_success version_le "v1.0" "v1"
e2e_assert_command_success version_le "v1" "v1.0"
e2e_assert_command_success version_le "v1.0.0" "v1"
e2e_assert_command_success version_le "v1" "v1.0.0"
e2e_assert_command_success version_le "v1.2.3-rc.4" "v1.2.3-rc.4"
e2e_assert_command_success version_le "v1.2.3-rc.04" "v1.2.3-rc.4"
e2e_assert_command_success version_le "v1.2.3-rc.4" "v1.2.3-rc.04"

# major
e2e_assert_command_success version_le "v1.2.3" "v2.2.3"
e2e_assert_command_failure version_le "v2.2.3" "v1.2.3"

# minor
e2e_assert_command_success version_le "v1.2.3" "v1.3.3"
e2e_assert_command_failure version_le "v1.3.3" "v1.2.3"

# patch
e2e_assert_command_success version_le "v1.2.3" "v1.2.4"
e2e_assert_command_failure version_le "v1.2.4" "v1.2.3"

# rc
e2e_assert_command_success version_le "v1.2.3-rc.4" "v1.2.3-rc.5"
e2e_assert_command_failure version_le "v1.2.3-rc.5" "v1.2.3-rc.4"
e2e_assert_command_success version_le "v1.2.3-rc.4" "v1.2.3"
e2e_assert_command_failure version_le "v1.2.3" "v1.2.3-rc.4"

# rc & pre
e2e_assert_command_success version_le "v1.2.3-alpha" "v1.2.3-rc.4"
e2e_assert_command_failure version_le "v1.2.3-rc.4" "v1.2.3-alpha"

# pre
e2e_assert_command_success version_le "v1.2.3-alpha" "v1.2.3-beta"
e2e_assert_command_failure version_le "v1.2.3-beta" "v1.2.3-alpha"
