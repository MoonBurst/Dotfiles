#!/usr/bin/env bash

cd $($HOME/scripts/github/ ${BASH_SOURCE[0]})

if [[ -n $(git status -s) ]]; then
    echo "Changes found. Pushing changes..."
    git add -A && git commit -m 'update' && git push
else
    echo "No changes found. Skip pushing."
fi
