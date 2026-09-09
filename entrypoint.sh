#!/bin/sh

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}" || exit
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

# shellcheck disable=SC2086
rpmlint ${INPUT_RPMLINT_FLAGS}
