Contents
--------
- [Intro](#intro)
- [User Guide](#user-guide)

Intro
-----

A Vim plugin, for automatically detecting indent settings.

User Guide
----------

:DetectIndent -- try to intelligently set the 'shiftwidth',
'expandtab' and 'tabstop' options based upon the existing settings in use in
the active file.

:DetectIndentV -- to show the message of the command :DetectIndent

:DetectIndentM -- to manually set expendtab, tabstop and shiftwidth. It accepts up to three parameters.

You can use following options to control the plugin. Or the plugin will fall back to global setting if unable to detect.
* g:detectindent_preferred_expandtab
* g:detectindent_preferred_indent
* g:detectindent_preferred_when_mixed

Currently :DetectIndent can skip c/c++ style comments and triple quoted string of python file while detecting.
