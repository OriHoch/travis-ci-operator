#!/usr/bin/env bash

VERSION_LABEL="${1}"

[ "${VERSION_LABEL}" == "" ] \
    && echo ERROR! Missing version label \
    && echo current VERSION.txt = $(cat VERSION.txt) \
    && exit 1

docker build -t uumpa/travis-ci-operator:v${VERSION_LABEL} . &&\
docker push uumpa/travis-ci-operator:v${VERSION_LABEL} &&\
docker tag uumpa/travis-ci-operator:v${VERSION_LABEL} uumpa/travis-ci-operator:latest &&\
docker push uumpa/travis-ci-operator:latest &&\
echo "${VERSION_LABEL}" > VERSION.txt &&\
echo uumpa/travis-ci-operator:v${VERSION_LABEL} &&\
echo Great Success &&\
exit 0

exit 1
