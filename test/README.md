# Overview

This is a simple test using the Jekyll Tools plugins.

# Layout

This project contains several new directories that are different than the typical Jekyll directories.

- `_assets` : Contains third-party code, various documents for the project, etc. This directory is mainly used for files that the `copy` plugin will copy from.
- `_src` : Contains source files meant for compilation such as JavaScript and Less files.

# Setup

Before you can setup this project you must have the following installed:

- [Git](http://git-scm.com/) : This is required so NPM can retrieve the lessjs module via git.
- [Ruby](http://www.ruby-lang.org/) : Required for Jekyll, plugins and Uglifier.
- [Node with NPM](http://nodejs.org/) : Required for installing lessjs and running the lessjs compiler.
- [Bundler gem](http://gembundler.com/) : Required for installing our gems.

Once the above requirements are installed then you can run the following:

1. Install `jekyll` and `uglifier`:

		bundle

2. Install `lessjs` as a NPM package:

		npm install


*NOTE:*

If you're familiar with NPM and the `node_modules` directory it places all locally installed modules you'll notice that after installing there is no `node_modules` in this project's directory. This is because the `package.json` file contains scripts to move the `node_modules` directory to `_assets/node_modules`.
