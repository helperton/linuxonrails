rsynconrails
============
Rsync on Rails is an implementation of 'just enough computing'.

Unlike tools such as chef or puppet, rsynconrails aims to manage the whole operating system, not just a small subset.  Files and directories are applied to the remote host in an 'already installed' state.  Instead of telling the host which deb's or rpm's it should have, you define what files, directories, and configuration it'll have.  Because this is a different way of the looking at the change management world, it requires that you have all the files/directories/configuration in place already on the master side (the side pushing the content down to the remote host).  This is called a 'package tree'.

The 'package tree' is where most of your work will occur.  Utilties are provided to unpack standard packages such as rpm or deb and place them into the 'package tree'.  The initial work for a 'package tree' can be a bit tedious at present.

While this may seem like too much work, there are some great benefits you get from doing it this way.  The first is that you're guaranteed that the systems you deploy are exactly as they should be down to every file in every directory.  You're also sure that if there aren't any foreign libraries sitting around which may trip up your application that someone installed trying to 'fix' something.  You also get the side benefit of what tripwire does.  A full filesystem audit will tell you if any of your files are different than the master source.  This is good for seeing things like rootkits and other foreign binaries/libraries.  Another great benefit is that since you're controlling the entire OS, you also gain the ability to easily backup the non-managed or 'excluded' parts, such as log files and other data files produced by daemons and utilities.

