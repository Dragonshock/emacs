;;; -*- lexical-binding: t -*-
(when (eq system-type 'darwin)
  ;; [Modifier keys] Command as Meta, Option as Super
  ;; (setq mac-command-modifier 'meta
  ;;       mac-option-modifier 'super)

  (unbind-key "s-,")
  (bind-keys ("s-a" . mark-whole-buffer)
             ("s-x" . kill-region)
             ("s-s" . save-buffer)
             ("s-v" . yank)
             ("s-c" . copy-region-as-kill)
             ("s-z" . undo)
             ("s-Z" . undo-redo)
             ("s-f" . isearch-forward)
             ("s-w" . tab-close)
             ("s-t" . tab-new)
             ;; ("s-o" . other-window)
             ("s-SPC" . toggle-input-method)))

(provide 'init-emacs-platform)
