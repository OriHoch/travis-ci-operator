# Travis CI Operator

Automate setup and usage of Travis CI in combination with Docker and GitHub

## Quickstart

Follow the quickstart guide to get start quickly:

[QUICKSTART.md](QUICKSTART.md)


## Additional Documentation

### Updating yaml files in GitHub repos

The following command will update yaml file `test.yaml` in self repo's master branch with the given commit message

```
- travis_ci_operator.sh github-yaml-update self master test.yaml '{"foo":"bar"}' "testing github yaml update"
```

The following command will update yaml file `test.yaml` in github-yaml-updater repo

```
script:
- travis_ci_operator.sh github-update github-yaml-updater master "echo foo > bar; git add bar" "testing travis-ci-operator" OriHoch/github-yaml-updater
```
