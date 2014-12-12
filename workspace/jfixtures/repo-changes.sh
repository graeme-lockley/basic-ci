#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

LOG_FILE_NAME=logs/repo-poll-`date "+%Y%m%d-%H%M%S"`.log
CONTROL_FILE_NAME=".repo-head"

mkdir logs >> /dev/null 2>&1 

git ls-remote https://github.com/graeme-lockley/jfixtures.git > $LOG_FILE_NAME 2>&1
HEAD=`cat $LOG_FILE_NAME | grep HEAD | cut -f 1`

if [ ! -e $CONTROL_FILE_NAME ]
then
	echo "info: No control file found" >> $LOG_FILE_NAME
	echo "action: Creating control file with $HEAD" >> $LOG_FILE_NAME
	echo "$HEAD" > $CONTROL_FILE_NAME

	echo "Kicking off pipeline" >> $LOG_FILE_NAME
	./kick-off-pipeline.sh
elif [ "`cat $CONTROL_FILE_NAME`" != "$HEAD" ]
then
	echo "info: The control file and head have different hash codes: HEAD=$HEAD: CONTROL=`cat $CONTROL_FILE_NAME`" >> $LOG_FILE_NAME
	echo "action: Updating control file with new head" >> $LOG_FILE_NAME
	echo "$HEAD" > $CONTROL_FILE_NAME

	echo "action: Kicking off pipeline" >> $LOG_FILE_NAME
	./kick-off-pipeline.sh
else
	echo "info: The control file and head have the same values - nothing to do" >> $LOG_FILE_NAME
fi

