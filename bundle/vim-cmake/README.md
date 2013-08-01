vim-cmake
=========

vim-cmake is a Vim plugin to make working with CMake a little nicer.

I got tired of navitating to the build directory each time, and I also 
disliked setting makeprg manually each time. This plugin does just that. 

`:CMake` searches for the closest directory named build in an upwards search,
and whenever one is found, it runs the cmake command there, assuming the CMakeLists.txt
file is just one directory above. Any arguments given to :CMake will be directly passed
on to the cmake command. It also sets the working directory of the make command, so 
you can just use quickfix as with a normal Makefile project.

Installation
------------

If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply copy and paste:

    cd ~/.vim/bundle
    git clone git://github.com/vhdirk/vim-cmake.git

Once help tags have been generated, you can view the manual with
`:help cmake`.



Acknowledgements
----------------

Thanks to [Tim Pope](http://tpo.pe/), his plugins are really awesome.



License
-------

Copyright (c) Dirk Van Haerenborgh.  Distributed under the same terms as Vim itself.
See `:help license`.
