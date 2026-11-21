;;; -*- lexical-binding: t -*-

(add-hook 'window-setup-hook
          (lambda ()
            (message "window-setup: %.3fs, after-init: %.3fs"
                     (float-time (time-subtract nil before-init-time))
                     (float-time (time-subtract after-init-time before-init-time)))))

;; Each entry maps to one `core/init-*.el', tangled from `emacs-config.org'.
;; The order IS the dependency order:
;;   init-emacs-util  first: every other module uses its `add-hook!' / `defadvice!'
;;   init-emacs-theme before init-emacs-platform: the platform files call
;;              `+system-appearance-changed' at load time.
;;   init-emacs-ime   right after core: it owns `default-input-method' and runs
;;              `+liberime-setup-build-env' before any liberime build.

(add-to-list 'load-path (expand-file-name "core" user-emacs-directory))

(require 'init-emacs-util)
(require 'init-emacs-straight)
(require 'init-emacs-core)
(require 'init-emacs-ime)
(require 'init-emacs-theme)
(require 'init-emacs-ui)
(require 'init-emacs-platform)
(require 'init-emacs-highlight)
(require 'init-emacs-modeline)
(require 'init-emacs-completion)
(require 'init-emacs-search)
(require 'init-emacs-edit)
(require 'init-emacs-window)
(require 'init-emacs-dired)
(require 'init-emacs-prog)
(require 'init-emacs-langs)
(require 'init-emacs-writing)
(require 'init-emacs-org)
(require 'init-emacs-agenda)
(require 'init-emacs-vcs)
(require 'init-emacs-tools)
(require 'init-emacs-mail)
(require 'init-emacs-web)
(require 'init-emacs-ai)
