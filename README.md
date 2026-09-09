# actions-rpmlint

Run rpmlint in GitHub Actions. When rpmlint fails during a pull request
workflow, the action posts the rpmlint output as a pull request comment and
then fails the step.

```yaml
permissions:
  contents: read
  issues: write

steps:
  - uses: actions/checkout@v4
  - uses: shogo82148/actions-rpmlint@v0
    with:
      rpmlint_flags: "path/to/*.spec"
```

`issues: write` is required because pull request conversation comments use the
Issues API. GitHub gives read-only tokens to workflows triggered by pull
requests from forks, so comments cannot be posted for those runs unless the
repository uses another trusted workflow design. The rpmlint result is still
reported in the job log in that case.

## Inputs

- `github_token`: token used to post the pull request comment. Defaults to
  `github.token`.
- `rpmlint_flags`: arguments passed to rpmlint.
