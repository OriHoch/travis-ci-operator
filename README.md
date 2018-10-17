# Travis CI Operator

Automate setup and usage of Travis CI in combination with Docker and GitHub

## Initialize

Create the travis-ci-operator local configuration directory and give permissions to travis-ci-operator user id which is used in the docker container

```
sudo mkdir -p /etc/travis-ci-operator && sudo chown 1023:1023 /etc/travis-ci-operator
```

Install and authenticate with [Travis CLI](https://github.com/travis-ci/travis.rb#installation)

Initliaze a repo for travis-ci-operator:

```
docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    init `travis token` github_user/repo branch_name
```

## Authenticate with Docker

Create a Docker user to be used for this purpose only: https://hub.docker.com/

The Docker repo should be under an organization: https://hub.docker.com/organizations/

Create a team for this project and add the Docker user you created to this team

Create a Docker repo for this project and assign this team to it with write access

Store the Docker user credentials for travis-ci-operator:

```
docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    init-docker `travis token` github_user/repo branch_name docker_user docker_password
```

## Add deploy key to allow pushing to another repo

github user/repo and branch name refer to the current repo (not the repo you want to push to)

```
docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    add-deploy-key `travis token` github_user/repo branch_name deploy_key_name
```

## Generate .travis.yml file

Outputs an example .travis.yml file

```
docker run -v /etc/travis-ci-operator:/etc/travis-ci-operator -it uumpa/travis-ci-operator \
    get-travis-yml github_user/repo branch_name
```

## Using the operator from .travis.yml

### Login to Docker

If you authenticated with Docker in the previous step you can use the following to login to Docker:

```
sudo: required
services:
- docker
install:
- travis_ci_operator.sh docker-login
```

You can then run docker build / push in the script or deploy steps

```
script:
- docker build -t my-docker-user/my-project . && docker push my-docker-user/my-project
```

### Pushing changes to GitHub repos

The following command will add file `foo` to the main (self) repo's master branch with commit message "testing github self update":

```
script:
- travis_ci_operator.sh github-update self master "echo foo > bar; git add bar" "testing github self update"
```

The following command will add file `foo` to the repo configured with deploy key name `github-yaml-updater` at master branch with the given commit message

The last argument is the repo slug of the other repo to update:

```
script:
- travis_ci_operator.sh github-update github-yaml-updater master "echo foo > bar; git add bar" "testing travis-ci-operator" OriHoch/github-yaml-updater
```

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
