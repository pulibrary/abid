# AbID Application
[![CircleCI](https://circleci.com/gh/pulibrary/abid.svg?style=svg)](https://circleci.com/gh/pulibrary/abid)
[![Apache 2.0 License](https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=plastic)](./LICENSE)

Generates Absolute Identifiers for physical organization of materials by shelving size 
for Princeton University Library and handles synchronization of those to
ArchivesSpace.

AbIDs allow us to organize boxes by their size and their location.  AbIDs are not unique across the
institution, but they are unique at a particular site (e.g. Mudd and Firestone could each have a
box with the same ABID "S001", but Firestone could not have two boxes for the same ABID).

### Typical use case

1. A user creates container records in aspace.  These records contain placeholder box numbers, not AbIDs.
1. They enter the following info into this abid application:
   - the first barcode they have in their hand
   - the numbers from the first and last boxes in their batch
   - the EAD id (call number), like C0140.
   - the shelving size (aka container profile) -- since you want to group boxes of similar sizes together
   - the location (Mudd vs Firestone)
1. The application creates the sequential AbIDs.
1. In this app, the user "syncronizes" the AbIDs, which adds them to aspace.  This overwrites the placeholder
box numbers.

### Book use case

This application can also be used for books, and the AbIDs get written back to Alma.  The AbID application
can also provide the data from which book spine labels can be printed.

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
- Ensure you're on VPN or the part of the login process where you connect to
    aspace will not work
- Access application at http://localhost:3000/
