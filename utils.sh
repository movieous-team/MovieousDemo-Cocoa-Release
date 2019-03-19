#!/bin/bash

PATH=/usr/libexec:$PATH

COMMAND="$1"
# 跳转到 utils.sh 所在文件夹
cd $(dirname "$0")

case "$COMMAND" in
    "new-build")
        agvtool next-version -all
        demo_build=`agvtool vers -terse`
        pod update --no-repo-update
        git add .
        git commit -m "new build framework $framework_build, demo $demo_build"
        exit 0
        ;;

    "release")
        dst_version="$2"
        if [ -z "$dst_version" ]; then
            echo "You must specify a version."
            exit 1
        fi
        agvtool new-marketing-version $dst_version
        agvtool next-version -all
        demo_build=`agvtool vers -terse`
        pod update --no-repo-update
        git add .
        git commit -m "release v$dst_version(framework build $framework_build, demo build $demo_build)"
        git tag "v$dst_version"
        exit 0
        ;;
    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
