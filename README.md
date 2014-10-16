# Quickfix

A Mongoose (MongoDB) fixture loader and smart reloader.

Fixtures are small sets of data to test your application against. Quickfix loads your fixtures into your database.

To prevent creation/deletion of entire collections before/after every test case, Quickfix keeps track of all modifications against the database, then reverts each individual change to reach pristine condition.

Because modifications are logged and individually reverted, this is much faster than clearing and re-inserting the entire collection.

## Usage

The `Makefile` details how to run the test suite.

To see real examples, look in the `src/test` directory.

`src/test/helpers/*.coffee` has all the instructions to connect to the database.

`src/test/fixtures/*.coffee` contains example fixtures.

`src/test/*.coffee` are the actual tests.

## Features

- Collections can be split up into multiple files. Follow the format `collectionname.description.js`
- Handle multiple connections. The options are as follows:
  - All collections are inserted into the collection (and reset on population)
  - All collections are wiped from the connection (and re-wiped on population)

## Documentation

All code is documented in-file.

## License

Copyright (c) 2014 Seelio, Inc.

Licensed under ISC License.
