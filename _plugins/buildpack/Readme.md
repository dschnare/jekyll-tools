Overview
===============

This folder is the root for the buildpack plugins. Each plugin is driven by a hook system that delegates
several key tasks for each plugin (i.e. compiling, etc.) to a hook that you must define. These tasks are
not provided by default since they themselves may require several dependencies. See the hook examples
for ideas of how you would write your own hooks, or use the examples as-is and install their dependencies.

- copy.rb = Plugin that can be used to copy files from excluded directories into the site destination.
- jsbuild.rb = Plugin that can be used to combine and optionally compile Javascript files.
- lessbuild.rb = Plugin that can be used to compile LESS stylesheets.
- lib/ = Helper Ruby scripts for each plugin.
- hooks/ = Contains example hooks for each plugin.
