#!/usr/bin/env bash

eb create -v -t web -s  -c active-elastic-job web-env
eb create -v -t worker -s  worker-env
eb setenv -e web-env SECRET_KEY_BASE=secret AWS_REGION=eu-central-1
eb setenv -e worker-env SECRET_KEY_BASE=secret AWS_REGION=eu-central-1 WEB_ENV_HOST=active-elastic-job.eu-central-1.elasticbeanstalk.com WEB_ENV_PORT=443 PROCESS_ACTIVE_ELASTIC_JOBS=true
