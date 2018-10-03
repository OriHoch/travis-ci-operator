FROM ruby:alpine

RUN apk add --no-cache build-base git bash python openssh && \
    gem install travis && \
    gem install travis-lint && \
    apk del build-base

RUN apk add --no-cache py-yaml

RUN addgroup travis-ci-operator -g 1023 && adduser travis-ci-operator -D -u 1023 -G travis-ci-operator

USER travis-ci-operator

WORKDIR /home/travis-ci-operator

RUN mkdir -p .ssh && ssh-keyscan -t rsa github.com >> .ssh/known_hosts &&\
    git config --global user.email "travis-ci-operator@null" &&\
    git config --global user.name "travis-ci-operator"

COPY entrypoint.sh update_yaml.py read_yaml.py ./

ENTRYPOINT ["./entrypoint.sh"]
