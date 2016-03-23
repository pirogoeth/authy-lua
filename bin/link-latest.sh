#!/usr/bin/env bash
# link-latest.sh
#
# reads the version from a rockspec and links the appropriate
# <name>-<version>-<revision>.rockspec

[[ -z "${ROCKSPEC}" ]] && \
    echo " [-] No ROCKSPEC envvar specified." && \
    exit 1

[[ ! -f "${ROCKSPEC}" ]] && \
    echo " [-] Invalid rockspec file path." && \
    exit 1

package_name="`cat $ROCKSPEC | grep package | tr -d '=' | awk '{print $2}' | tr -d '\"'`"
package_version="`cat $ROCKSPEC | grep version | tr -d '=' | awk '{print $2}' | tr -d '\"'`"

link_name="${package_name}-${package_version}.rockspec"

echo " [+] Linking ${link_name} -> ${ROCKSPEC}"
ln -s ${ROCKSPEC} ${link_name}

_ret=$?
if [[ ${_ret} != 0 ]] ; then
    echo " [-] Linking error! [Code: ${_ret}]"
else
    echo " [+] Success!"
fi
