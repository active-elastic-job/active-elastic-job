## [v1.4.0] - 2016-02-09
- Disable middleware that processes SQS daemon request with an environment variable
 - Closes [issue #12](https://github.com/tawan/active-elastic-job/issues/12)
- Check if SQS daemon request originates from localhost
 - Closes [issue #13]((https://github.com/tawan/active-elastic-job/issues/13)

## [v1.3.2] - 2016-02-08
- Fix worker environments running Puma servers. Remove underscore from header.
 - Close [issue #15](https://github.com/tawan/active-elastic-job/issues/15)
## [v1.3.1] - 2016-02-07

- Fix backwards incompatibility
 - Refers to [issue #10](https://github.com/tawan/active-elastic-job/issues/10)

- [Performance improvements](https://github.com/tawan/active-elastic-job/commit/1f1c72d6d10a3e0c42ad305b29afb1d55fcb2561)

## [v1.3.0] - 2016-02-06

- Verify MD5 hashes responses from SQS API
 - Closes issue [issue #4](https://github.com/tawan/active-elastic-job/issues/4)

- Cache queue urls
 - Closes issue [issue #3](https://github.com/tawan/active-elastic-job/issues/3)

- Avoid interfering with other aws-sqsd requests
 - Closes issue [issue #9](https://github.com/tawan/active-elastic-job/issues/9)
