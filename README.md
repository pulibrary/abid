# AbID Application
[![CircleCI](https://circleci.com/gh/pulibrary/abid.svg?style=svg)](https://circleci.com/gh/pulibrary/abid)
[![Apache 2.0 License](https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=plastic)](./LICENSE)

Generates Absolute Identifiers for physical organization of materials on shelves
for Princeton University Library and handles synchronization of those to
ArchivesSpace.

### Development

#### Dependencies Setup
* Install Lando from https://github.com/lando/lando/releases (at least 3.x)
* See .tool-versions for language version requirements (ruby, nodejs)

```sh
bundle install
yarn install
```
(Remember you'll need to run the above commands on an ongoing basis as dependencies are updated.)

#### Credentials setup
* Install the necessary environment variables for accessing ArchivesSpace:

```sh
lpass login YOURNETID@princeton.edu
rake setup_keys
```

#### Starting / stopping services
We use lando to run services required for both test and development environments.

Start and initialize database services with `rake servers:start`

To stop database services: `rake servers:stop` or `lando stop`

#### Run tests
`bundle exec rspec`

#### Start development server
- `bundle exec rails s`
- Access application at http://localhost:3000/
