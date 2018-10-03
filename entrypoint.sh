#!/usr/bin/env bash

COMMAND="${1}"
ARGS="${@:2}"

usage() {
    echo Usage: docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator '<COMMAND>'
}

prepare_push_to_github() {
    GITHUB_REPO_SLUG="${1}"
    GIT_BRANCH="${2}"
    GITHUB_DEPLOY_KEY_FILE="/etc/travis-ci-operator/${GITHUB_REPO_SLUG}/id_rsa"
    cp -f "${GITHUB_DEPLOY_KEY_FILE}" ~/.ssh/id_rsa && chmod 400 ~/.ssh/id_rsa
    [ "$?" != "0" ] && echo echo failed to setup deploy key for pushing to GitHub && return 1
    GIT_REPO="git@github.com:${GITHUB_REPO_SLUG}.git"
    TEMPDIR=`mktemp -d`
    echo Cloning git repo ${GIT_REPO}
    ! git clone --branch ${GIT_BRANCH} ${GIT_REPO} ${TEMPDIR} && echo failed to clone repo && return 1
    pushd $TEMPDIR
    return 0
}

push_to_github() {
    GITHUB_REPO_SLUG="${1}"
    GIT_BRANCH="${2}"
    COMMIT_MSG="${3}"
    GIT_REPO="git@github.com:${GITHUB_REPO_SLUG}.git"
    echo Committing and pushing to GitHub repo ${GIT_REPO} branch ${GIT_BRANCH}
    git commit -m "${COMMIT_MSG}" &&\
    git push ${GIT_REPO} ${GIT_BRANCH}
    [ "$?" != "0" ] && echo failed to push change to GitHub && return 1
    popd
    return 0
}

init() {
    TRAVIS_TOKEN="${1}"
    GITHUB_REPO_SLUG="${2}"
    GIT_BRANCH="${3}"
    if [ -z "${TRAVIS_TOKEN}" ] || [ -z "${GITHUB_REPO_SLUG}" ] || [ -z "${GIT_BRANCH}" ]; then
        echo Usage: init '<TRAVIS_TOKEN>' '<GITHUB_REPO_SLUG>' '<GIT_BRANCH>'
        return 1
    else
        echo Generating GitHub deploy key for repo slug ${GITHUB_REPO_SLUG}
        [ -e /etc/travis-ci-operator/${GITHUB_REPO_SLUG} ] && echo WARNING! repo slug already initialized, overwriting existing data
        mkdir -p /etc/travis-ci-operator/${GITHUB_REPO_SLUG}
        GITHUB_DEPLOY_KEY_FILE="/etc/travis-ci-operator/${GITHUB_REPO_SLUG}/id_rsa"
        ! ssh-keygen -t rsa -b 4096 -C "travis-ci-operator" -P "" -f "${GITHUB_DEPLOY_KEY_FILE}" \
            && echo failed to generate ssh key && return 1
        echo "Please add the public deploy key to the relevant GitHub repo deploy keys"
        echo "and enable write access to this key"
        echo "https://github.com/OriHoch/travis-ci-operator/settings/keys/new"
        echo ---
        cat "${GITHUB_DEPLOY_KEY_FILE}.pub"
        echo ---
        read -p 'Press <Enter> after you added the key to your repo deploy keys'
        echo Enabling Travis for slug ${GITHUB_REPO_SLUG}
        while ! travis enable --token ${TRAVIS_TOKEN} --repo "${GITHUB_REPO_SLUG}" --no-interactive; do
            sleep 1
            echo .
        done
        echo Encrypting deploy key for travis
        ! SSH_DEPLOY_KEY_OPENSSL_CMD=$(travis encrypt-file --repo "${GITHUB_REPO_SLUG}" \
                                                           --token ${TRAVIS_TOKEN} \
                                                           "${GITHUB_DEPLOY_KEY_FILE}" \
                                                           ".travis_ci_operator_self_github_deploy_key.id_rsa.enc" \
                                                           --decrypt-to ".travis_ci_operator_self_github_deploy_key.id_rsa" \
                                                           -p --no-interactive | grep '^openssl ') || [ -z "${SSH_DEPLOY_KEY_OPENSSL_CMD}" ] \
            && echo failed to encrypt deploy key for travis && return 1
        cp -f "${GITHUB_DEPLOY_KEY_FILE}" ~/.ssh/id_rsa && chmod 400 ~/.ssh/id_rsa
        [ "$?" != "0" ] && echo failed to setup deploy key for pushing to GitHub && return 1
        echo Committing deploy key to repo ${GITHUB_REPO_SLUG} file .travis_ci_operator_self_github_deploy_key.id_rsa.enc
        GIT_REPO="git@github.com:${GITHUB_REPO_SLUG}.git"
        TEMPDIR=`mktemp -d`
        ! git clone --branch ${GIT_BRANCH} ${GIT_REPO} ${TEMPDIR} && echo failed to clone repo && return 1
        [ -e $TEMPDIR/.travis_ci_operator_self_github_deploy_key.id_rsa.enc ] && echo WARNING! overwriting existing .travis_ci_operator_self_github_deploy_key.id_rsa.enc
        rm -f $TEMPDIR/.travis_ci_operator_self_github_deploy_key.id_rsa.enc
        mv .travis_ci_operator_self_github_deploy_key.id_rsa.enc $TEMPDIR/.travis_ci_operator_self_github_deploy_key.id_rsa.enc
        pushd $TEMPDIR
        [ -e .travis-ci-operator.yaml ] && echo WARNING! overwriting existing .travis-ci-operator.yaml
        echo "selfDeployKeyDecryptCmd: '${SSH_DEPLOY_KEY_OPENSSL_CMD}'" > .travis-ci-operator.yaml
        git add .travis_ci_operator_self_github_deploy_key.id_rsa.enc &&\
        git add .travis-ci-operator.yaml &&\
        git commit -m "add travis-ci-operator github deploy key" &&\
        git push ${GIT_REPO} ${GIT_BRANCH}
        [ "$?" != "0" ] && echo failed to push change to GitHub && return 1
        popd
        echo Great Success
        return 0
    fi
}

