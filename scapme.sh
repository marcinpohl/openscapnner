#!/bin/bash
set -xeufo pipefail

function get_last_tag() {
local remote="$1"
git ls-remote --tags --exit-code --refs "$remote" \
  | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' \
  | tail -n1
}

function scan_rhel6() {
git clone --depth 1 -bv4.0 https://developer.nasa.gov/ASCS/red_hat_enterprise_linux_6.git rhel6
pushd rhel6
oscap xccdf eval --profile xccdf_gov.nasa_profile_common_required --tailoring-file tailoring-xccdf.xml /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml
}

function scan_rhel7() {
### TODO bake in https://www.redhat.com/security/data/oval/com.redhat.rhsa-RHEL7.xml.bz2, try to use it if download fails
rpm -q openscap-scanner scap-security-guide openscap || (echo 'Need to install openscap openscap-scanner scap-security-guide'; exit 1)

REPO_DIR=rhel7
REPO='https://developer.nasa.gov/ASCS/red_hat_enterprise_linux_7.git'
LAST_TAG=$(get_last_tag "${REPO}")
rm -fr -- "${REPO_DIR}"
git clone --quiet --branch "$LAST_TAG" --depth 1 "${REPO}" "$REPO_DIR" 2>/dev/null
pushd rhel7
oscap xccdf eval \
    --fetch-remote-resources \
    --profile xccdf_gov.nasa_profile_common_required \
    --tailoring-file tailoring-xccdf.xml \
    /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml
}

function scan_rhel8() {
git clone --depth 1 https://developer.nasa.gov/ASCS/red_hat_enterprise_linux_8 rhel8
pushd rhel8
oscap xccdf eval --profile xccdf_gov.nasa_profile_common_required --tailoring-file tailoring-xccdf.xml /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml
}

scan_rhel7
