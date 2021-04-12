# Active Elastic Job

[![Build Status](https://github.com/active-elastic-job/active-elastic-job/workflows/Build/badge.svg)](https://github.com/active-elastic-job/active-elastic-job/actions)
[![Gem Version](https://badge.fury.io/rb/active_elastic_job.svg)](https://badge.fury.io/rb/active_elastic_job)

You have your Rails application deployed on the [Amazon Elastic Beanstalk](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/Welcome.html) platform and now your application needs to offload work—like sending emails—into asynchronous background jobs. Or you want to perform jobs periodically similar to cron jobs. Then Active Elastic Job is the right gem. It provides an adapter for Rails' [Active Job](http://guides.rubyonrails.org/active_job_basics.html) framework that allows your application to queue jobs as messages in an [Amazon SQS](https://aws.amazon.com/sqs/) queue. Elastic Beanstalk provides [worker environments](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html) that automatically pull messages from the queue and transforms them into HTTP requests. This gem knows how to handle these requests. It comes with a [Rack](http://rack.github.io/) middleware that intercepts these requests and transforms them back into jobs which are subsequently executed.

![Architecture Diagram](/docs/architecture.png?raw=true "Architecture Diagram")

## Why use this gem?
  * It is easy to setup.
  * It makes your application ready for worker environments that are highly integrated in the Elastic Beanstalk landscape.
  * It is based on Amazon SQS, a fast, fully managed, scaleable, and reliable queue service. You do not need to operate and maintain your custom-messaging cluster.
  * It is easy to deploy. You simply push your application code to a worker environment, the same way that you push your application code to your web environment.
  * It scales. The worker environments come with auto-scale capability. Additional worker instances will spawn automatically and process jobs from the queue if the load increases above a preconfigured threshold.

## Usage

1. Add this line to your application's Gemfile:

        gem 'active_elastic_job'

2. Create an SQS queue:
  * Log into your Amazon Web Service Console and select _SQS_ from the services menu.
  * Create a new queue. Select a name of choice but do not forget to use the **same name** in your Active Job class definition.

    ```Ruby
    class YourJob < ActiveJob::Base
      queue_as :name_of_your_queue
    end
    ```

    Also use that **same name** in your Action Mailer configuration (if you send emails in background jobs):

    ```Ruby
    # config/application.rb
    module YourApp
      class Application < Rails::Application
        config.action_mailer.deliver_later_queue_name = :name_of_your_queue
      end
    end
    ```
  * Choose a visibility timeout that exceeds the maximum amount of time a single job will take.
3. Give your EC2 instances permission to send messages to SQS queues:
  * Stay logged in and select the _IAM_ service from the services menu.
  * Select the _Roles_ submenu.
  * Find the role that you select as the instance profile when creating the Elastic Beanstalk web environment:
  ![Instance Profile](/docs/instance_profile.png?raw=true "Architecture Diagram")
  * Attach the **AmazonSQSFullAccess** policy to this role.
  * Make yourself familiar with [AWS Service Roles, Instance Profiles, and User Policies](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts-roles.html).
4. Tell the gem the region of your SQS queue that you created in step 2:
  * Select the web environment that is currently hosting your application and open the _Software Configuration_ settings.
  * Add **AWS_REGION** and set it to the _region_ of the SQS queue, created in Step 2.

5. Create a worker environment:
  * Stay logged in and select the _Elastic Beanstalk_ option from the services menu.
  * Select your application, click the _Actions_ button and select **Launch New Environment**.
  * Click the **create worker** button and select the identical platform that you had chosen for your web environment.
  * In the _Worker Details_ form, select the queue, that you created in Step 2, as the worker queue, and leave the MIME type to `application/json`. The visibility timeout setting should exceed the maximum time that you expect a single background job will take. The HTTP path setting can be left as it is (it will be ignored).

6. Configure the worker environment for processing jobs:
  * Select the worker environment that you just have created and open the _Software Configuration_ settings.
  * Add **PROCESS_ACTIVE_ELASTIC_JOBS** and set it to `true`.
7. Configure Active Elastic Job as the queue adapter.

    ```Ruby
    # config/application.rb
    module YourApp
      class Application < Rails::Application
        config.active_job.queue_adapter = :active_elastic_job
      end
    end
    ```
8. Verify that both environments—web and worker—have the same secret base key:
  * In the _Software Configuration_ settings of the web environment, copy the value of the **SECRET_KEY_BASE** variable.
  * Open the _Software Configuration_ settings of the worker environment and add the **SECRET_KEY_BASE** variable. Paste the value from the web environment, so that both environments have the same secret key base.

9. Deploy the application to both environments (web and worker).

## Set up periodic tasks (cron jobs)

Elastic beanstalk worker environments support the execution of
[periodic tasks](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html#worker-periodictasks)
similar to cron jobs. We recommend you to make yourself familiar with Elastic Beanstalks' [official doumentation](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html#worker-periodictasks) first.

You don't need this gem to make use of Elastic Beanstalk's periodic tasks feature, however, this gem takes care of intercepting the POST requests from
the SQS daemon (explained in the [official documentation](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html#worker-periodictasks)).
If the gem detects a POST request from the daemon caused by a periodic task definition, then the gem will create a corresponding Active Job instance and trigger the execution.
To make use of the gem, just follow these conventions when writing your definition of the perdiodic tasks in `cron.yaml`:

* Set `name` to the class name the of the (ActiveJob) job that should be performed.
* Set `url` to `/periodic_tasks`.

This is an example of a `cron.yaml` file which sets up a periodic task that is executed at 11pm UTC every day.
The `url` setting leads to requests which will be intercepted by the gem.
It then looks at the `name` setting, passed as a request header value by the SQS daemon, and instantiates a `PeriodicTaskJob` job object.
Subsequently it triggers its execution by calling the `#perform_now` method.

  ```Yaml

  version: 1
  cron:
   - name: "PeriodicTaskJob"
     url: "/periodic_tasks"
     schedule: "0 23 * * *"
  ```

## FIFO Queues

FIFO (First-In-First-Out) queues are designed to enhance messaging between applications when the order of operations and
events is critical, or where duplicates can't be tolerated. FIFO queues also provide exactly-once processing but have a
limited number of transactions per second (TPS).

The message group id will be set to the job type, and the message deduplication id will be set to the job id.

Note: Periodic tasks don't work for worker environments that are configured with Amazon SQS FIFO queues.

## Optional configuration
This gem is configurable in case your setup requires different settings than the defaults.
The snippet below shows the various configurable settings and their defaults.

  ```Ruby
  Rails.application.configure do
    config.active_elastic_job.process_jobs = ENV['PROCESS_ACTIVE_ELASTIC_JOBS'] == 'true'
    config.active_elastic_job.aws_credentials = lambda { Aws::InstanceProfileCredentials.new } # allows lambdas for lazy loading
    config.active_elastic_job.aws_region # no default
    config.active_elastic_job.secret_key_base = Rails.application.secrets[:secret_key_base]
    config.active_elastic_job.periodic_tasks_route = '/periodic_tasks'.freeze
  end
  ```

If you don't want to provide AWS credentials by using EC2 instance profiles, but via environment variables, you can do so:
  ```Ruby
  Rails.application.configure do
    config.active_elastic_job.aws_credentials = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  end
  ```

## Suggested Elastic Beanstalk configuration

### Extended Nginx read timeout
By default, Nginx has a read timeout of 60 seconds. If a job takes more than 60 seconds to complete, Nginx will close the connection making AWS SQS think the job failed. However, the job will continue running until it completes (or errors out), and SQS will re-queue the job to be processed again, which typically is not desirable.

The most basic way to make this change is to simply add this to a document within `nginx/conf.d`:

```
fastcgi_read_timeout 1800; # 30 minutes
proxy_read_timeout 1800; # 30 minutes
```

However, one of the best parts about `active-elastic-job` is that you can use the same code base for your web environment and your worker environment. You probably don't want your web environment to have a `read_timeout` longer than 60 seconds. So here's an Elastic Beanstalk configuration file to only add this to your worker environments.

#### Amazon Linux 2

`.platform/hooks/predeploy/nginx_read_timeout.sh`
```
#!/usr/bin/env bash
set -xe

if [ $PROCESS_ACTIVE_ELASTIC_JOBS ]
then
  cat >/var/proxy/staging/nginx/conf.d/read_timeout.conf <<EOL
fastcgi_read_timeout 1800;
proxy_read_timeout 1800;
EOL
fi
```

#### Pre-Amazon Linux 2

Coming soon


## FAQ
A summary of frequently asked questions:
### What are the advantages in comparison to popular alternatives like Resque, Sidekiq or DelayedJob?
You decided to use Elastic Beanstalk because it facilitates deploying and operating your application. Active Elastic Job embraces this approach and keeps deployment and maintenance simple. To use Resque, Sidekiq or DelayedJob as a queuing backend, you would need to setup at least one extra EC2 instance that runs your queue application. This complicates deployment. Furthermore, you will need to monitor your queue and make sure that it is in a healthy state.
### Can I run Resque or DelayedJob in my web environment which already exists?
It [is](http://junkheap.net/blog/2013/05/20/elastic-beanstalk-post-deployment-scripts/) [possible](http://www.dannemanne.com/posts/post-deployment_script_on_elastic_beanstalk_restart_delayed_job) but not recommended. Your jobs will be executed on the same instance that is hosting your web server, which handles your users' HTTP requests. Therefore, the web server and the worker processes will fight for the same resources. This leads to slower responses of your application. But a fast response time is actually one of the main reasons to offload tasks into background jobs.
### Is there a possibility to prioritize certain jobs?
Amazon SQS does not support prioritization. In order to achieve faster processing of your jobs you can add more instances to the worker environment or create a separate queue with its own worker environment for your  high-priority jobs.
### Can jobs be delayed?
You can schedule jobs not more than **15 minutes** into the future. See [the Amazon SQS API reference](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html). If you need to postpone the execution of a job further into the future, then consider the possibility of setting up a periodic task.
### Can I monitor and inspect failed jobs?
Amazon SQS provides [dead-letter queues](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/SQSDeadLetterQueue.html). These queues can be used to isolate and sideline unsuccessful jobs.
### Is my internet-facing web environment protected against being spoofed into processing jobs?
The Rails application will treat requests presenting a user agent value `aws-sqsd/*`
  as a request from the SQS daemo; therefore, it tries to un-marshal the request body back into a job object for further execution. This adds a potential attack vector since anyone can fabricate a request with this user agent and, therefore, might try to spoof the application into processing jobs or even malicious code. This gem takes several counter-measures to block the attack vector.
   * The middleware that processes the requests from the SQS daemon is disabled per default. It has to be enabled deliberately by setting the environment variable **PROCESS_ACTIVE_ELASTIC_JOBS**  to `true`, as instructed in the [Usage](#usage) section.
   * Messages that represent the jobs are signed before they are enqueued. The signature is verified before the job is executed. This is the reason both environments-web and worker-need to have the same value for the environment variable **SECRET_KEY_BASE** (see the [Usage](#usage) section Step 7) since the secret key base will be used to generate and verify the signature.
   * Only requests that originate from the same host (localhost) are considered to be requests from the SQS daemon. SQS daemons are installed in all instances running in a worker environment and will only send requests to the application running in the same instance.
Because of these safety measures it is possible to deploy the same codebase to both environments, which keeps the deployment simple and reduces complexity.

### Can jobs get lost?
Active Elastic Job will raise an error if a job has not been sent successfully to the SQS queue. It expects the queue to return an MD5 digest of the message contents, which it verifies for correctness. Amazon advertises SQS to be reliable and messages are stored redundantly. If a job is not executed successfully, the corresponding message become visible in the queue again. Depending on the queue's setting, the worker environment will pull the message again and an attempt will be made to execute the jobs again.

### What can be the reason if jobs are not executed?

Inspect the log files of your worker tier environment. It should contain entries for the requests that are performed
by the AWS SQS daemon. Look out for POST requests from user agents starting with `aws-sqsd/`. If the log does not
contain any, then make sure that there are messages enqueued in the SQS queue which is attached to your worker tier. You can do this from
your AWS console.

When you have found the requests, check their response codes which give a clue on why a job is not executed:

* status code `500`: something went wrong. The job might have raised an error.
* status code `403`: the request seems to originate from another host than `localhost` or the message which represents the job has not been verified successfully. Make sure that both environment, web and worker, use the same `SECRET_KEY_BASE`.
* status code `404` or `301`: the gem is not included in the bundle, or the `PROCESS_ACTIVE_ELASTIC_JOBS` is **not** set to `true` (see step 6) in the worker environment or the worker environment uses an outdated platform which uses the AWS SQS daemon version 1. Check the user agent again, if it lookes like this `aws-sqsd/1.*` then it uses the old version. This gem works only for daemons version 2 or newer.


## Bugs - Questions - Improvements

Whether you catch a bug, have a question or a suggestion for improvement, I sincerely appreciate any feedback. Please feel free to [create an issue](https://github.com/active-elastic-job/active-elastic-job/issues/new) and I will follow up as soon as possible.


## Contribute

Running the complete test suite requires to launch elastic beanstalk environments. Travis builds triggered by a pull request will launch the needed elastic beanstalk environments and subsequently run the complete test suite. You can run all specs that do not depend on running elasitic beanstalk environments by setting an environment variable:
 ```bash
EXCEPT_DEPLOYED=true bundle exec rspec spec
```
Feel free to issue a pull request, if this subset of specs passes.

### Development environment with Docker

We recommend to run the test suite in a controlled and predictable envrionment. If your development machine has [Docker](https://www.docker.com/) installed, then you can make use of the Dockerfile that comes with this package. Build an image and run tests in container of that image.

```bash
docker build -t active-elastic-job-dev .
docker run -e EXCEPT_DEPLOYED=true -v $(pwd):/usr/src/app active-elastic-job-dev bundle exec rspec spec
```
