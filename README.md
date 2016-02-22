# Active Elastic Job

[![Build Status](https://travis-ci.org/tawan/active-elastic-job.svg)](https://travis-ci.org/tawan/active-elastic-job)
[![Gem Version](https://badge.fury.io/rb/active_elastic_job.svg)](https://badge.fury.io/rb/active_elastic_job)

You have your Rails application deployed on the [Amazon Elastic Beanstalk](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/Welcome.html) platform and now your application needs to offload work—like sending emails—into asynchronous background jobs. Then Active Elastic Job is the right gem. It provides an adapter for Rails' [Active Job](http://guides.rubyonrails.org/active_job_basics.html) framework that allows your application to queue jobs as messages in an [Amazon SQS](https://aws.amazon.com/sqs/) queue. Elastic Beanstalk provides [worker environments](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html) that automatically pull messages from the queue and transforms them into HTTP requests. This gem knows how to handle these requests. It comes with a [Rack](http://rack.github.io/) middleware that intercepts these requests and transforms them back into jobs which are subsequently executed.
![Architecture Diagram](/docs/architecture.png?raw=true "Architecture Diagram" =20x20)

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
  * Choose a visibility timeout that exceeds the maximum amount of time a single job will take.
3. Create a new user with SQS permissions:
  * Stay logged in and select the _IAM_ service from the services menu.
  * Create a new user and store the credentials.
  * Attach the **AmazonSQSFullAccess** policy to this user.
4. Add four environment variables to the web environment
  * Select the web environment that is currently hosting your application and open the _Software Configuration_ settings.
    * Add **AWS_ACCESS_KEY_ID** and set it to _access key id_ of the newly created user (from Step 3).
    * Add **AWS_SECRET_ACCESS_KEY** and set it to the _secret access key_ of the newly created user (from Step 3).
    * Add **AWS_REGION** and set it to the _region_ of the SQS queue, created in Step 2.
    * Add **DISABLE_SQS_CONSUMER** and set it to `true`.
5. Create a worker environment:
  * Stay logged in and select the _Elastic Beanstalk_ option from the services menu.
  * Select your application, click the _Actions_ button and select **Launch New Environment**.
  * Click the **create worker** button and select the identical platform that you had chosen for your web environment.
  * In the _Worker Details_ form, select the queue, that you created in Step 2, as the worker queue, and leave the MIME type to `application/json`. The visibility timeout setting should exceed the maximum time that you expect a single background job will take. The HTTP path setting can be left as it is (it will be ignored).
6. Configure Active Elastic Job as the queue adapter.

  ```Ruby
  # config/application.rb
  module YourApp
    class Application < Rails::Application
      config.active_job.queue_adapter = :active_elastic_job
    end
  end
  ```
7. Verify that both environments—web and worker—have the same secret base key:
  * In the _Software Configuration_ settings of the web environment, copy the value of the **SECRET_KEY_BASE** variable.
  * Open the _Software Configuration_ settings of the worker environment and add the **SECRET_KEY_BASE** variable. Paste the value from the web environment, so that both environments have the same secret key base.

8. Deploy the application to both environments (web and worker).

## FAQ
A summary of frequently asked questions:
### What are the advantages in comparison to popular alternatives like Resque, Sidekiq or DelayedJob?
You decided to use Elastic Beanstalk because it facilitates deploying and operating your application. Active Elastic Job embraces this approach and keeps deployment and maintenance simple. To use Resque, Sidekiq or DelayedJob as a queuing backend, you would need to setup at least one extra EC2 instance that runs your queue application. This complicates deployment. Furthermore, you will need to monitor your queue and make sure that it is in a healthy state.
### Can I run Resque or DelayedJob in my web environment which already exists?
It [is](http://junkheap.net/blog/2013/05/20/elastic-beanstalk-post-deployment-scripts/) [possible](http://www.dannemanne.com/posts/post-deployment_script_on_elastic_beanstalk_restart_delayed_job) but not recommended. Your jobs will be executed on the same instance that is hosting your web server, which handles your users' HTTP requests. Therefore, the web server and the worker processes will fight for the same resources. This leads to slower responses of your application. But a fast response time is actually one of the main reasons to offload tasks into background jobs.
### Is there a possibility to prioritize certain jobs?
Amazon SQS does not support prioritization. In order to achieve faster processing of your jobs you can add more instances to the worker environment or create a separate queue with its own worker environment for your  high-priority jobs.
### Can jobs be delayed?
You can schedule jobs not more than **15 minutes** into the future. See [the Amazon SQS API reference](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html).
### Can I monitor and inspect failed jobs?
Amazon SQS provides [dead-letter queues](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/SQSDeadLetterQueue.html). These queues can be used to isolate and sideline unsuccessful jobs.
### Is my internet-facing web environment protected against being spoofed into processing jobs?
The Rails application will treat requests presenting a user agent value `aws-sqsd/*`
  as a request from the SQS daemo; therefore, it tries to un-marshal the request body back into a job object for further execution. This adds a potential attack vector since anyone can fabricate a request with this user agent and, therefore, might try to spoof the application into processing jobs or even malicious code. This gem takes several counter-measures to block the attack vector.
   * The middleware that processes the requests from the SQS daemon is disabled in the web environment, but only if the environment variable **DISABLE_SQS_CONSUMER** has `true` as its setting, as instructed in the [Usage](#usage) section.
   * Messages that represent the jobs are signed before they are enqueued. The signature is verified before the job is executed. This is the reason both environments-web and worker-need to have the same value for the environment variable **SECRET_KEY_BASE** (see the [Usage](#usage) section Step 7) since the secret key base will be used to generate and verify the signature.
   * Only requests that originate from the same host (localhost) are considered to be requests from the SQS daemon. SQS daemons are installed in all instances running in a worker environment and will only send requests to the application running in the same instance.
Because of these safety measures it is possible to deploy the same codebase to both environments, which keeps the deployment simple and reduces complexity.

### Can jobs get lost?
Active Elastic Job will raise an error if a job has not been sent successfully to the SQS queue. It expects the queue to return an MD5 digest of the message contents, which it verifies for correctness. Amazon advertises SQS to be reliable and messages are stored redundantly. If a job is not executed successfully, the corresponding message become visible in the queue again. Depending on the queue's setting, the worker environment will pull the message again and an attempt will be made to execute the jobs again.

## Bugs - Questions - Improvements

Whether you catch a bug, have a question or a suggestion for improvement, I sincerely appreciate any feedback. Please feel free to [create an issue](https://github.com/tawan/active-elastic-job/issues/new) and I will follow up as soon as possible.


## Contribute
1. Fork
1. Commit
1. Issue a pull request
