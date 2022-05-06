#!/bin/bash

git branch -D branch1
git checkout -b branch1
git push --set-upstream origin branch1 -f
git checkout main
