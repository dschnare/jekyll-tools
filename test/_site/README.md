# Overview

This is a simple test using the Jekyll Tools plugins.

# Setup

Before you can setup this project you must have the following installed:

- [Ruby](http://www.ruby-lang.org/)
- [Node with NPM](http://nodejs.org/)
- [Bundler gem](http://gembundler.com/)

Once the above requirements are installed then you can run the following:

1. Install `jekyll` and `uglifier`:

	bundle

2. Install `less` as a NPM package:

	npm install


*NOTE:*

If you're familiar with NPM and the `node_modules` directory it places all locally installed modules you'll notice that after installing there is no `node_modules` in this project's directory. This is because the `package.json` file contains scripts to move the `node_modules` directory to `_assets/node_modules`.
