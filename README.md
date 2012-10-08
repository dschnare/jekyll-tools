# Overview

The Jekyll Tools is a set of hook-driven Jekyll plugins that help compile JS/LESS files and copy files to your site destination.



# Test

To experiment with an example quickly see the `test` directory.



# Documentation

## JSBuild

This plugin will combine JavaScript files and optionally compile the combined file.
Compilation is determined by hooks specified in the `_config.yml` file. If there is
no `compile` hook then no compilation occurs.

This plugin comes with example hooks at `_plugins/tools/hooks/jsbuild.hook`. The extension
of this file is `.hook` so Jekyll does not load it as a Ruby file. Any extension can be used for hook files.

The config mapping `jsbuild` must be present in `_config.yml` for this plugin to run.


### Template Data

Each build target is exposed as template data on `site.js` and `page.js`. All build target paths
exposed on `site.js` are absolute paths and all build target paths exposed on `page.js` are
relative to a specific page.

```yaml
jsbuild:
  hooks: _plugins/tools/hooks/jsbuild.hook

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


### Config

**NOTE:** All paths are relative to the project root unless otherwise stated.

**NOTE:** There has to be a default hook file specified that has a 'compile' hook
or a hook file specific to a build target that has a 'compile' hook in order
for compilation to occur.

```yaml
jsbuild:
  # An optional path to a custom hook file. This will be the
  # default hooks unless overriden by a build target.

  hooks: _plugins/tools/hooks/jsbuild.hook

  # Every other key represents a build target, where the key
  # is a JavaScript file relative to the 'destination' setting.
  # This form is a simple build target where only included files
  # are listed in a sequence. The order of these files is
  # important because this is the order they will be combined in.

  inc/js/main.min.js:
    - _src/js/lib/**/*.js
    - _src/js/main.js

  # This form is an advanced build target where custom settings
  # are specified.

  inc/ns/main.min.js:
    # Hooks are optional and only apply to this build target.
    # This will override any default hooks, but will still fallback
    # to the default hooks if a particular hook is not defined at this level.

    hooks: _hooks/jsbuild-custom.rb

    # Sequence of files or file globs to include in the build. The order of these files is
    # important because this is the order they will be combined in.

    include:
      - _src/js/lib/**/*.js
      - _src/js/main.js

    # An optional sequence of files to exclude from the build.

    exclude
      - _src/js/lib/_deprecated/**/*.js


  # This form inserts a MD5 hash of the compiled JavaScript file into
  # the build target name. The token @hash will be replaced with the MD5 digest.

  inc/js/main-@hash.js:
    - _src/js/lib/**/*.js
    - _src/js/main.js
```


### Hooks

- `pre_combine_file(file, file_content)`
- `pre_compile(js)`
- `compile(js)`
- `post_compile(js)`

See `_plugins/tools/hooks/jsbuild.hook` for documentation and examples.


---


## LessBuild

This plugin compiles LESS stylesheets starting at a main stylesheet that
includes all dependent stylesheets. Compilation is determined by hooks specified
in the config.yml file. If there is no `compile` hook then no compilation occurs.

This plugin will copy all file globs to a temporary directory where each file is an immediate child. This has two consequences:

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


## Copy

The copy plugin will copy files or directories to a directory relative to the 'destination' setting.

This plugin comes with example hooks at `_plugins/tools/hooks/copy.hook`. The extension
of this file is `.hook` so Jekyll does not load it as a Ruby file. Any
extension can be used for hook files.

The config mapping `copy` must be present in `_config.yml` for this plugin to run.


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