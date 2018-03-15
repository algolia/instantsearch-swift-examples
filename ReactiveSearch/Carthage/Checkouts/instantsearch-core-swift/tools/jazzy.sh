#!/usr/bin/env ksh
# ============================================================================ #
# Jazzy wrapper
# ============================================================================ #


SELF_ROOT=$(cd $(dirname "$0") && pwd)

MODULE_ROOT=$(cd "$SELF_ROOT/.." && pwd)

POD_NAME="InstantSearch-Core-Swift"
PODSPEC_FILE="$MODULE_ROOT/$POD_NAME.podspec"

# Extract a given field from the podspec.
get_podspec_field() {
    field_name="$1"
    cat "$PODSPEC_FILE" | grep -E "\.$field_name\s*=\s*'[^']*'" | cut -d '=' -f 2 | tr -d " \t'"
}

# Jazzy fails to retrieve information from the Podspec because the offline flavor is not supported on all platforms.
github_url=$(get_podspec_field "homepage")
module_version=$(get_podspec_field "version")

cd "$MODULE_ROOT" && jazzy \
    --theme "doc/jazzy/themes/algolia" \
    --module-version=$module_version \
    --github_url=$github_url
