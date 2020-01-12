#!/bin/bash

repository_root=$(cd $1 ; pwd)
latest_commit_comment=$(git log -n 1 --format="%B" | head -n 1)
latest_commit_short_sha=$(git log -n 1 --format="%h")

function tag_commit() {
    local previous_tag=$1
    local tag=$2
    local message=$3
    local commit_sha=$4
    
    git tag -a -m "$message" $tag

    if [ $? -gt 0 ]
    then
        echo "Could not apply $tag to commit: $commit_sha. Exiting ..."
        exit 1
    else
        echo "Version is now: $tag, previous was: $previous_tag"
    fi
}

function build_image() {
    local name=$1
    local tag=$2
    local path_to_dockerfile=$3
    local tag_as_latest=$4

    if [ $tag_as_latest ]
    then
        docker build -t $name:$tag -t $name:latest $path_to_dockerfile
        if [ $? -gt 0 ]
        then
            echo "Could not build image named: $name@$tag. Exiting ..."
            exit 1
        else
            echo "Built $name@$tag"
        fi
    else
        docker build -t $name:$tag $path_to_dockerfile
        if [ $? -gt 0 ]
        then
            echo "Could not build image named: $name@$tag. Exiting ..."
            exit 1
        else
            echo "Built $name@$tag"
        fi
    fi
}

cd $repository_root

tag_from_latest_commit=$(git describe --exact-match $latest_commit_short_sha)

if [ $? -eq 0 ]
then
    echo "Commit: $latest_commit_short_sha is already tagged. Building image ..."
    build_image $(basename `pwd` | tr '[:upper:]' '[:lower:]') $tag_from_latest_commit . true
else

    if [[ $latest_commit_comment =~ \[(.*)\] ]]
    then
        latest_tag=$(git describe --abbrev=0:-0.0.0)
        if [[ $latest_tag =~ ([0-9]*)\.([0-9]*)\.([0-9]*) ]]
        then
            if [[ "${BASH_REMATCH[1]}" == "PATCH" ]]
            then
                major="${BASH_REMATCH[1]}"
                minor="${BASH_REMATCH[2]}"
                patch="${BASH_REMATCH[3]}"
                incremented_patch=$((patch+1))
                new_tag=$major.$minor.$incremented_patch
                
                tag_commit $latest_tag $new_tag $latest_commit_comment $latest_commit_short_sha
                build_image $(basename `pwd` | tr '[:upper:]' '[:lower:]') $new_tag . true
            elif [[ "${BASH_REMATCH[1]}" == "MINOR" ]]
            then
            if [[ $latest_tag =~ ([0-9]*)\.([0-9]*)\.([0-9]*) ]]
                then
                    major="${BASH_REMATCH[1]}"
                    minor="${BASH_REMATCH[2]}"
                    patch="${BASH_REMATCH[3]}"
                    incremented_minor=$((minor+1))
                    new_tag=$major.$incremented_minor.$patch
                    
                    tag_commit $latest_tag $new_tag $latest_commit_comment $latest_commit_short_sha
                    build_image $(basename `pwd` | tr '[:upper:]' '[:lower:]') $new_tag . true
                fi
            else
                if [[ $latest_tag =~ ([0-9]*)\.([0-9]*)\.([0-9]*) ]]
                then
                    major="${BASH_REMATCH[1]}"
                    minor="${BASH_REMATCH[2]}"
                    patch="${BASH_REMATCH[3]}"
                    incremented_major=$((major+1))
                    new_tag=$incremented_major.$minor.$patch

                    tag_commit $latest_tag $new_tag $latest_commit_comment $latest_commit_short_sha
                    build_image $(basename `pwd` | tr '[:upper:]' '[:lower:]') $new_tag . true
                fi
            fi
        fi
    else
        echo "Could not determine version to increment from commit: $latest_commit_short_sha. Make sure to commit with either the [MAJOR], [MINOR] or [PATCH] prefixes"
    fi
fi
