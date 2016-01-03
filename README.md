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

## Usage

1. Add this line to your application's Gemfile:

        gem 'active_elastic_job'

2. Create an SQS queue:
  * Log into your Amazon Web Service Console and select _SQS_ from the services menu,
  * Create a new queue.
3. Create a new user with SQS permissions:
  * Stay logged in and select the _IAM_ service from the services menu,
  * Create a new user and store the credentials,
  * Attach the **AmazonSQSFullAccess** policy to this user.
4. Create a worker environment:
  * Stay logged in and select the _Elastic Beanstalk_ option from the services menu,
  * Select your application, click the _Actions_ button and select **Launch New Environment**,
  * Click the **create worker** button, select the identical platform that you had chosen for your web environment,
  * Fill out the following forms and make sure to add three environment tags one you reached the **Environment Tags** form:
    * AWS_ACCESS_KEY_ID (_access key id from newly created user with SQS permissions_)
    * AWS_SECRET_ACCESS_KEY (_the secret access key of the newly created user_)
    * AWS_REGION (_region of the SQS queue_)
5. Configure Active Elastic Job as the queue adapter:

  ```Ruby
  # config/application.rb
  module YourApp
    class Application < Rails::Application
      # Be sure to have the adapter's gem in your Gemfile and follow
      # the adapter's specific installation and deployment instructions.
      config.active_job.queue_adapter = :active_elastic_job
    end
  end
  ```
6. Add three environment variables to the web environment
  * Select the web environment that is currently hosting your application and open the _Software Configuration_ settings,
  * Add the same three environment variables that you added in step 4 to the worker environment.
7. Create an Active Job class:

  ```Bash
  $ bin/rails generate job resize_image --queue [name of queue that you chose in step 2]
  invoke  test_unit
  create    test/jobs/resize_image_job_test.rb
  create  app/jobs/resize_image_job.rb
  ```
  This generated job looks like this:

  ```Ruby
  # app/jobs/resize_image_job.rb
  class ResizeImageJob < ActiveJob::Base
    queue_as :default # here should be the name of the queue that was created in step 2.

    def perform(image)
      ImageResizer.resize(image) # long running operation
    end
  end
  ```

  Enqueue the job by:

  ```Ruby
    ResizeImageJob.perform_later(image)
  ```
  Read more about Active Job in the [Active Job Basics Guide](http://guides.rubyonrails.org/active_job_basics.html).

8. Deploy the application to both (web and worker) environments.

## Caveats

  * Both environments need to have the same value for the environment variable `SECRET_KEY_BASE`!
  * Jobs can not be scheduled more than **15 minutes** into the future, see [the Amazon SQS API reference](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html).