init_docker() {
    TRAVIS_TOKEN="${1}"
    GITHUB_REPO_SLUG="${2}"
    GIT_BRANCH="${3}"
    DOCKER_USER="${4}"
    DOCKER_PASSWORD="${5}"
    if [ -z "${TRAVIS_TOKEN}" ] || [ -z "${GITHUB_REPO_SLUG}" ] || [ -z "${GIT_BRANCH}" ] \
       || [ -z "${DOCKER_USER}" ] || [ -z "${DOCKER_PASSWORD}" ]; then
        echo Usage: init-docker '<TRAVIS_TOKEN>' '<GITHUB_REPO_SLUG>' '<GIT_BRANCH>' '<DOCKER_USER>' '<DOCKER_PASSWORD>'
        return 1
    else
        echo Generating encrypted Docker credentials
        ! ENCRYPTED_DOCKER_USER=$(travis encrypt --token ${TRAVIS_TOKEN} \
                                                 --repo "${GITHUB_REPO_SLUG}" \
                                                 "DOCKER_USER=${DOCKER_USER}" \
                                                 --no-interactive) || [ -z "${ENCRYPTED_DOCKER_USER}" ] \
            && echo failed to encrypt docker user && return 1
        ! ENCRYPTED_DOCKER_PASSWORD=$(travis encrypt --token ${TRAVIS_TOKEN} \
                                                     --repo "${GITHUB_REPO_SLUG}" \
                                                     "DOCKER_PASSWORD=${DOCKER_PASSWORD}" \
                                                     --no-interactive) || [ -z "${ENCRYPTED_DOCKER_PASSWORD}" ] \
            && echo failed to encrypt docker password && return 1
        ! prepare_push_to_github "${GITHUB_REPO_SLUG}" "${GIT_BRANCH}" && return 1
        SET_VALUES='{"encryptedDockerUser":'${ENCRYPTED_DOCKER_USER}',"encryptedDockerPassword": '${ENCRYPTED_DOCKER_PASSWORD}'}'
        ! ~/update_yaml.py "${SET_VALUES}" \
                           .travis-ci-operator.yaml && echo failed to update .travis-ci-operator.yaml && return 1
        git add .travis-ci-operator.yaml
        ! push_to_github "${GITHUB_REPO_SLUG}" "${GIT_BRANCH}" "travis-ci-operator: add docker support" && return 1
        echo Great Success
        return 0
    fi
}

