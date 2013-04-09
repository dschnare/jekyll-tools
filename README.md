# Overview

Jekyll Tools is a set of hook-driven Jekyll plugins that help 
automate common tasks such as compiling LESS files, combining and
minifying JS files and copying files to a destination of your choice.

Tools are required by the Jekyll Tools plugin. Each tool is responsible for
performing a specific task and exposes hooks that can be overridden.

Hooks provide a convenient mechanism to override various stages of execution
of a tool. Hooks are functions with specific signatures contained within a
hook file. Hook files are found in a hooks directory, typically this directory
is `_hooks`.

# Installation

Copy the `_plugins`, `_hooks` and `_tools` folders to your Jekyll project.

Next copy the `Gemfile` to your Jekyll project. If you already have a Gemfile
then ensure the gems are copied over. Specifically, the LESS tool depends on the
`os` gem and the jsbuild tool depends on the `uglifier` gem.

Finally, if you intend on using the built-in tools for TypeScript and/or LESS
compilation then be sure to create a `package.json` file with the following
dependencies:

- typescript
- lessjs

Once you have all your dependencies in order then install them.

    gem install bundler
    bundle install
    npm install



# Testing

To experiment with an example quickly, see the `test` directory.



# Documentation

To use Jekyll Tools you must have a `tools` hash in your `_config.yml` file
that has the following keys.

    tools: # The Jekyll Tools hash
      path: # The path to find the tools (usually _tools)
      defaults: # The hash containing defaults for each tool
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
        css/main-@hash.css:
          main: _assets/less/main.less
          include:
            - _assets/less/*.less
            - { bootstrap: node_modules/bootstrap/less/*.less }
        css/main.css:
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
typically acts as a nullop.

When hooks are specified in your defaults hash and in your tool settings hash, then the hooks will
cascade. This means that if a hook is specified in your default hooks it doesn't have to be sepcified
in your setting hooks.



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

#### Hooks

- `pre_combine_file(file, file_content, settings)`
- `pre_compile(js, settings)`
- `compile(js, settings)`
- `post_compile(js, settings)`

See `_hooks/jsbuild.rb` for documentation and examples.


#### Template Data

Each build target is exposed as template data on `site.js` and `page.js`. All build target paths
exposed on `site.js` are absolute paths and all build target paths exposed on `page.js` are
relative to the current page.

```yaml
tools:
  defaults:
    jsbuild:
      hooks: _plugins/tools/hooks/jsbuild.hook
  tasks:
    - jsbuild:
        js/main-@hash.js:
          - _src/js/lib/**/*.js
          - _src/main.js
        js/main.js:
          - _src/js/lib/**/*.js
          - _src/js/main.js
```

```liquid
<script type="text/javascript" src="{{ site.js['js/main-@hash.js'] }}"></script>
<script type="text/javascript" src="{{ site.js['js/main.js'] }}"></script>
<script type="text/javascript" src="/js/main.js"></script>
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
cssbuild:
  css/main-@hash.css:
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
cssbuild:
  css/main-@hash.css:
    hooks: _hooks/cssbuild-less.rb
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



#### Template Data

Each build target is exposed as template data on `site.css` and `page.css`. All build target paths
exposed on `site.css` are absolute paths and all build target paths exposed on `page.css` are
relative to a specific page.

```yaml
tools:
  defaults:
    cssbuild:
      hooks: _hooks/cssbuild-less.rb
  tasks:
    - cssbuild:
        css/main-@hash.css:
          main: _assets/less/main.less
          include:
            - _assets/less/*.less
            - node_modules/bootstrap/less/*.less
        css/main-@hash.css:
          main: _assets/less/main.less
          include:
            - _assets/less/*.less
            - node_modules/bootstrap/less/*.less
```

```liquid
<link rel="stylesheet" type="text/css" href="{{ site.css['css/main-@hash.css'] }}" />
<link rel="stylesheet" type="text/css" href="{{ page.css['css/main.css'] }}" />
<link rel="stylesheet" type="text/css" href="/css/main.css" />
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

If a copy target contains `**/` then you can optionally preserve all recursively matched directories when copying.

Example:

```yaml
tools:
  tasks:
    - copy:
      preserve_dirs: true
      page[0-9]/vendor:
        - node_modules/bootstrap/**/*.*
```

The above example will copy all files from Twitter bootstrap into
a `vendor/` directory under a directory of the form `page[0-9]` directly
under the `destination` directory. If `vendor/` does not exist then the
path will be created. Because `preserve_dirs` is set to true however,
the directories under `node_modules/bootstrap` will be copied over under
the copy target. If `preserve_dirs` was not set or was set to false then only
the files themselves would be copied to the copy target.




!UPDATE!


#### Hooks


```yaml
copy:
  # An optional path to a custom hook file.
  # This will be the default hooks unless overriden.

  hooks: _plugins/tools/hooks/copy.hook

  # An optional setting to preserve recursive
  # directories in file patterns. Default is false.

  preserve_dirs: true

  # Every other key represents a copy target, where the
  # key is a directory relative to the 'destination' setting.
  # This form is a simple copy target where only files and/or
  # directories to copy are listed in a sequence.

  inc/img:
    - _assets/from_design/images/**/*.*
    - _assets/node_modules/bootstrap/img/*.*

  # This form is an advanced copy target where custom settings
  # are specified.

  inc/img:
    # Hooks are optional and only apply to this copy target.
    # This will override any default hooks, but will still fallback
    # to the default hooks if a particular hook is not defined at this level.

    hooks: _hooks/copy-custom.rb

    # An optional setting that preserves recursive directories in
    # file patterns for this copy target only.

    preserve_dirs: false

    # Sequence of files and/or directories to copy.

    include:
      - _assets/from_design/images/**/*.*
      - _assets/node_modules/bootstrap/img/*.*

    # An optional sequence of files to exclude from copying.

    exclude:
      - _assets/from_design/images/old/**/*.*


  # Copy targets can contain directory glob patterns as well.
  # This will copy the included files to all directories that
  # match the glob. Glob patterns can match directories created
  # by Jekyll in the 'destination' directory.

  webpages/**/docs:
    - _assets/docs/*.pdf
```


### Hooks

- `copy_file(source_file, dest_file)`

See `_plugins/tools/hooks/copy.hook` for documentation and examples.


### Preserving Recursive Directories

By default recursive directories are not preserved when copying, meaning each file
will be copied to the root of its copy target: `{destination}/inc/img/{file.ext}`

```yaml
copy:
  inc/img/somedir:
    - _assets/node_modules/bootstrap/img/**/*.*
```

Recursive directories can be preserved by setting the `preserve_dirs` mapping to true.
All images in this example will now have a copy path: `{destination}/inc/img/somedir/{recursive-directories}/{file.ext}`

This setting has the affect of maintaining the path at the first recursive glob of each included file.
In the following example the directory structure after `_assets/node_modules/bootstrap/img` for all images will be preserved when copying.

```
_assets/node_modules/bootstrap/img/**/*.*
```

The `preserve_dirs` mapping can be specified at the top-level or on an individual copy target. This mapping
has no effect on patterns that do not match recursive directories (i.e. do not contain '**').