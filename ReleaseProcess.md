# Release process (DRAFT)

## Objectives

As identified in [issue 76](https://github.com/tawan/active-elastic-job/issues/76) releases came to a halt which raised the question if the project has been abandoned.
At that time, a new version was tested with a suite of integration test prior release.
The single maintainer was not using this project in production at that time, therefore the maintainer needed to run the integration tests in order to have confidence in the stability of a new version. These integration tests depended on manually creating resources in an AWS account, which was time consuming at slowed down the pace new releases with important changes.

This new process intends to remove the bottleneck of having one single maintainer running integration test, but without sacrificing stability of new released version.
The new process should allow faster integration of patches and new features.

## Characteristics

Release
* small incremental changes,
* often,
* stable versions which have been tested in production on at least one platform (Ruby version),
* in compliance with Semantic Versioning 2.0.0.


## Workflow

1. A new pull request is tested with a test suite, smoke tests, that does not depend on any external resource and can be executed by a Travis build.
1. A new pull request is merged when it passes the smoke tests.
1. After three pull requests have been merged, or if one month after the latest merge has passed, which ever comes first, an alpha version is tagged and released.
1. The alpha version is used in production by at least one project for a week.
1. If no issues surfaced, the version is tagged and released.
1. If issues are discovered, the path level is bumped and a new alpha version is released and tested for a week in production.