get_travis_yml() {
    GITHUB_REPO_SLUG="${1}"
    GIT_BRANCH="${2}"
    if [ -z "${GITHUB_REPO_SLUG}" ] || [ -z "${GIT_BRANCH}" ]; then
        echo Usage: get-travis-yml '<GITHUB_REPO_SLUG>' '<GIT_BRANCH>'
        return 1
    else
        ! prepare_push_to_github "${GITHUB_REPO_SLUG}" "${GIT_BRANCH}" && return 1
        SSH_DEPLOY_KEY_OPENSSL_CMD=`~/read_yaml.py .travis-ci-operator.yaml selfDeployKeyDecryptCmd`
        ENCRYPTED_DOCKER_USER=`~/read_yaml.py .travis-ci-operator.yaml encryptedDockerUser`
        ENCRYPTED_DOCKER_PASSWORD=`~/read_yaml.py .travis-ci-operator.yaml encryptedDockerPassword`
        if ! [ -z "${ENCRYPTED_DOCKER_USER}" ] && ! [ -z "${ENCRYPTED_DOCKER_PASSWORD}" ]; then
            DOCKER_INSTALL_STEP="- travis_ci_operator.sh docker-login"
            DOCKER_USER_SECURE_ENV='  - secure: '${ENCRYPTED_DOCKER_USER}
            DOCKER_PASSWORD_SECURE_ENV='  - secure: '${ENCRYPTED_DOCKER_PASSWORD}
        else
            DOCKER_INSTALL_STEP=""
            DOCKER_USER_SECURE_ENV=""
            DOCKER_PASSWORD_SECURE_ENV=""
        fi
        echo travis.yml:
        echo ---
        echo "language: bash
sudo: required
env:
  global:
  - TRAVIS_CI_OPERATOR=1
${DOCKER_USER_SECURE_ENV}
${DOCKER_PASSWORD_SECURE_ENV}
services:
- docker
install:
- curl -L https://raw.githubusercontent.com/OriHoch/travis-ci-operator/master/travis_ci_operator.sh > \$HOME/bin/travis_ci_operator.sh
- bash \$HOME/bin/travis_ci_operator.sh init
${DOCKER_INSTALL_STEP}
script:
- docker build -t org/image:latest .
- travis_ci_operator.sh github-update self master \"echo foo > bar; git add bar\" \"testing github self update\"
- travis_ci_operator.sh github-update github-yaml-updater master \"echo foo > bar; git add bar\" \"testing travis-ci-operator\" OriHoch/github-yaml-updater
- travis_ci_operator.sh github-yaml-update self master test.yaml '{\"foo\":\"bar\"}' \"testing github yaml update\"
- travis_ci_operator.sh github-yaml-update github-yaml-updater master test.yaml '{\"foo\":\"bar\"}' \"testing travis-ci-operator github yaml update\" OriHoch/github-yaml-updater
deploy:
  provider: script
  script: docker push org/image:latest
  on:
    branch: master
    condition: \$TRAVIS_TAG = \"\" && \$TRAVIS_PULL_REQUEST = \"false\"
"
        echo ---
        return 0
    fi
}

