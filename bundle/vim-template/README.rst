=============================
 Simple Vim templates plugin
=============================
:Author: Adrian Perez <aperez@igalia.com>

This is a simple plugin for Vim that will allow you to have a set of
templates for certain file types. It is useful to add boilerplate code
like guards in C/C++ headers, or license disclaimers.


Installation
============

The easiest way to install the plugin is to install it as a bundle:

1. Get and install `pathogen.vim`__. You can skip this step if you
   already have it installed.

2. ``cd ~/.vim/bundle``

3. ``git clone git://github.com/aperezdc/vim-template.git``

__ https://github.com/tpope/vim-pathogen


Updating
========

In order to update the plugin, go to the its bundle directory and use
Git to update it:

1. ``cd ~/.vim/bundle/vim-template``

2. ``git pull``

Configuration
=============

In your vimrc you can put:

* ``let g:templates_plugin_loaded = 1`` to skip loading of this plugin.

* ``let g:templates_no_autocmd = 1`` to disable automatic insertion of
  template in new files.

Usage
=====

There are a number of options to use a template:


* Create a new file giving it a name. The suffix will be used to determine
  which template to use. E.g::

    $ vim foo.c

* In a buffer, use ``:Template foo`` to load the template that would be
  loaded for file with suffix ``foo``. E.g. from within Vim::

    :Template c

Template search order
---------------------

The algorithm to search for templates works like this:

1. A file named ``=template.<suffix>`` in the current directory. If not
   found, goto *(2)*.

2. Go up a directory and goto *(1)*, if not possible, goto *(3)*.

3. Try to use the ``template.<suffix>`` file supplied with the plugin.


Variables in templates
----------------------

The following variables will be expanded in templates:

``%DAY%``, ``%YEAR%``, ``%MONTH%``
    Numerical day of the month, year and month.
``%DATE%``
    Date in ``YYYY-mm-dd`` format
``%TIME%``
    Time in ``HH:MM`` format
``%FDATE``
    Full date (date + time), in ``YYYY-mm-dd HH:MM`` format.
``%FILE%``
    File name, without extension.
``%FFILE%``
    File name, with extension.
``%EXT%``
    File extension.
``%MAIL%``
    Current user's e-mail address. May be overriden by defining ``g:email``.
``%USER%``
    Current logged-in user name. May be overriden by defining ``g:username``.
``%HOST%``
    Host name.
``%GUARD%``
    A string with alphanumeric characters and underscores, suitable for use
    in proprocessor guards for C/C++/Objective-C header files.
``%CLASS%``
    File name, without extension,and the first character of every word is capital
``%HERE%``
    Expands to nothing, but ensures that the cursor will be placed in its
    position after expanding the template.

