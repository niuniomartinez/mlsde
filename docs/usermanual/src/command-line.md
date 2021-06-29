# Command Line #

The `mlsde` executable accepts several arguments you can use from command line
(cmd, bash, ...).

You can pass files to edit and/or a directory to be open as project by MLSDE.
If you pass files only then the directory of the first one will be open as the
project.  If the path includes spaces you must enclose the path in double
quotes.  For example:
~~~
$ ./mlsde "/mng/WIN/Documents and Settings/peter/project/"
~~~

You can get the full list of options usign the `--help` option:
~~~
$ ./mlsde --help
~~~
