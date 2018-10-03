#!/usr/bin/env bash

if [ "${1}" == "init" ]; then
    chmod +x $HOME/bin/travis_ci_operator.sh
    curl -L https://raw.githubusercontent.com/OriHoch/travis-ci-operator/master/read_yaml.py > $HOME/bin/read_yaml.py
    chmod +x $HOME/bin/read_yaml.py
    ! $(eval echo `read_yaml.py .travis-ci-operator.yaml selfDeployKeyDecryptCmd`) \
        && echo Failed to get self deploy key && exit 1
    echo Successfully initialized travis-ci-operator
    exit 0

elif [ "${1}" == "docker-login" ]; then
    ! docker login -u "${DOCKER_USER}" -p "${DOCKER_PASSWORD}" && echo failed to login to Docker && exit 1
    echo Logged in to Docker
    exit 0

else
    echo unknown command
    exit 1

fi
