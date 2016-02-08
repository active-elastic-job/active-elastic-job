# Active Elastic Job

[![Build Status](https://travis-ci.org/tawan/active-elastic-job.svg)](https://travis-ci.org/tawan/active-elastic-job)
[![Gem Version](https://badge.fury.io/rb/active_elastic_job.svg)](https://badge.fury.io/rb/active_elastic_job)

Active Elastic Job is a simple queuing backend implementation, targeting Rails >= 4.2 applications running on the
[Amazon Elastic Beanstalk](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/Welcome.html) platform. It provides an
adapter for Rails' [Active Job](http://guides.rubyonrails.org/active_job_basics.html) framework and a [Rack](http://rack.github.io/) middleware to consume messages pulled by the SQS daemon running in Elastic Beanstalk [worker environments](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html).

This gem allows Rails applications which run in Elastic Beanstalk environments to offload long running tasks into background jobs by simply
* adding this gem to the bundle,
* creating an [Amazon SQS](https://aws.amazon.com/de/sqs/) queue,
* creating a [worker environment](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html)
* configuring Active Elastic Job as the queue adapter,
* deploying the updated application (identical versions) to web and the worker environments.

## Why use this gem?
You decided to deploy your Rails application to Amazon Elastic Beanstalk because
it makes deployment as easy as pushing a button. You don't need to configure load balancers,
setup monitoring and everything scales automatically.

Your application now incorporates several long running operations which make the user waiting for the response often unnecessarily. You want to offload the long running tasks into background jobs. There are [several alternatives](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html) which provide this functionality that you can choose from.

However, using one of these options makes deployment difficult (you will need to setup an additional EC2 instance and also deploy your application to it) and demands continuos maintenance. But a simple deployment and low maintenance burden were to actual reasons to use Elastic Beanstalk. You can try to circumvent the need for an extra instance by starting the background job process in your Elastic Beanstalk web instances, as apparently [many](http://junkheap.net/blog/2013/05/20/elastic-beanstalk-post-deployment-scripts/) [others](http://www.dannemanne.com/posts/post-deployment_script_on_elastic_beanstalk_restart_delayed_job) do. But this approach is rather a hack and suboptimal. The worker processes and your web server will fight for the same resources, since now they are running in the same instance. Consequently, your web server will response slower to your users, but that's what you actually wanted to avoid with a background solution.

### Active Elastic Job to the rescue
Active Elastic Job keeps deployment and maintenance simple. It allows your application to be deployed on both, Elastic Beanstalk web and worker environments, which are essentially
identical, but a worker environment can process messages from an [Amazon SQS](https://aws.amazon.com/de/sqs/) queue. An SQS is created with a few mouse clicks  and  can be connected to your worker environment simply by selecting it from a menu when creating the environment.

Originally, worker environments are intended to host a specialized version of your application, which is only responsible for processing jobs. But then you would have to keep two versions at hand, probably in two different branches or repositories - again, additional administrative burden.
Active Elastic Beanstalk, however, makes it possible to deploy the exact same version to both environments, which is a big win.

## Usage

1. Add this line to your application's Gemfile:

        gem 'active_elastic_job'

2. Create an SQS queue:
  * Log into your Amazon Web Service Console and select _SQS_ from the services menu.
  * Create a new queue. Select a name of choice but don't forget to use the **same name** in your Active Job class definition.

  ```Ruby
  class YourJob < ActiveJob::Base
    queue_as :name_of_your_queue
  end
  ```
3. Create a new user with SQS permissions:
  * Stay logged in and select the _IAM_ service from the services menu.
  * Create a new user and store the credentials.
  * Attach the **AmazonSQSFullAccess** policy to this user.
4. Create a worker environment:
  * Stay logged in and select the _Elastic Beanstalk_ option from the services menu.
  * Select your application, click the _Actions_ button and select **Launch New Environment**.
  * Click the **create worker** button, select the identical platform that you had chosen for your web environment.
  * In the _Worker Details_ form, select the queue, that you created in step 2, as the worker queue, leave the MIME type to application/json. The visibility timeout setting should exceed the maximum time that you expect a single background job will take. The HTTP path setting can be left as it is (it will be ignored).
5. Configure Active Elastic Job as the queue adapter:

  ```Ruby
  # config/application.rb
  module YourApp
    class Application < Rails::Application
      config.active_job.queue_adapter = :active_elastic_job
    end
  end
  ```
6. Add four environment variables to the web environment
  * Select the web environment that is currently hosting your application and open the _Software Configuration_ settings:
    * add **AWS_ACCESS_KEY_ID** and set it to _access key id_ of the newly created user (from step 3),
    * add **AWS_SECRET_ACCESS_KEY** and set it to the _secret access key_ of the newly created user (step 3),
    * add **AWS_REGION** and set it to the _region_ of the SQS queue, created in step 2,
    * add **DISABLE_SQS_CONSUMER** and set it to `true`.
7. Verify that both environments, web and worker, have the same secret base key
  * In the _Software Configuration_ settings of the web environment, copy the value of the `SECRET_KEY_BASE` variable,
  * open the _Software Configuration_ settings of the worker environment and add the `SECRET_KEY_BASE` variable. Paste the value from the web environment, so that both environments have the same secret key base.

8. Deploy the application to both environments (web and worker).

## Caveats
  * Jobs can not be scheduled more than **15 minutes** into the future, see [the Amazon SQS API reference](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html).
  * The rails application will treat requests presenting a user agent value `aws-sqsd/*`
  as a request from the SQS daemon and therefore tries to unmarshal the request body back into a job object for further execution. This adds a potential attack vector since anyone can fabricate a request with this user agent, and therefore might try to spoof the application into processing jobs or even malicious code. This gem takes several counter measures to block this attack vector.
   * The middleware that processes the requests from the SQS daemon is disabled in the web environment. (Only if the environment variable **DISABLE_SQS_CONSUMER** has been set to `true` as instructed in the Usage section!
   * Messages that represent the jobs are signed before they are enqueued. The signature is verified before the job is executed. This is the reason that both environments, web and worker, need to have the same value for the environment variable **SECRET_KEY_BASE** (see the Usage section step 7), since the secret key base will be used to generate and verify the signature.
   * Only requests that originate from the same host (localhost) are considered to be a request from the SQS daemon. SQS daemons are installed in all instances running in a worker environments and will only send requests to the application running in the same instance.


Because of this safety measures it is possible to deploy the same codebase to both environments, which keeps deployment simple and reduces complexity.
