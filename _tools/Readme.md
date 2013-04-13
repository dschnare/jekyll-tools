Overview
===============

This folder contains all Tools. Each Tool is driven by a hook system that delegates
several key tasks for each Tool (i.e. compiling, etc.) to a hook that you must define. These tasks are
not provided by default since they themselves may require several dependencies. See `_hooks` for examples.