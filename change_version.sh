#!/bin/bash

git pull
VALUE=""
if grep -q ":v1" deployment.yaml; then
    sed -i 's/wil42\/playground\:v1/wil42\/playground\:v2/g' deployment.yaml
    VALUE="v2"
elif grep -q ":v2" deployment.yaml; then
    sed -i 's/wil42\/playground\:v2/wil42\/playground\:v1/g' deployment.yaml
    VALUE="v1"
fi
git add deployment.yaml
git commit -am "Argo: Test $VALUE"
git push
