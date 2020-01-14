#!/bin/bash

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
        #git push origin $tag
    fi
}

repository_root=$1
latest_commit_comment=$(git log -n 1 --format="%B" | head -n 1)
latest_commit_short_sha=$(git log -n 1 --format="%h")

cd $repository_root
is_head_revision_tagged=$(git describe --exact-match $latest_commit_short_sha 2>&1 > /dev/null)

if [ $? -eq 0 ]
then
    echo "Commit: $latest_commit_short_sha is already tagged. Exiting ..."
else
    if [[ $latest_commit_comment =~ \[(.*)\] ]]
    then
        latest_tag=$(git describe --abbrev=0 2>&1 > /dev/null)

        if [ $? -gt 0 ]
        then
            latest_tag="0.0.0"
        fi

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
                fi
            fi
        fi
    else
        echo "Could not determine version to increment from commit: $latest_commit_short_sha. Make sure to commit with either the [MAJOR], [MINOR] or [PATCH] prefixes"
    fi
fi
