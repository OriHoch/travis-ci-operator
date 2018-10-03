# Travis CI Operator

Automate setup and usage of Travis CI in combination with Docker and GitHub

## Initialize

Create the travis-ci-operator local configuration directory and give permissions to travis-ci-operator user id which is used in the docker container

```
sudo mkdir -p /etc/travis-ci-operator && sudo chown 1023:1023 /etc/travis-ci-operator
```

To authenticate with Travis you need a travis token which you can get from Travis web app > profile > settings > COPY TOKEN

Or, if you have Travis CLI installed, use `travis token`

```
docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    init travis_token github_user/repo branch_name
```

## Authenticate with Docker

Create a Docker user to be used for this purpose only: https://hub.docker.com/

The Docker repo should be under an organization: https://hub.docker.com/organizations/

Create a team for this project and add the Docker user you created to this team

Create a Docker repo for this project and assign this team to it with write access

Store the credentials for travis-ci-operator:

```
docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    init-docker travis_token github_user/repo branch_name docker_user docker_password
```

## Add deploy key to allow pushing to another repo

github user/repo and branch name refer to the current repo (not the repo you want to push to)

```
docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    add-deploy-key travis_token github_user/repo branch_name deploy_key_name
```

## Generate travis.yml file

Outputs a simple .travis.yml file with a minimal setup supporting travis-ci-operator

```
docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    get-travis-yml github_user/repo branch_name
```

## Helper scripts

Once travis-ci-operator is setup for your repo you can source the travis-ci-operator functions from your .travis.yml to authenticate with the supported services

```
wget -qO - https://
```