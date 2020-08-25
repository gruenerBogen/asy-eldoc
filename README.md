# asy-eldoc
ElDoc support for asy-mode. Asy-mode is an Emacs major mode for writing
Asymptote files. This displays the function signature of the function under
the point in the message area.

## Installation
Download `asy-eldoc.el` and put it somewhere you recognise. Then insert the
following into your `.emacs`-file:
```lisp
(load-file "Path to asy-eldoc.el")
(add-hook 'asy-mode-hook 'asy-eldoc-setup)
```

As asy-mode is required by `asy-eldoc.el`, you should make it available before
loading `asy-eldoc.el`.

## Configuration
Asy-eldoc currently has the following configuration option:

* ```asy-eldoc-lib-directory```: The path to the Asymptote library files. This
  defaults to `/usr/share/texmf/asymptote/`. This variable is used for
  locating imported files.
  
## Limitations
Currently there are a number of limitations to the ElDoc support:

* Asymptote's built-in function signatures are not displayed in asy-eldoc
* Nested imports, i.e. imports in imported files are currently not supported.
* Imports using other methods than the statement `import` are currently not
  recognised as imports.
* Complex function signatures containing parenthesis in their default
  arguments are currently not recognised as function signatures.
* Known function signatures are only updated when the file is first opened. To
  update them later on, you have to call ```M-x asy-eldoc-scan-definitions```.
