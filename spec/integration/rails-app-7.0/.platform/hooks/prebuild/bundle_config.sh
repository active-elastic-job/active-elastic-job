#!/bin/bash
set -xe

sudo su - -c "cd /var/app/staging; \
bundle config set --local force_ruby_platform true; \
bundle config set --local build.nokogiri \"--use-system-libraries\";"
