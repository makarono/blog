#! /bin/bash

set -eux 

OUTPUT="imroc.github.io"

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

msg="rebuilding site `date`"
if [ $# -eq 1  ]
    then msg="$1"
fi

# Build the project. 
hugo -d $OUTPUT # if using a theme, replace by `hugo -t <yourtheme>`

# Go To Public folder
cd imroc.github.io

# Add changes to git.
git add .

# Commit changes.

git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..

git add .
git commit -m "$msg"
git push origin master

