#!/bin/sh

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}" || exit
fi

output_file="$(mktemp)"
trap 'rm -f "${output_file}"' EXIT HUP INT TERM

# shellcheck disable=SC2086
rpmlint ${INPUT_RPMLINT_FLAGS} >"${output_file}" 2>&1
exit_code=$?

cat "${output_file}"

if [ "${exit_code}" -ne 0 ]; then
  echo "::warning::rpmlint failed with exit code ${exit_code}."
  python3 /post-pr-comment.py "${output_file}" ||
    echo "::warning::Failed to post the rpmlint result to the pull request."
fi

# rpmlint findings are reported in the log and pull request comment, but they
# do not fail the workflow job.
exit 0
