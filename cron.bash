#!/bin/bash

set -ue

DIR=$(cd $(dirname $0); pwd)
cd $DIR
./bin/fetch_all
./bin/crawl ./static_repo_list.txt

# sometimes, confused git leaks some files in $DIR
git reset --hard HEAD

./bin/generate_json
git add -u
git commit -m "update data"
git push
