rsynconrails
============

Unlike tools such as chef or puppet, rsynconrails aims to manage the whole operating system, not just a small subset.  While this may seem like too much work, there are some great benefits you get from doing it this way.  The first is that you're guaranteed that the systems you deploy are exactly as they should be down to every file in every directory.  You're also sure that if there aren't any foreign libraries sitting around which may trip up your application that someone installed trying to 'fix' something.  You also get the side benefit of what tripwire does.  A full filesystem audit will tell you if any of your files are different than the master source.  This is good for seeing things like rootkits and other foreign binaries/libraries.  Another great benefit is that since you're controlling the entire OS, you also gain the ability to easily backup the non-managed or 'excluded' parts, such as log files and other data files produced by daemons and utilities.

Rsync on Rails is more of an implementation around 'just enough computing' and a different way of doing things than you'd normally do with a tool such as chef or puppet.
