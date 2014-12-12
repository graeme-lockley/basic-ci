#!/bin/bash

export DATE_TIME_STAMP="$1"

if [ "$1" == "" ]
then
	export DATE_TIME_STAMP=`date "+%Y%m%d-%H%M%S"`
fi

RC_BRANCH_NAME="rc-$DATE_TIME_STAMP"

mkdir $RC_BRANCH_NAME

cd $RC_BRANCH_NAME

git clone https://github.com/graeme-lockley/jfixtures.git

( cd jfixtures ; ci-pipeline.rb run )
