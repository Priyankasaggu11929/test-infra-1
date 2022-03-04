#!/bin/bash

github_org="${1}"
github_repo="${2}"
command="${@:3}"

git clone "https://github.com/${github_org}/${github_repo}"
cd "${github_repo}"
eval "${command}"

