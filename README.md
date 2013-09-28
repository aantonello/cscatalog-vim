
cscatalog
=========

A color schema catalog
----------------------

Vim has a lot of colorscheme files. They cover almost every taste and flavors
of colors for users that like to use the GUI version or the terminal version.
Most of users choose one colorscheme and stick with it in every work. Others,
like me, likes to change between a small or large set, accordingly with the
time of the day or language that they are currently working. When you have a
large set of colorschemes is hard to remember which is better for one case or
another.

This is what `cscatalog` does: build a catalog where you can put your
colorschemes within categories of your choice.

The catalog
-----------

The catalog is a directory in you machine. You can put this directory in any
place. Often this directory is placed inside the user vim runtime directory.
Usually this is `~/.vim` on Unix or Unix like systems or
`\Users\<user_name>\vimfiles` on Windows machines. The place of this directory
is defined by the option `g:csc_StorageFolder`. Type `:h cscatalog-configure`
to see more information about it.

Categories are files inside the catalog directory. The plugin maintains these
file through user commands. For example:

    :CSAdd white-bg

Will add the current colorschema (the one in `g:colors_name`) in the category
**white-bg** inside the catalog directory.

    :CSList white-bg

This command will list, in the command window, all colorschemes added to the
**white-bg** category.

You can put one colorscheme in more than one category. For a scheme that
doesn't have any bolds or italics font decoration, we can type:

    :CSAdd non-bolds non-italics

After create your categories is easy to find a scheme that has a dark
background, bold font style but not italics:

    :CSList dark-bg bolds non-italics

Installation
------------

There is not an automatic installation yet. But the process is easy. Just copy
the files `plugin/cscatalog.vim` and `doc/cscatalog.txt` to your Vim runtime
path. Inside Vim type `:helptags ~/.vim/docs` to update the help index.

Configuration
-------------

You must set the option `g:csc_StorageFolder` before using the plugin. Common
configurations are `~/.vim/cscatalog`, if you are in a Unix like system or
`\Users\%USERNAME%\vimfiles\cscatalog` if you are using Vim under Windows.

Work in Progress
----------------

This plugin is a work in progress. It is not finished and not bugs-safe.
Probably it will never be. If you found a bug or have any requests, please,
mail me.

License
-------

Distributed in terms of [GPLv3][http://www.gnu.org/licenses/gpl3.0-standalone.html].