add_deploy_key() {
    TRAVIS_TOKEN="${1}"
    GITHUB_REPO_SLUG="${2}"
    GIT_BRANCH="${3}"
    DEPLOY_KEY_NAME="${4}"
    if [ -z "${TRAVIS_TOKEN}" ] || [ -z "${GITHUB_REPO_SLUG}" ] || [ -z "${GIT_BRANCH}" ] || [ -z "${DEPLOY_KEY_NAME}" ]; then
        echo Usage: add-deploy-key '<TRAVIS_TOKEN>' '<GITHUB_REPO_SLUG>' '<GIT_BRANCH>' '<DEPLOY_KEY_NAME>'
        return 1
    else
        echo Generating GitHub deploy key for deploy key name ${DEPLOY_KEY_NAME}
        [ -e /etc/travis-ci-operator/deploy_keys/${DEPLOY_KEY_NAME} ] \
            && echo WARNING! deploy key name already exists, overwriting existing data \
            && rm -rf /etc/travis-ci-operator/deploy_keys/${DEPLOY_KEY_NAME}
        mkdir -p /etc/travis-ci-operator/deploy_keys/${DEPLOY_KEY_NAME}
        OTHER_DEPLOY_KEY_FILE="/etc/travis-ci-operator/deploy_keys/${DEPLOY_KEY_NAME}/id_rsa"
        ! ssh-keygen -t rsa -b 4096 -C "travis-ci-operator" -P "" -f "${OTHER_DEPLOY_KEY_FILE}" \
            && echo failed to generate ssh key && return 1
        echo "Please add the public deploy key to the relevant GitHub repo deploy keys"
        echo "and enable write access to this key"
        echo ---
        cat "${OTHER_DEPLOY_KEY_FILE}.pub"
        echo ---
        read -p 'Press <Enter> after you added the key to your repo deploy keys'
        echo Encrypting deploy key for travis
        ! prepare_push_to_github "${GITHUB_REPO_SLUG}" "${GIT_BRANCH}" && return 1
        if [ -e ".travis_ci_operator_${DEPLOY_KEY_NAME}_github_deploy_key.id_rsa.enc" ]; then
            echo WARNING! encrypted deploy key already exists, will overwrite
            rm ".travis_ci_operator_${DEPLOY_KEY_NAME}_github_deploy_key.id_rsa.enc"
        fi
        ! SSH_DEPLOY_KEY_OPENSSL_CMD=$(travis encrypt-file --repo "${GITHUB_REPO_SLUG}" \
                                                           --token ${TRAVIS_TOKEN} \
                                                           "${OTHER_DEPLOY_KEY_FILE}" \
                                                           ".travis_ci_operator_${DEPLOY_KEY_NAME}_github_deploy_key.id_rsa.enc" \
                                                           --decrypt-to ".travis_ci_operator_${DEPLOY_KEY_NAME}_github_deploy_key.id_rsa" \
                                                           -p --no-interactive | grep '^openssl ') || [ -z "${SSH_DEPLOY_KEY_OPENSSL_CMD}" ] \
            && echo failed to encrypt deploy key for travis && return 1
        SET_VALUES='{"'${DEPLOY_KEY_NAME}'DeployKeyDecryptCmd": "'${SSH_DEPLOY_KEY_OPENSSL_CMD}'"}'
        ! ~/update_yaml.py "${SET_VALUES}" \
                           .travis-ci-operator.yaml && echo failed to update .travis-ci-operator.yaml && return 1
        git add ".travis_ci_operator_${DEPLOY_KEY_NAME}_github_deploy_key.id_rsa.enc"
        git add .travis-ci-operator.yaml
        ! push_to_github "${GITHUB_REPO_SLUG}" "${GIT_BRANCH}" "travis-ci-operator: add deploy key ${DEPLOY_KEY_NAME}" && return 1
        echo Great Success
        return 0
    fi
}


if [ "${COMMAND}" == "" ]; then
    usage
    exit 0
elif [ "${COMMAND}" == "init" ]; then
    ! init $ARGS && exit 1
    exit 0
elif [ "${COMMAND}" == "init-docker" ]; then
    ! init_docker $ARGS && exit 1
    exit 0
elif [ "${COMMAND}" == "get-travis-yml" ]; then
    ! get_travis_yml $ARGS && exit 1
    exit 0
elif [ "${COMMAND}" == "add-deploy-key" ]; then
    ! add_deploy_key $ARGS && exit 1
    exit 0
else
    echo unknown command: ${COMMAND}
    exit 1
fi
