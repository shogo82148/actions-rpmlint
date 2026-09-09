#!/bin/sh

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}" || exit
fi

# shellcheck disable=SC2086
rpmlint ${INPUT_RPMLINT_FLAGS}
