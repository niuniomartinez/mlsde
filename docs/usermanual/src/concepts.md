# Basic Concepts #

This guide is written from the perspective of a Windows user.  Most instructions
only require trivial changes to work on other platforms.

## The Directories ##

Application files (like translations) are in subdirectories in the `bin`
subdirectory.  You should not change such files.

User based files (like the configuration) live under the *user configuration
directory*.  This directory is a platform-dependent location:

* **Windows**:  `%APPDATA%\mlsde`
* **Linux**: `~/.config/mlsde´

If you have problems with configuration just remove the `mlsde.cfg` file that
is in the user configuration directory.  This way the next time you run MLSDE
it will use the default configuration.
