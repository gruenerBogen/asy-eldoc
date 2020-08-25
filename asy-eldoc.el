;;; asy-eldoc.el --- ElDoc capabilities for asy-mode

;; Copyright (c) 2020 gruenerBogen

;; Author: gruenerBogen <GoleoBaer@web.de>
;; Keywords: asy-eldoc Asymptote
;; Version: 0.0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; asy-eldoc.el adds eldoc support to asy-mode, which is a major mode for
;; editing Asymptote files.  It puts the funciton definition at point over in
;; the message area.
;;
;; To enable the features add
;; (add-hook 'asy-mode-hook 'asy-eldoc-setup)
;; to your .emacs file.
;;
;; You can change the location to look for the Asymptote library by setting
;; ASY-ELDOC-LIB-DIRECTORY.

;;; Code:

(require 'asy-mode)

(defcustom asy-eldoc-lib-directory
  "/usr/share/texmf/asymptote/"
  "The path of the asymptote library.")

(defvar-local asy-eldoc-function-signatures
  (make-hash-table :test 'equal)
  "A hash containing all function signatures available in the current buffer.
The keys are the names of the functions.")

(defun asy-eldoc-resolve-using-search-path (name)
  "Resolves the file behind to which NAME in an import statement points.
Return nil if the name could not be resolved.

The search is performed using Asymptote's search paths.  That is search for the
file name in the following directories, which are ordered by priority:
1. The current directory
2. Directories specified in ASYMPTOTE_DIR environment variable
   (separated by : under Unix and ; under MSDOS)
3. Directory specified in ASYMPTOTE_HOME evironment variable
   (defaults to ~/.asy)
4. The Asymptote system directory (specified in ASY-ELDOC-LIB-FOLDER)
See section 2.5 of the Asymptote manual for more details.  Currently the search
only covers the directories 1. and 4. are implemented.

If name is a string sourrounded by \" it will be returned without \"."
  (if (and (string-prefix-p "\"" name) (string-suffix-p "\"" name))
      (let ((fname (string-remove-prefix "\"" (string-remove-suffix "\"" name))))
	(when (file-exists-p fname)
	  fname))
    (let ((fname (concat name ".asy")))
      (first
       (delete-if-not
	#'file-exists-p
	(mapcar
	 (lambda (dir)
	   (concat (file-name-as-directory dir) fname))
	 (list default-directory asy-eldoc-lib-directory)))))))


(defun asy-eldoc-scan-definitions ()
  "Scan for all funcitons available in the current buffer.

Find all function definitions in the current buffer and of every asy file which
is imported in this Asymptote file."
  (interactive)
  (save-excursion
    (beginning-of-buffer)
    (asy-eldoc-scan-definitions-in-buffer)
    ;; TODO this regex misses a lot of import statements see Asymptote manual section 6.14 for details.
    (while (re-search-forward
	    "^\\s-*import\\s-+\\(\\_<.+?\\_>\\|\\s\".+?\\s\"\\)\\(?:\\s-*\\|\\s-+as [^;]+\\);"
	    nil t)
      ;; TODO find the file which is imported (match-string 1)
      (let ((fpath (asy-eldoc-resolve-using-search-path (match-string 1)))
	    (main-buffer (current-buffer)))
	(with-temp-buffer
	  (insert-file-contents fpath)
	  (asy-eldoc-scan-definitions-in-buffer main-buffer))))))
	  
	    

(defun asy-eldoc-scan-definitions-in-buffer (&optional main-buffer)
  "Scan function signatures in current buffer and copy them to MAIN-BUFFER.

After scanning all function signatures in the current buffer, the findings are
appended to the ASY-ELDOC-FUNCTION-SIGNATURES hash of the buffer MAIN-BUFFER.
MAIN-BUFFER defaults to the current buffer."
  (when (not main-buffer)
    (setq main-buffer (current-buffer)))
  (save-excursion
    (beginning-of-buffer)
    (while (re-search-forward
	    "^\\(\\_<[^[:space:]\n]+?\\s-+\\(\\_<[^ ]+?\\_>\\)\\s-*(\\(?:([^)]+)\\|[^)]+\\))\\)[[:space:]\n]*{"
	    nil t)
      (let ((fn-name (match-string 2)) (fn-signature (match-string 1)))
	(with-current-buffer main-buffer
	  (puthash fn-name fn-signature asy-eldoc-function-signatures))))))

(defun asy-eldoc-find-definition (symbol)
  "Return the definition string of SYMBOL, or nil."
  (when (stringp symbol)
    (save-excursion
      (beginning-of-buffer)
      (when (re-search-forward
	     (concat "^\\s-*\\(\\_<.+?\\_>\\s-+\\_<"
		     (regexp-quote symbol)
		     "\\_>\\s-*([^)]+)\\)\\s-*{")
	     nil t)
	(match-string 1)))))

(defun asy-eldoc-function ()
  "Return a doc string appropriate for the current context, or nil."
  ;;  (asy-eldoc-find-definition (thing-at-point 'symbol)))
  (gethash (thing-at-point 'symbol) asy-eldoc-function-signatures))

(defun asy-eldoc-setup ()
  "Setup ElDoc to support asy-mode."
  (interactive)
  (asy-eldoc-scan-definitions)
  (add-function :before-until
		(local 'eldoc-documentation-function)
		#'asy-eldoc-function))

(provide 'asy-eldoc)
;;; asy-eldoc.el ends here
