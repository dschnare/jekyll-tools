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

!UPDATE!

### cssbuild

This tool compiles LESS stylesheets starting at a main stylesheet that
includes all dependent stylesheets. Compilation is determined by hooks specified
in the config.yml file. If there is no `compile` hook then no compilation occurs.

This tool will copy all file globs to a temporary directory where each file is an immediate child. This has two consequences:

1. All `.less` files must have a unique file name.
2. All `@import` statements must import Less files as if they are all in the same directory.

```yaml
# _config.yml
lessbuild:
  hooks: _plugins/tools/hooks/lessbuild.hook

  css/main.css:
    main: _src/less/main.less
    include:
      - _src/less/*.less
      - _assets/node_modules/bootstrap/less/*.less
```

```less
// main.less
@import 'bootstrap'     // Twitter Bootstrap's less files
@import 'responsive'    // Twitter Bootstrap's less files
@import 'code'          // Twitter Bootstrap's less files
@import 'mysite-mixins' // Your site's less files
@import 'mysite-common' // Your site's less files
```

If you want to preserve the directory structure of your `.less` files then you can do the following:

***Specify a directory as the include pattern.*** This will copy the entire directory to the temporary directory, thus perserving the directory structure.

```yaml
# _config.yml
lessbuild:
  hooks: _plugins/tools/hooks/lessbuild.hook

  css/main.css:
    main: _src/less/main.less
    include:
      - _src/less/*.less
      - _assets/node_modules/bootstrap/less
```

```less
// main.less
@import 'less/bootstrap'   // Twitter Bootstrap's less files
@import 'less/responsive'  // Twitter Bootstrap's less files
@import 'common'           // Your site's less files
@import 'mixins'           // Your site's less files
```

***Specify a namespace for the include pattern.*** This will create a new directory with the same name as your namespace in the temporary directory and place all files or directories in it.

```yaml
# _config.yml
lessbuild:
  hooks: _plugins/tools/hooks/lessbuild.hook

  css/main.css:
    main: _src/less/main.less
    include:
      - _src/less/*.less
      - { bootstrap: _assets/node_modules/bootstrap/less/*.less }
      - { bootstrap2: _assets/node_modules/bootstrap/less }
```

```less
// main.less
@import 'bootstrap/bootstrap'            // From Twitter Bootstrap
@import 'bootstrap/responsive'           // From Twitter Bootstrap
// OR
// @import 'bootstrap2/less/bootstrap'   // From Twitter Bootstrap
// @import 'bootstrap2/less/responsive'  // From Twitter Bootstrap
@import 'common'
@import 'mixins'
```

This plugin comes with example hooks at `_plugins/tools/hooks/lessbuild.hook`.
The extension of this file is `.hook` so Jekyll does not load it as a Ruby file. Any
extension can be used for hook files.

The config mapping `lessbuild` must be present in `_config.yml` for this plugin to run.


### Template Data

Each build target is exposed as template data on `site.css` and `page.css`. All build target paths
exposed on `site.css` are absolute paths and all build target paths exposed on `page.css` are
relative to a specific page.

```yaml
lessbuild:
  hooks: _plugins/tools/hooks/less.hook

  css/main-@hash.css:
    main: _src/less/main.less
    include:
      - _src/less/**/*.less
  css/main.css:
    main: _src/less/main.less
    include:
      - _src/less/**/*.less
```

```liquid
<link rel="stylesheet" type="text/css" href="{{ site.css['css/main-@hash.css'] }}" />
<link rel="stylesheet" type="text/css" href="{{ page.css['css/main.css'] }}" />
<link rel="stylesheet" type="text/css" href="/css/main.css" />
```


### Config

**NOTE:** All paths are relative to the project root unless otherwise stated.

**NOTE:** There has to be a default hook file specified that has a 'compile' hook
or a hook file specific to a build target that has a 'compile' hook in order
for compilation to occur.

```yaml
lessbuild:
  # An optional path to a custom hook file.
  # This will be the default hooks unless overriden.
  # Your hook file must contain a 'compile' hook for
  # compilation to occur.

  hooks: _plugins/tools/hooks/lessbuild.hook

  # Every other key represents a build target, where
  # the key is a CSS file relative to the 'destination' setting.

  inc/css/main.min.css:
    # Hooks are optional and only apply to this build target.
    # This will override any default hooks, but will still fallback
    # to the default hooks if a particular hook is not defined at this level.

    hooks: _hooks/lessbuild-custom.rb

    # The path to the main LESS stylesheet.

    main: _src/less/main.less

    # Sequence of glob patterns to include in the build. This is optional if
    # the only LESS file you have is your main LESS file. Each glob pattern
    # can be a directory pattern or file pattern. See the documentation above
    # for more details.

    include:
      - _src/less/*.less
      - { bootstrap: _assets/node_modules/bootstrap/less/*.less }
      - { thirdparty: _assets/vendor/thirdparty/less/*.less }

    # An optional sequence of files to exclude form the build.

    exclude:
      - _src/less/themes/**/*.less


  # This form inserts a MD5 hash of the compiled CSS file into
  # the build target name. The token @hash will be replaced with the MD5 digest.

  inc/css/main-@hash.css:
    hooks: _hooks/lessbuild-custom.rb
    main: _src/less/main.less
    include:
      - _src/less/*.less
      - _assets/node_modules/bootstrap/less/*.less
```


### Hooks

- `pre_compile(main_file)`
- `compile(main_file, include_paths)`
- `post_compile(css)`

See `_plugins/tools/hooks/lessbuild.hook` for documentation and examples.


---


## copy

The copy tool will copy files or directories to a directory relative to the 'destination' setting.

This tool comes with example hooks at `_plugins/tools/hooks/copy.hook`. The extension
of this file is `.hook` so Jekyll does not load it as a Ruby file. Any
extension can be used for hook files.

The config mapping `copy` must be present in `_config.yml` for this tool to run.


### Config

**NOTE:** All paths are relative to the project root unless otherwise stated.


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