# -*- tcl -*-
#
# Searching for Tcl Modules. Defines a procedure, declares it as the primary
# command for finding packages, however also uses the former 'package unknown'
# command as a fallback.
#
# Locates all possible packages in a directory via a less restricted glob. The
# targeted directory is derived from the name of the requested package, i.e.
# the TM scan will look only at directories which can contain the requested
# package. It will register all packages it found in the directory so that
# future requests have a higher chance of being fulfilled by the ifneeded
# database without having to come to us again.
#
# We do not remember where we have been and simply rescan targeted directories
# when invoked again. The reasoning is this:
#
# - The only way we get back to the same directory is if someone is trying to
#   [package require] something that wasn't there on the first scan.
#
#   Either
#   1) It is there now:  If we rescan, you get it; if not you don't.
#
#      This covers the possibility that the application asked for a package
#      late, and the package was actually added to the installation after the
#      application was started. It shoukld still be able to find it.
#
#   2) It still is not there: Either way, you don't get it, but the rescan
#      takes time. This is however an error case and we dont't care that much
#      about it
#
#   3) It was there the first time; but for some reason a "package forget" has
#      been run, and "package" doesn't know about it anymore.
#
#      This can be an indication that the application wishes to reload some
#      functionality. And should work as well.
#
# Note that this also strikes a balance between doing a glob targeting a
# single package, and thus most likely requiring multiple globs of the same
# directory when the application is asking for many packages, and trying to
# glob for _everything_ in all subdirectories when looking for a package,
# which comes with a heavy startup cost.
#
# We scan for regular packages only if no satisfying module was found.

namespace eval ::tcl::tm {
    # Default pat