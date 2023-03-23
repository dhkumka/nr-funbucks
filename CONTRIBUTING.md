# Contributing

Document the process to work on funbucks for new server fluentbit configuration

# Pre-Requisites:

    WSL
    Git bash and GUI app
    Visual Studio Code


# Setup FUNBUCKS repo 

1. Clone funbucks : https://github.com/bcgov-nr/nr-funbucks

    Command: git clone https://github.com/bcgov-nr/nr-funbucks.git

2. branch it first

    Command: git checkout -b feat/newbranchname

3. Do the code change, commit and publish the change repo

    - Add/Modify servername.json file in https://github.com/bcgov-nr/nr-funbucks/tree/main/config/server
    For example: 

        * Proxy server type: backup.json
        * Tomcat server type: between.json 
        * Other application server type: WSO2 translate.json, refactor.json

    - Modify/Add new line for the server in https://github.com/bcgov-nr/nr-funbucks/blob/main/scripts/fluentbit_agents.csv, the list will pop in the parameter list in Jenkins deployment jobs 

    - Add fluentbit monitor job for the new server in the OpenSearch, follow the instruction on [Confluence page : create monitor via Terraform in nr-apm-stack](https://apps.nrs.gov.bc.ca/int/confluence/display/EPSILON/nr-apm-stack)

4. New pull request(PR) will appear in https://github.com/bcgov-nr/nr-funbucks/pulls

    - Command: git remote add stash https://user.name%40gov.bc.ca@bwa.nrs.gov.bc.ca/int/stash/scm/oneteam/oneteam-nr-funbucks.git
    
    Confirm there are two remote repo links (origin and stash):

        Command: git remote -v
        origin  https://github.com/bcgov-nr/nr-funbucks.git (fetch)
        origin  https://github.com/bcgov-nr/nr-funbucks.git (push)
        stash   https://bwa.nrs.gov.bc.ca/int/stash/scm/oneteam/oneteam-nr-funbucks.git (fetch)
        stash   https://bwa.nrs.gov.bc.ca/int/stash/scm/oneteam/oneteam-nr-funbucks.git (push)

5. Sync Github repo to Bitbucket stash repo

    Command: git push stash main

# Deploy fluentbit to a new server:
    
    Run Jenkins job: https://apps.nrs.gov.bc.ca/int/jenkins/job/FLUENTBIT/job/fluentbit-deploy/