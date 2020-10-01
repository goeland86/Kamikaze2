#!/bin/bash

TAG=$(git log -n1 --pretty="format:%d" | sed "s/, /\n/g" | grep tag: | sed "s/tag: \|)//g")

if [[ $TAG == "" ]]; then
	TAG=$(git reflog --decorate -1 | awk -F' ' '{print $1}')
fi

echo $TAG
