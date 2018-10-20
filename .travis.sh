#!/usr/bin/env bash

DOCKER_IMAGE=uumpa/travis-ci-operator

if [ "${1}" == "install" ]; then
    cp ./travis_ci_operator.sh $HOME/bin/travis_ci_operator.sh &&\
    bash $HOME/bin/travis_ci_operator.sh init &&\
    travis_ci_operator.sh docker-login &&\
    exit 0

elif [ "${1}" == "script" ]; then
    docker build -t ${DOCKER_IMAGE}:latest . &&\
    travis_ci_operator.sh github-update self master "echo foo2 > bar; git add bar" "testing github self update" &&\
    travis_ci_operator.sh github-update github-yaml-updater master "echo foo2 > bar; git add bar" "testing travis-ci-operator" OriHoch/github-yaml-updater &&\
    travis_ci_operator.sh github-yaml-update self master test.yaml '{"foo2":"bar"}' "testing github yaml update" &&\
    travis_ci_operator.sh github-yaml-update github-yaml-updater master test.yaml '{"foo2":"bar"}' "testing travis-ci-operator github yaml update" OriHoch/github-yaml-updater &&\
    travis_ci_operator.sh github-update self master "git rm bar test.yaml" "testing github self update" &&\
    travis_ci_operator.sh github-update github-yaml-updater master "git rm bar test.yaml" "testing travis-ci-operator" OriHoch/github-yaml-updater &&\
    exit 0

elif [ "${1}" == "deploy" ]; then
    if [ "${TRAVIS_BRANCH}" == "master" ] &&\
       [ "${TRAVIS_TAG}" == "" ] &&\
       [ "${TRAVIS_PULL_REQUEST}" == "false" ]
    then
        docker push ${DOCKER_IMAGE}:latest &&\
        exit 0
    else
        echo Skipping deployment && exit 0
    fi

fi

exit 1
