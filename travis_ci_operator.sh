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

elif [ "${1}" == "github-update" ]; then
    DEPLOY_KEY_NAME="${2}"
    GIT_BRANCH="${3}"
    UPDATE_SCRIPT="${4}"
    COMMIT_MSG="${5}"
    [ -z "${DEPLOY_KEY_NAME}" ] || [ -z "${GIT_BRANCH}" ] || [ -z "${UPDATE_SCRIPT}" ] || [ -z "${COMMIT_MSG}" ] \
        && echo missing required arguments && exit 1
    [ "${DEPLOY_KEY_NAME}" == "self" ] && [ "${COMMIT_MSG}" == "${TRAVIS_COMMIT_MESSAGE}" ] && [ "${GIT_BRANCH}" == "${TRAVIS_BRANCH}" ] \
        && echo skipping update of self with same commit msg and branch && exit 0
    GITHUB_REPO_SLUG="${TRAVIS_REPO_SLUG}"
    [ -z "${GITHUB_REPO_SLUG}" ] && echo missing GITHUB_REPO_SLUG && exit 1
    GITHUB_DEPLOY_KEY_FILE="travis_ci_operator_${DEPLOY_KEY_NAME}_github_deploy_key.id_rsa"
    cp -f "${GITHUB_DEPLOY_KEY_FILE}" ~/.ssh/id_rsa && chmod 400 ~/.ssh/id_rsa
    [ "$?" != "0" ] && echo echo failed to setup deploy key for pushing to GitHub && exit 1
    GIT_REPO="git@github.com:${GITHUB_REPO_SLUG}.git"
    TEMPDIR=`mktemp -d`
    echo Cloning git repo ${GIT_REPO} branch ${GIT_BRANCH}
    ! git clone --branch ${GIT_BRANCH} ${GIT_REPO} ${TEMPDIR} && echo failed to clone repo && exit 1
    pushd $TEMPDIR
    eval "${UPDATE_SCRIPT}"
    echo Committing and pushing to GitHub repo ${GIT_REPO} branch ${GIT_BRANCH}
    git commit -m "${COMMIT_MSG}" &&\
    git push ${GIT_REPO} ${GIT_BRANCH}
    [ "$?" != "0" ] && echo failed to push change to GitHub && exit 1
    popd
    echo GitHub update complete successfully
    exit 0

else
    echo unknown command
    exit 1

fi
