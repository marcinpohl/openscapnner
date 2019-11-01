#!/bin/bash
set -eufo pipefail
umask 0077
BASEDIR=$( cd -P $( dirname "$0" ) && pwd )
cd "${BASEDIR}" || exit

SCAP_RESULT="${BASEDIR}/SCAPresult.xml"
SCAP_REPORT="${BASEDIR}/SCAPreport.html"

                                                                                                                                                              shopt -s extglob
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
rpm -q openscap-scanner scap-security-guide openscap > /dev/null 2>&1 \
    || $(echo 'Need to install openscap openscap-scanner scap-security-guide'; exit 1)

REPO_DIR="${BASEDIR}/rhel7"
REPO='https://developer.nasa.gov/ASCS/red_hat_enterprise_linux_7.git'
LAST_TAG=$(get_last_tag "${REPO}")

rm -fr -- "${REPO_DIR}"
git clone --quiet --branch "$LAST_TAG" --depth 1 "${REPO}" "$REPO_DIR" 2>/dev/null
pushd rhel7 > /dev/null 2>&1
oscap xccdf eval \
    --fetch-remote-resources \
    --profile xccdf_gov.nasa_profile_common_required \
    --tailoring-file tailoring-xccdf.xml \
    --results "${SCAP_RESULT}" \
    --report "${SCAP_REPORT}" \
    --check-engine-results \
    /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml || true
popd > /dev/null 2>&1 || true
}


function scan_rhel8() {
    git clone --depth 1 https://developer.nasa.gov/ASCS/red_hat_enterprise_linux_8 rhel8
    pushd rhel8
    oscap xccdf eval --profile xccdf_gov.nasa_profile_common_required --tailoring-file tailoring-xccdf.xml /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml
}

### Real Code starts here
grep -E -q 'release 6' /etc/redhat-release && scan_rhel6
grep -E -q 'release 7' /etc/redhat-release && scan_rhel7
echo
echo "Scan results/reports are in ${SCAP_RESULT} and ${SCAP_REPORT}"
echo 'Please remove results and report files from this computer,'
echo 'you do not want sensitive/vuln info laying around.'
