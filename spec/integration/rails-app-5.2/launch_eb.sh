#!/usr/bin/env bash

eb create -v -s  -c active-elastic-job web-env # Omitting -t web is the only way to make tier web
eb create -v -t worker -s  worker-env
eb setenv -e web-env SECRET_KEY_BASE=secret AWS_REGION=us-east-1
eb setenv -e worker-env SECRET_KEY_BASE=secret AWS_REGION=us-east-1 WEB_ENV_HOST=active-elastic-job.us-east-1.elasticbeanstalk.com WEB_ENV_PORT=443 PROCESS_ACTIVE_ELASTIC_JOBS=true
aws elasticbeanstalk restart-app-server --environment-name web-env
aws elasticbeanstalk restart-app-server --environment-name worker-env
sleep 15 # Only way I know to be sure the app has restarted before moving on
