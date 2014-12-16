Basic-CI
========

I am confused by the complexity and degree of opinion with the current crop of CI software.  Working on a complex project
I found that the degree of opinion was so severe that I spent too much time fighting with the CI server and how they
wanted to structure my builds and my pipelines.  So, in frustration, I dumped the CI servers and went back to
basics - cron and a set of bash and ruby scripts with the tasks that make up the pipeline contained within the project
itself rather than being hidden away in a CI tool.

Structuring a Project
---------------------

To allow a project to work with this tool it is necessary to create a directory in the project's root called

    ci-pipeline/

and, within that directory, two further directories:

    tasks/
    logs/

The tasks directory is then populated with a collection of shell scripts that are executed by the pipeline in a order of
sequence.  The convention that I use is to number each script 001, 002, 003, ... so that I can then re-arrange as and
when.  Further to that each script can be called with an info parameter which requires the script to describe itself.
The first line in the description has the format

    name: textual description

Where the name is the human understandable name of the script and the description is a little about how the script works.
A script can accept parameters via the shell environment.  These named parameters should also be described using the format

    PARAM: param name: type: description

The following is an example of a script:

    #!/bin/bash
    case "$1" in
        "")
            if [ "$PUSH_BRANCH" = "true" ]
            then
                git config --global push.default matching
                git add pom.xml
                git add pom.xml.versionsBackup
                git commit -m "Updated POM with release candidate's version number"
                git push -u origin `git status | grep "On branch" | cut -d " " -f 3`
            else
                echo "Failed: the variable PUSH_BRANCH is not present and set to true."
                exit 1
            fi
            ;;
        "info")
            echo "Push Release Candidate Branch: Adds the updated pom and backup pom into git and pushed these changes through to the remote git repo."
            echo "PARAM: PUSH_BRANCH: boolean: Will execute only if this parameter is present and set to 'true'"
            ;;
    esac


Installing Basic-IC
-------------------

Given that the application is under development I have not you properly packaged Basic-CI making it a one-touch deployment - if
anyone wants to help
me with this please get in touch.
After cloning the project you will need to install the necessary ruby gems and then install the necessary to Javascript
libraries.

Assuming that you have Ruby 2 and bower installed the following set of commands will do the trick:

    git clone https://github.com/graeme-lockley/basic-ci.git
    cd basic-ci/app
    bundle
    cd data
    bower install

Now you need to setup your PATH to include the two commands

    ci-pipeline.rb
    ci-webapp.rb

which execute your pipeline and provide a set of REST services and a simple browser app to inspect your pipelines.

To add these commands to your path, execute the following from your project home directory:

    cd app/bin
    export PATH=$PATH:`pwd`

