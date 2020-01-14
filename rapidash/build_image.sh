#!/bin/bash

path_to_dockerfile=$1
image_name=$2
tag=$3
tag_as_latest=$4

function build_image() {
    local path_to_dockerfile=$1
    local image_name=$2
    local tag=$3
    local tag_as_latest=$4

    if [ $tag_as_latest ]
    then
        docker build -t $image_name:$tag -t $image_name:latest $path_to_dockerfile
        if [ $? -gt 0 ]
        then
            echo "Could not build image image_named: $image_name@$tag. Exiting ..."
            exit 1
        else
            echo "Built $image_name@$tag"
        fi
    else
        docker build -t $image_name:$tag $path_to_dockerfile
        if [ $? -gt 0 ]
        then
            echo "Could not build image image_named: $image_name@$tag. Exiting ..."
            exit 1
        else
            echo "Built $image_name@$tag"
        fi
    fi
}

build_image $path_to_dockerfile $image_name $tag $tag_as_latest
