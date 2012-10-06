# Overview

The Jekyll Buildpack is a set of hook-driven Jekyll plugins that help compile JS/LESS files and copy files to your site destination.



# Test

To experiment with an example quickly see the `test` directory.



# Documentation

## JSBuild

This plugin will combine JavaScript files and optionally compile the combined file.
Compilation is determined by hooks specified in the `_config.yml` file. If there is
no `compile` hook then no compilation occurs.

This plugin comes with example hooks at `_plugins/buildpack/hooks/jsbuild.hook`. The extension
of this file is `.hook` so Jekyll does not load it as a Ruby file. Any extension can be used for hook files.

The config mapping `jsbuild` must be present in `_config.yml` for this plugin to run.


### Template Data

Each build target is exposed as template data on `site.js` and `page.js`. All build target paths
exposed on `site.js` are absolute paths and all build target paths exposed on `page.js` are
relative to a specific page.

```yaml
jsbuild:
  hooks: _plugins/hooks/jsbuild.hook

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

NOTE: All paths are relative to the project root unless otherwise stated.

NOTE: There has to be a default hook file specified that has a 'compile' hook
or a hook file specific to a build target that has a 'compile' hook in order
for compilation to occur.

```yaml
jsbuild:
  # An optional path to a custom hook file. This will be the
  # default hooks unless overriden by a build target.

  hooks: _plugins/build/hooks/jsbuild.hook

  # Every other key represents a build target, where the key
  # is a JavaScript file relative to the 'destination' setting.
  # This form is a simple build target where only included files
  # are listed in a sequence.

  inc/js/main.min.js:
    - _src/js/lib/**/*.js
    - _src/js/main.js

  # This form is an advanced build target where custom settings
  # are specified.

  inc/ns/main.min.js:
    # Hooks are optional and only apply to this build target. This will override any default hooks.

    hooks: _hooks/jsbuild-custom.rb

    # Sequence of files to include in the build.

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

See `_plugins/buildpack/hooks/jsbuild.hook` for documentation and examples.


---


## LessBuild

This plugin compiles LESS stylesheets starting at a source/main stylesheet that
includes all dependent stylesheets. Compilation is determined by hooks specified
in the config.yml file. If there is no `compile` hook then no compilation occurs.

This plugin comes with example hooks at `_plugins/buildpack/hooks/lessbuild.hook`.
The extension of this file is `.hook` so Jekyll does not load it as a Ruby file. Any
extension can be used for hook files.

The config mapping `lessbuild` must be present in `_config.yml` for this plugin to run.


### Template Data

Each build target is exposed as template data on `site.css` and `page.css`. All build target paths
exposed on `site.css` are absolute paths and all build target paths exposed on `page.css` are
relative to a specific page.

```yaml
lessbuild:
  hooks: _plugins/hooks/less.hook

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

NOTE: All paths are relative to the project root unless otherwise stated.

NOTE: There has to be a default hook file specified that has a 'compile' hook
or a hook file specific to a build target that has a 'compile' hook in order
for compilation to occur.

```yaml
lessbuild:
  # An optional path to a custom hook file.
  # This will be the default hooks unless overriden.
  # Your hook file must contain a 'compile' hook for
  # compilation to occur.

  hooks: _plugins/build/hooks/lessbuild.hook

  # Every other key represents a build target, where
  # the key is a CSS file relative to the 'destination' setting.

  inc/css/main.min.css:
    # An optional path to a custom hook file for this build target.
    # This will override any default hooks.

    hooks: _hooks/lessbuild-custom.rb

    # The path to the main LESS stylesheet.

    main: _src/less/main.less

    # Sequence of files to include in the build. This is optional if
    # the only LESS file you have is your main LESS file.

    include:
      - _src/less/**/*.less
      - _assets/vendor/bootstrap/less/*.less

    # An optional sequence of files to exclude form the build.

    exclude:
      - _src/less/themes/**/*.less


  # This form inserts a MD5 hash of the compiled CSS file into
  # the build target name. The token @hash will be replaced with the MD5 digest.

  inc/css/main-@hash.css:
    hooks: _hooks/lessbuild-custom.rb
    main: _src/less/main.less
    include:
      - _src/less/**/*.less
      - _assets/vendor/bootstrap/less/*.less
```


### Hooks

- `pre_compile(main_file)`
- `compile(main_file)`
- `post_compile(css)`

See `_plugins/buildpack/hooks/lessbuild.hook` for documentation and examples.


---


## Copy

The copy plugin will copy files to a directory relative to the 'destination' setting.

This plugin comes with example hooks at `_plugins/buildpack/hooks/copy.hook`. The extension
of this file is `.hook` so Jekyll does not load it as a Ruby file. Any
extension can be used for hook files.

The config mapping `copy` must be present in `_config.yml` for this plugin to run.


### Config

NOTE: All paths are relative to the project root unless otherwise stated.


```yaml
copy:
  # An optional path to a custom hook file.
  # This will be the default hooks unless overriden.

  hooks: _plugins/build/hooks/copy.hook

  # An optional setting to preserve recursive
  # directories in file patterns. Default is false.

  preserve_dirs: true

  # Every other key represents a copy target, where the
  # key is a directory relative to the 'destination' setting.
  # This form is a simple copy target where only files to copy
  # are listed in a sequence.

  inc/img:
    - _assets/from_design/images/**/*.*
    - _assets/vendor/bootstrap/images/*.*

  # This form is an advanced copy target where custom settings
  # are specified.

  inc/img:
    # An optional path to a custom hook file for this copy target.
    # This will override any default hooks.

    hooks: _hooks/copy-custom.rb

    # An optional setting that preserves recursive directories in
    # file patterns for this copy target only.

    preserve_dirs: false

    # Sequence of files to copy.

    include:
      - _assets/from_design/images/**/*.*
      - _assets/vendor/bootstrap/images/*.*

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

See `_plugins/buildpack/hooks/copy.hook` for documentation and examples.


### Preserving Recursive Directories

By default recursive directories are not preserved when copying, meaning each file
will be copied to the root of its copy target: `{destination}/inc/img/{file.ext}`

```yaml
copy:
  inc/img:
    - _vendor/bootstrap/img/**/*.*
```

Recursive directories can be preserved by setting the `preserve_dirs` mapping to true.
All images in this example will now have a copy path: `{destination}/inc/img/nested/{recursive-directories}/{file.ext}`

```yaml
copy:
  inc/img/nested:
    preserve_dirs: true
    include:
      - _vendor/bootstrap/img/**/*.*
```

This setting has the affect of maintaining the path at the first recursive glob of each included file.

This will keep the path from `_vendor/bootstrap/img` for all images.
```
_vendor/bootstrap/img/**/*.*
```

The `preserve_dirs` mapping can be specified at the top-level or on an individual copy target. This mapping
has no effect on patterns that do not match recursive directories (i.e. do not contain '**').