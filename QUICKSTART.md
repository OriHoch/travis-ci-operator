
## Install system dependencies

Install Docker for [Windows](https://store.docker.com/editions/community/docker-ce-desktop-windows),
[Mac](https://store.docker.com/editions/community/docker-ce-desktop-mac) or [Linux](https://docs.docker.com/install/)

Create the travis-ci-operator local configuration directory and give permissions to travis-ci-operator user id which is used in the docker container

```
sudo mkdir -p /etc/travis-ci-operator && sudo chown 1023:1023 /etc/travis-ci-operator
```

Install and authenticate with [Travis CLI](https://github.com/travis-ci/travis.rb#installation)

## (optional) Install Conda environment to run the Jupyter notebooks

This allows to run the notebook interactively, you can skip this step and continue with `Install travis-ci-operator` section, copy-pasting the relevant code and running in a terminal

Create the Conda environment

```
conda env create -f environment.yaml
```

Activate the environment, install dependencies and start jupyter lab

```
. activate travis-ci-operator
pip install bash_kernel
python -m bash_kernel.install
jupyter lab
```

Download the [quickstart notebook](https://raw.githubusercontent.com/OriHoch/travis-ci-operator/master/QUICKSTART.ipynb) and open in Jupyter Lab

## Initialize a repo for travis-ci-operator

Verify you get a token from `travis token` command (keep it private!)


```bash
if travis token | python -c "import sys; print(''.join(['*' for i in range(len(sys.stdin.read()))]))"
then echo OK
else echo failed to get travis token; fi
```

    ***********************
    OK



```bash
# change these values according to the repo you want to activate travis-ci-operator for
export GITHUB_USER="hasadna"
export GITHUB_REPO="migdar-search-ui"
export BRANCH_NAME="master"

echo This step needs to run interactively outside of the Jupyter notebooks
echo
echo run the following in a new terminal to initialize ${GITHUB_USER}/${GITHUB_REPO}:
echo
echo docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator \
                -it uumpa/travis-ci-operator init \`travis token\` ${GITHUB_USER}/${GITHUB_REPO} ${BRANCH_NAME}
```

    This step needs to run interactively outside of the Jupyter noteboo

    run the following in a new terminal to initialize hasadna/migdar-search-ui:

    docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator init `travis token` hasadna/migdar-search-ui master


The deploy keys are stored here:


```bash
ls -lah /etc/travis-ci-operator/${GITHUB_USER}/${GITHUB_REPO}
```

    total 16K
    drwxr-xr-x 2 1023 1023 4.0K Oct 19 14:35 [0m[01;34m.[0m
    drwxr-xr-x 4 1023 1023 4.0K Oct 19 14:35 [01;34m..[0m
    -rw------- 1 1023 1023 3.2K Oct 19 14:35 id_rsa
    -rw-r--r-- 1 1023 1023  744 Oct 19 14:35 id_rsa.pub


## Initialize Docker

This allows to run docker pull / push from travis

1. Create a Docker user to be used for this purpose only: https://hub.docker.com/
2. The Docker repo should be under an organization: https://hub.docker.com/organizations/
3. Create a team for this project and add the Docker user you created to this team
4. Create a Docker repo for this project and assign this team to it with write access
5. Store the Docker user credentials for travis-ci-operator



```bash
# set the credentials of the dedicated user
DOCKER_USER=""
DOCKER_PASSWORD=""

docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    init-docker `travis token` ${GITHUB_USER}/${GITHUB_REPO} ${BRANCH_NAME} ${DOCKER_USER} ${DOCKER_PASSWORD}
```

## Allow to push to another repo

e.g. to update downstream


```bash
# set a short name for the deploy key
export DEPLOY_KEY_NAME=migdar-k8s

echo This step needs to run interactively outside of the Jupyter noteboo
echo
echo run the following in a new terminal to add deploy key ${DEPLOY_KEY_NAME}:
echo
echo docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator \
                -it uumpa/travis-ci-operator add-deploy-key \`travis token\` \
                ${GITHUB_USER}/${GITHUB_REPO} ${BRANCH_NAME} ${DEPLOY_KEY_NAME}
```

    This step needs to run interactively outside of the Jupyter noteboo

    run the following in a new terminal to add deploy key migdar-k8s:

    docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator add-deploy-key `travis token` hasadna/migdar-search-ui master migdar-k8s


## Generate .travis.yml file

Outputs an basic .travis.yml file which you can modify and extend


```bash
DOCKER_IMAGE="uumpa/hasadna-migdar-internal-search-ui"
DEPLOY_BRANCH="master"

echo
echo Create the following files in the root of the ${GITHUB_USER}/${GITHUB_REPO} repo, ${BRANCH_NAME} branch:
echo
echo
docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    get-travis-yml ${GITHUB_USER}/${GITHUB_REPO} ${BRANCH_NAME}

echo Create the above .travis.yml and append the following lines:
echo '
script:
- chmod +x .travis.sh && ./.travis.sh script
deploy:
  provider: script
  script: chmod +x .travis.sh && ./.travis.sh deploy
  on:
    tags: false
    condition: "$TRAVIS_BRANCH = '${DEPLOY_BRANCH}'
'

echo
echo
echo -- .travis.sh:
echo
echo '
#!/usr/bin/env bash

DOCKER_IMAGE='${DOCKER_IMAGE}'

[ -e .travis.banner ] && cat .travis.banner

if [ "${1}" == "script" ]; then
    docker build -t ${DOCKER_IMAGE}:latest -t ${DOCKER_IMAGE}:${TRAVIS_COMMIT} && exit 0
elif [ "${1}" == "deploy" ]; then
    docker push ${DOCKER_IMAGE}:latest && docker push ${DOCKER_IMAGE}:${TRAVIS_COMMIT} && exit 0
fi; exit 1
'
```


    Create the following files in the root of the hasadna/migdar-search-ui repo, master branch:


    Cloning git repo git@github.com:hasadna/migdar-search-ui.git
    Cloning into '/tmp/tmp.ilKoHO'...
    Warning: Permanently added the RSA host key for IP address '192.30.253.112' to the list of known hosts.
    remote: Enumerating objects: 21, done.[K
    remote: Counting objects: 100% (21/21), done.[K
    remote: Compressing objects: 100% (17/17), done.[K
    remote: Total 45 (delta 10), reused 15 (delta 4), pack-reused 24[K
    Receiving objects: 100% (45/45), 127.16 KiB | 307.00 KiB/s, done.
    Resolving deltas: 100% (14/14), done.
    /tmp/tmp.ilKoHO ~
    Traceback (most recent call last):
      File "/home/travis-ci-operator/read_yaml.py", line 18, in <module>
        print(json.dumps(get_from_dict(values, sys.argv[2:]), separators=(',', ':')))
      File "/home/travis-ci-operator/read_yaml.py", line 15, in get_from_dict
        return values[keys[0]]
    KeyError: 'selfDeployKeyDecryptCmd'
    travis.yml:
    ---
    language: bash
    sudo: required
    env:
      global:
      - TRAVIS_CI_OPERATOR=1
      - secure: "Soe7CfrBMzbQIIrJi3yFPXWtMtk+gBpdrZrUsNpdNOfqzyiNX72CqNKxHk/BgFKjI3VSpCG1hOjH7ahzq3pUsBE/JoK2sQ0ndO5v4ookFH07V3M1V0jXDWywGpZ/+tmkuHNwljliIJvGO07fOQxgztDxuIfQiJgIN51lW9Hpdq00ADcJC5ouqZRldI1crxu/+CeIaelxk+SvhyuSGuMlG2Chze/Djtys/iPxgdsf2S62j6RNLz78dzTwtACEF7iON8w0pcYlT/hVnIxY29VF6uI92ezPQ+tkrnl6KgqWh7rxtnlUt0lIscTxIGKTgWEQ/QtSa4nNbc02z96qG6c5aWMGo0QGJs8lqz5cH4TGsc/K+tZUz4xvwgVWuY/BzDLHxQBCY4B1PWWHQ1abvBVUX2MdCk3zBa0lbCop/D4iMQZhTLCyyBqFylT6jHRzscxLauYbRfPDqiAWUJJwBYzl5gjteGkdBMpxh/Sd/t6pqWC+1nxw+y8s3E+uldMfVtI1FiopvcpP6qamZMhPys0BauhFX7p+Q7uFq1vHBm4Zhtyd+6ItOY6z6KnuyaewsQEI/tmBegx3yjQCYhYdZ9v2oayT9Wq7P58yfOs2nTDzCutaCgIPhtUmqh7MD1KcUTd/fsAaH5XPXKE3s+1TLvrMS3Rd86TpVJXXShYSj4OXej0="
      - secure: "fZ9wTzMk7bI5iRVJkfksLBuKQ7ISdDoNOqSM+6EJxKwmHkDGOAQG/Z+nu8ZtUpJmG/7VVNoEdBkLiWbA0jgPTAqBs+gDLJzT99khAhCHPHHKcQI7fq10ThdL6Z2VwzHbdoHKvmShBDaDBfDWnFBJDely9zNlMQ+u5bD1itnE/Z/Kd+iXcuVeY0xS8pTagCvBqcUdEO2FwOQQ1jCwVcc5bEoKuc7dlkbaZTaFBmuKIoaQpv9iZcXBroHbfHNqQKfzQ6X1nNbz3D0lA6tULVzAjqaiApI/X7E6Vgc7HCV6AaaZTREdTvfuk6bbF+oGan8SCWPY7ITJjtP9ZmPD59ErjixXUD5pZT5qrRje1waz8+KvKIt5ahdQamz1yXNlQ6WknW1Q2FYnigh5h8g/88PKhjZp1fF7yuc/maqhTCzUfey+06ojVxJxMr4pGHGK3IuIZKwpVk97TPqyDmrdEBnd4mU82YBuDwPbAcWceCnYFRfI1Rf/xsc+r4B/4MaYkeUvkOmEYtABMbXa5Jv3CNH73r7Brt/I8lhnm1bh9cOIuaBTGA9A2kr8BTJ9rF9/qHAZt9JfDSCRXT8YwUQv/Zj2lPXyIJVE7Vs4N9F1tYzMwGm/HJKekiBpl6fN6d/1d8A/qtyr1TnUDhnHf3SvVATsEz+SO/bU/c6TeAa2EvJv0r4="
    services:
    - docker
    install:
    - curl -L https://raw.githubusercontent.com/OriHoch/travis-ci-operator/master/travis_ci_operator.sh > $HOME/bin/travis_ci_operator.sh
    - bash $HOME/bin/travis_ci_operator.sh init
    - travis_ci_operator.sh docker-login
    ---
    Create the above .travis.yml and append the following lines:

    script:
    - chmod +x .travis.sh && ./.travis.sh script
    deploy:
      provider: script
      script: chmod +x .travis.sh && ./.travis.sh deploy
      on:
        tags: false
        condition: "$TRAVIS_BRANCH = master



    -- .travis.sh:


    #!/usr/bin/env bash

    DOCKER_IMAGE=uumpa/hasadna-migdar-internal-search-ui

    [ -e .travis.banner ] && cat .travis.banner

    if [ "${1}" == "script" ]; then
        docker build -t ${DOCKER_IMAGE}:latest -t ${DOCKER_IMAGE}:${TRAVIS_COMMIT} && exit 0
    elif [ "${1}" == "deploy" ]; then
        docker push ${DOCKER_IMAGE}:latest && docker push ${DOCKER_IMAGE}:${TRAVIS_COMMIT} && exit 0
    fi; exit 1


