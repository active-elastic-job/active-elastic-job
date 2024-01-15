## [v.3.3.0] - 2024-01-15
 - Add Rails 7.x support (@zaru)
 - Add alternative docker check, adds support for AL2023 (@estromlund)

## [v.3.1.0] - 2021-10-21
 - Add support for generes SQSD daemons
 - Update various dependencies for security
 - Expand Docker detection to include Docker Compose bridge networking
 - Add support for FIFO queues

## [v.3.0.0] - 2021-02-22
 - Update to AWS SDK V3
 - Closes [issue #104](https://github.com/active-elastic-job/active-elastic-job/issues/104)
 - Drop support for Ruby <2.5
 - Drop support for Rails <5
 - Add support for Ruby 3
 - Add support for Rails 6
 - Replace TravisCI with GitHub Actions

## [v.2.0.1] - 2017-02-05
 - Closes [issue #51](https://github.com/active-elastic-job/active-elastic-job/issues/51) Lazy loading of AWS credentials in order to prevent slowing down of Rails start up time.

## [v.2.0.0] - 2016-11-27
 - Closes [issue #40](https://github.com/active-elastic-job/active-elastic-job/issues/40) Thanks to @masonjeffreys for the inspiration.
 - Makes processing of jobs opt-in per default.
 - Simplifies set up by using AWS instance profiles per default.

## [v.1.7.0] - 2016-11-05
 - Closes [issue #42](https://github.com/active-elastic-job/active-elastic-job/issues/42)
 - Closes [issue #33](https://github.com/active-elastic-job/active-elastic-job/issues/33)

## [v.1.6.3] - 2016-11-05
 - Closes [issue #41](https://github.com/active-elastic-job/active-elastic-job/issues/41)

## [v.1.6.1] - 2016-05-24
 - Closes [issue #35](https://github.com/active-elastic-job/active-elastic-job/issues/35)

## [v.1.6.0] - 2016-04-21
 - Support Docker environments
 - Closes [issue #26](https://github.com/active-elastic-job/active-elastic-job/issues/26)
 - Support common environment variable names
 - Closes [issue #31](https://github.com/active-elastic-job/active-elastic-job/issues/31)

## [v.1.5.0] - 2016-04-13
- Support Rails 5 applications
 - Closes [issue #28](https://github.com/active-elastic-job/active-elastic-job/issues/28)
 - Acknowledgments: Many thanks to Matt D from San Jose.

## [v1.4.4] - 2016-04-06
- Support Rails application configured to force SSL
 - Closes [issue #25](https://github.com/active-elastic-job/active-elastic-job/issues/25)

## [v1.4.3] - 2016-03-06
- Skip SQS MD5 digest verification if not necessary
 - Closes [issue #21](https://github.com/active-elastic-job/active-elastic-job/issues/21)

## [v1.4.2] - 2016-02-18
- Escalate errors to make debugging easier


## [v1.4.0] - 2016-02-09
- Disable middleware that processes SQS daemon request with an environment variable
 - Closes [issue #12](https://github.com/active-elastic-job/active-elastic-job/issues/12)
- Check if SQS daemon request originates from localhost
 - Closes [issue #13]((https://github.com/active-elastic-job/active-elastic-job/issues/13)

## [v1.3.2] - 2016-02-08
- Fix worker environments running Puma servers. Remove underscore from header.
 - Close [issue #15](https://github.com/active-elastic-job/active-elastic-job/issues/15)

## [v1.3.1] - 2016-02-07

- Fix backwards incompatibility
 - Refers to [issue #10](https://github.com/active-elastic-job/active-elastic-job/issues/10)

- [Performance improvements](https://github.com/active-elastic-job/active-elastic-job/commit/1f1c72d6d10a3e0c42ad305b29afb1d55fcb2561)

## [v1.3.0] - 2016-02-06

- Verify MD5 hashes responses from SQS API
 - Closes issue [issue #4](https://github.com/active-elastic-job/active-elastic-job/issues/4)

- Cache queue urls
 - Closes issue [issue #3](https://github.com/active-elastic-job/active-elastic-job/issues/3)

- Avoid interfering with other aws-sqsd requests
 - Closes issue [issue #9](https://github.com/active-elastic-job/active-elastic-job/issues/9)
