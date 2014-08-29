
Lawrencium
==========

Lawrencium is a [Mercurial][] wrapper for [Vim][], inspired by Tim Pope's [Fugitive][].


Installation
------------

The recommended method to install Lawrencium is to use [Pathogen][], also from Tim Pope:

    cd ~/.vim/bundle
    hg clone https://bitbucket.org/ludovicchabant/vim-lawrencium

You can then update the help tags with `:call pathogen#helptags()` and browse Lawrencium's help pages with `:help lawrencium`.


Quick Start
-----------

Open a file from one of your Mercurial repositories.

    :e ~/Work/Project1/src/foo.py

Work on it for a bit, then open another file, this time using `Hgedit` and a
repository-relative path:

    :Hgedit src/bar.py

Take advantage of the auto-completion when typing the path! Work on that 
other file too, then compare it to the parent revision version:

    :Hgvdiff

Continue working. At any moment, you can run a Mercurial command and get a
quick glance at its output:

    :Hg log --limit 5 src/blah/bleh

Note how auto-completion will help you with all the built-in commands and
their options! Any other parameter will auto-complete with repository-relative
paths.

Once you're happy with your work, bring up the status window:

    :Hgstatus

You can see the difference between modified files and their parent revision
version easily by moving the cursor to the appropriate line and hitting 
<C-V>. You can also do an `addremove` by using <C-A> (use the selection mode
to add/remove several files at once!).

Now it's time to commit. While still in the status window, remove all mentions
of files you don't want to commit, and hit <C-S>. Write your commit message,
go `:wq`, and you're done! You can check everything went fine:

    :Hg tip

You can also commit faster with the `:Hgcommit` command of course!

And that's it for now. Open the help file with `:help lawrencium`, and post
your questions and problems in the [issue tracker][1] on BitBucket.


  [mercurial]: http://hg-scm.com
  [vim]: http://www.vim.org
  [fugitive]: https://github.com/tpope/vim-fugitive
  [pathogen]: https://github.com/tpope/vim-pathogen
  [1]: https://bitbucket.org/ludovicchabant/vim-lawrencium/issues

