# Overview

**Supports Jekyll 1.0.0.beta3 and above.**

Jekyll Tools is a set of hook-driven Jekyll plugins that help 
automate common tasks such as compiling LESS files, combining and
minifying JS files and copying files to a destination of your choice.

Tools are 'required' by the Jekyll Tools plugin. Each tool is responsible for
performing a specific task and exposes hooks that can be overridden.

Hooks provide a convenient mechanism to override various stages of execution
of a tool. Hooks are functions with specific signatures contained within a
hook file. Hook files are found in a hooks directory, typically this directory
is `_hooks`.

# Dependencies

- [Git](http://git-scm.com/)
- [Ruby](http://www.ruby-lang.org/)
- [Node with NPM](http://nodejs.org/)

# Installation

Copy the `_plugins`, `_hooks` and `_tools` folders to your Jekyll project.

*NOTE: You can use the provided Gemfile and package.json to setup a new Jekyll project.*

Next ensure you have the following gems in your Gemfile:

- jekyll ~> 1.0.0.beta3
- os
- uglifier

Finally, if you intend on using the built-in hooks for CoffeeScript, TypeScript and/or LESS
compilation then be sure to create a `package.json` file with the following
dependencies:

- coffee-script
- typescript
- lessjs

Once you have all your dependencies setup then install them.

    npm install
    gem install bundler
    bundle install --path _bundle

To build your Jekyll project:

    bundle exec jekyll build



# Testing

To experiment with an example quickly, see the `test` directory.



# Documentation

To use Jekyll Tools you must have a `tools` hash in your `_config.yml` file
that has the following keys.

    tools: # The Jekyll Tools hash
      path: # The path to find the tools (defaults to _tools)
      defaults: # The hash containing defaults for each tool (optional)
      tasks: # The sequence of tasks containing a hash of tool settings for each tool to be called

Here's an exmple

```yaml
tools:
  path: _tools
  defaults:
    cssbuild:
      hooks: _hooks/cssbuild-less.rb
      lessc: node_modules/less/bin/lessc
  tasks:
    - cssbuild:
        css/main.min.css:
          main: _assets/less/main.less
          include:
            - _assets/less/*.less
            - { bootstrap: node_modules/bootstrap/less/*.less }
```

In this example notice that the `cssbuild` tool has `hooks` and `lessc` specified once
in the `defaults` for the tool. This reduces the need to repeat these keys whenever the
tool is used in the `tasks` sequence.


## Hooks

Hooks can optionally be specified for each of the tools in your `_config.yml` by using the `hooks`
key in the tool settings hash. If no hooks are specified then the tool employs a fallback that
typically acts as a nullop, so it's perfectly safe to not specify a hooks file.

When hooks are specified in your defaults hash and in your tool settings hash, then the hooks will
cascade. This means that if a hook is specified in your default hooks it doesn't have to be sepcified
in your setting hooks.

Look in the `_hooks` directory for documenation on the built-in hooks.



## Tools

### jsbuild

This tool will combine JavaScript files and optionally compile the combined file.
Compilation is determined by hooks specified in the `_config.yml` file. If there is
no `compile` hook then no compilation occurs.

Example settings:

```yaml
jsbuild:
  path/file.js: # Path relative to Jekyll destination setting of build target to create
    hooks: # Path to hooks file
    include: # Sequence of JS files to combine and compile (can be glob patterns)
    exclude: # Sequence of JS files to exclude (can be glob patterns)
```

Or

```yaml
jsbuild:
  path/file.js: # Path relative to Jekyll destination setting of build target to create
    # Sequence of JS files to combine and compile (can be glob patterns)
```

**NOTE: The example below shows typical usage with the built-in TypeScript hooks**

Example: 

```yaml
tools:
  path: ../_tools
  defaults:
    jsbuild:
      hooks: ../_hooks/jsbuild.rb
  tasks:
    - jsbuild:
        "../_assets/js/some-framework.ts.js":
          hooks: _hooks/jsbuild-typescript.rb
          tsc: node_modules/typescript/bin/tsc.js
          include:
            - _assets/vendor/some-framework/module.ts
        js/main.min.js:
          - _assets/js/some-framework.ts.js
          - _assets/js/main.js
```

#### Hooks

- `pre_combine_file(file, file_content, settings)`
- `pre_compile(js, settings)`
- `compile(js, settings)`
- `post_compile(js, settings)`

See `_hooks/jsbuild.rb` for documentation and examples.


#### Template Usage

Jekyll Tools also creates a custom tag for generating random alpha-numeric strings.

    {% random_string %}
    {% random_string length %}

You can use this tag to generate a cache buster query parameter like so.

```liquid
<script type="text/javascript" src="/js/main.min.js?bust={% random_string %}"></script>
<script type="text/javascript" src="/js/main.min.js"></script>
```

---


### cssbuild

This tool compiles CSS stylesheets starting at a main stylesheet that
includes all dependent stylesheets. Compilation is determined by hooks specified
in the config.yml file. If there is no `compile` hook then no compilation occurs.


Example settings:

```yaml
cssbuild:
  path/file.js: # Path relative to Jekyll destination setting of build target to create
    hooks: # Path to hooks file
    main: # The main stylesheet that does the importing
    include: # Sequence of stylesheets to combine and compile (can be glob patterns)
    exclude: # Sequence of stylesheets to exclude (can be glob patterns)
```

The includes can be namespaced so that when importing the files can be referenced using the
namespace name. If an include file/pattern is namespaced then the matching file(s) are
copyied to a temporary directory under a directory with the same name as the namespace.
Otherwise the included files are left where they are.

**NOTE: The examples below show typical usage with the built-in LESS hooks**

Example:

```yaml
tools:
  path: _tools
  defaults:
    cssbuild:
      hooks: _hooks/cssbuild.rb
  task:
    - cssbuild:
        css/main.min.css:
          hooks: _hooks/cssbuild-less.rb
          main: _assets/less/main.less
          include:
            - _assets/less/*.less
            - { mynamespace: node_modules/bootstrap/less/*.less }
```

Then in the `_assets/less/main.less` file:

```less
@import "mynamespace/bootstrap"
@import "mynamespace/responsive"
// ... rest of file
```

Without namespaces then your includes must have unique file names otherwise
they will override each other when you attempt to import.

```yaml
tools:
  path: _tools
  defaults:
    cssbuild:
      hooks: _hooks/cssbuild-less.rb
  task:
    - cssbuild:
        css/main.min.css:
          main: _assets/less/main.less
          include:
            - _assets/less/*.less
            - node_modules/bootstrap/less/*.less
```

Your `main.less` file.

```less
@import 'bootstrap'     // Twitter Bootstrap's less files
@import 'responsive'    // Twitter Bootstrap's less files
@import 'code'          // Twitter Bootstrap's less files
@import 'mysite-mixins' // Your site's less files
@import 'mysite-common' // Your site's less files
// Have to be careful that you don't use a file name that is the
// same as a LESS file that already exists in Bootstrap.
```


#### Hooks

- `pre_compile(main_file, settings)`
- `compile(css, include_paths, settings)`
- `post_compile(css, settings)`

See `_hooks/cssbuild.rb` for documentation and examples. You can also take a look at
`_hooks/cssbuild-less.rb` for an example of a custom hook.



#### Template Usage

Jekyll Tools also creates a custom tag for generating random alpha-numeric strings.

    {% random_string %}
    {% random_string length %}

You can use this tag to generate a cache buster query parameter like so.

```liquid
<link rel="stylesheet" type="text/css" href="/css/main.min.css?bust={% random_string %}" />
<link rel="stylesheet" type="text/css" href="/css/main.min.css" />
```


---


### copy

The copy tool will copy files or directories to a directory relative to the 'destination' setting.

Example settings:

```yaml
copy:
  path/dir: # Path relative to Jekyll destination setting of copy target to create (can be a glob that matches directories but introduces new directories at end of path)
    hooks: # Path to hooks file
    preserve_dirs: # Boolean indicating wildcard directories should be maintained when copying
    include: # Sequence of files to copy (can be glob patterns)
    exclude: # Sequence of files to exclude (can be glob patterns)
```

Or

```yaml
copy:
  path/dir: # Path relative to Jekyll destination setting of copy target to create (can be a glob that matches directories but introduces new directories at end of path)
    # Sequence of files to copy (can be glob patterns)
```

If an include glob pattern contains `**/` then you can optionally preserve all recursively matched directories when copying.

Example:

```yaml
tools:
  path: _tools
  defaults:
    copy:
      hooks: _hooks/copy.rb
  tasks:
    - copy:
      page[0-9]/vendor:
        preserve_dirs: true
        includes:
          - node_modules/bootstrap/**/*.*
```

The above example will copy all files from Twitter bootstrap into
a `vendor/` directory under a directory of the form `page[0-9]` directly
under the `destination` directory. If `vendor/` does not exist then the
path will be created. Because `preserve_dirs` is set to true however,
the directories under `node_modules/bootstrap` will be copied over under
the copy target. If `preserve_dirs` was not set or was set to false then only
the files themselves would be copied to the copy target.



#### Hooks

- `copy_file(source_file, dest_file)`

See `_hooks/copy.rb` for documentation and examples.