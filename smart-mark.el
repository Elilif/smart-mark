;;; smart-mark.el --- Restore point after C-g when mark

;; Copyright (C) 2015 Zhang Kai Yu

;; Author: Kai Yu <yeannylam@gmail.com>
;; Keywords: mark, restore

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

;; smart-mark-mode is a global minor mode.
;; When it is active and you press C-g after a mark function,
;; the cursor restores to its initial location.

;;; Code:
(defgroup smart-mark nil
  "Restore cursor to its initial location after executing a mark function."
  :group 'convenience)

(defcustom smart-mark-mark-functions
  '(mark-page mark-paragraph mark-whole-buffer mark-sexp mark-defun mark-word)
  "Functions with marking behavior.

To make the configuration effective, use the Customize user interface
 or `setopt' to modify this variable."
  :group 'smart-mark
  :type '(repeat function)
  :set (lambda (sym val)
		 (set-default sym val)
		 (mapc (lambda (f)
				 (advice-add f :before #'smart-mark-set-restore-before-mark))
			   val)))

(defcustom smart-mark-advice-functions '((keyboard-quit . :before))
  "Functions need to be advicde.

To make the configuration effective, use the Customize user interface
 or `setopt' to modify this variable."
  :group 'smart-mark
  :type '(repeat (cons function symbol))
  :set (lambda (sym val)
		 (set-default sym val)
		 (mapc (lambda (f)
				 (advice-add (car f) (cdr f) #'smart-mark-restore-cursor))
			   val)))

(defvar-local smart-mark-point-before-mark nil
  "Cursor position before mark.")

(defun smart-mark-set-restore-before-mark (&rest args)
  (unless (memq last-command smart-mark-mark-functions)
	(setq smart-mark-point-before-mark (point))))

(defun smart-mark-restore-cursor (&rest _args)
  "Restore cursor position saved just before mark."
  (when (and smart-mark-point-before-mark
			 (memq last-command smart-mark-mark-functions))
	(goto-char smart-mark-point-before-mark)
	(setq smart-mark-point-before-mark nil)))

(defun smart-mark-advice-all ()
  "Advice all `smart-mark-mark-functions' so that point is initially saved."
  (mapc (lambda (f)
          (advice-add f :before #'smart-mark-set-restore-before-mark))
		smart-mark-mark-functions)
  (mapc (lambda (f)
		  (advice-add (car f) (cdr f) #'smart-mark-restore-cursor))
		smart-mark-advice-functions))

(defun smart-mark-remove-advices ()
  "Remove all advices for `smart-mark-mark-functions'."
  (mapc (lambda (f)
          (advice-remove f #'smart-mark-set-restore-before-mark))
        smart-mark-mark-functions)
  (mapc (lambda (f)
		  (advice-remove (car f) #'smart-mark-restore-cursor))
		smart-mark-advice-functions))

;;;###autoload
(define-minor-mode smart-mark-mode
  "Mode for easy expand line when expand line is activated."
  :global t
  (if smart-mark-mode
      (smart-mark-advice-all)
    (smart-mark-remove-advices)))

(provide 'smart-mark)
;;; smart-mark.el ends here
