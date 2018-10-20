# Travis CI Operator

[![Build Status](https://travis-ci.org/OriHoch/travis-ci-operator.svg?branch=master)](https://travis-ci.org/OriHoch/travis-ci-operator)

```
      _____                         _____
      __  /_______________ ____   _____(_)________
      _  __/__  ___/_  __ `/__ | / /__  / __  ___/
      / /_  _  /    / /_/ / __ |/ / _  /  _(__  )
      \__/  /_/     \__,_/  _____/  /_/   /____/
                             _____
                      __________(_)
                      _  ___/__  /
                      / /__  _  /
                      \___/  /_/
                                       _____
 ______ ________ _____ ______________ ___  /_______ ________
 _  __ \___  __ \_  _ \__  ___/_  __ `/_  __/_  __ \__  ___/
 / /_/ /__  /_/ //  __/_  /    / /_/ / / /_  / /_/ /_  /
 \____/ _  .___/ \___/ /_/     \__,_/  \__/  \____/ /_/
        /_/
```

Automate setup and usage of Travis CI for open source projects

## Quickstart

Follow the quickstart guide to get start quickly:

[QUICKSTART.md](QUICKSTART.md)


## Additional Documentation

Documentation of additional features / use-cases not included in the quickstart

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
