#!/bin/bash

# script to prepare the development environment for alexa hosted skill development
set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

merge_skill_json () {
    git checkout dev -- skill-package/skill_template.json
    pushd $PWD
    cd skill-package/
    # merge keys
    jq -s '.[0] * .[1]' skill.json skill_template.json > merged_skill.json
    # now add locales
    jq '.manifest.publishingInformation.locales as $locales | .manifest.publishingInformation.locales |= . + { "en-GB": $locales."en-US", "en-IN": $locales."en-US" }' merged_skill.json > updated_skill.json
    mv updated_skill.json skill.json
    # remove the temp files
    rm merged_skill.json skill_template.json
    popd
}

create_and_commit_env_file() {
    # disable debug logging since it may echo access keys
    set +x
    for var in $(env | cut -d= -f1); do
      if [[ $var == *_ALEXA_SKILL_ENV ]]; then
        echo "${var%_ALEXA_SKILL_ENV}=${!var}" >> lambda/.env
      fi
    done
    set -x
    git add lambda/.env
    git commit -m "Added env"
}

merge_lambda_dir () {
    git checkout dev -- lambda/
    git add lambda/
    git commit -m "Prepare lambda for merge"
}

merge_skill_package () {
    git checkout dev -- skill-package/interactionModels/custom/en-US.json
    merge_skill_json
    git add skill-package/
    git commit -m "Prepare skill-package for merge"
}

SKILL_ROOT_DIR=$1
SKILL_REPO="https://github.com/$2.git"

cd "${SKILL_ROOT_DIR}"

# commit the changes in master branch as part of the skill creation
git add .gitignore skill-package/
git commit -m "Initial Commit for skill-package"

# add the repo to fetch the skill code
git remote add github "${SKILL_REPO}"
git fetch github dev
git checkout -b dev github/dev

# prepare master branch by merging with dev
git checkout master
create_and_commit_env_file
merge_lambda_dir
merge_skill_package

# For the initial merge we will be merging 2 trees that are unrelated, since one is created by
# ask CLI
git merge --allow-unrelated-histories --no-edit dev