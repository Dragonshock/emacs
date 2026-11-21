;;; -*- lexical-binding: t -*-
;;; Mainly for speeding up startup time

;; Defer GC during startup, then restore sane runtime defaults later.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1.0)
;; Restore when idle, so the first GC doesn't delay the first frame.
(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-idle-timer
             1 nil (lambda ()
                     (setq gc-cons-threshold (* 32 1024 1024)
                           gc-cons-percentage 0.2))))
          100)

;; Keep early startup quiet unless we're debugging init.
(setq ad-redefinition-action 'accept
      jka-compr-verbose init-file-debug
      native-comp-async-report-warnings-errors init-file-debug
      native-comp-warning-on-missing-source init-file-debug
      native-comp-async-on-battery-power nil
      warning-suppress-types '((defvaralias) (lexical-binding))
      warning-inhibit-types '((files missing-lexbind-cookie)))

;; Larger process output buffer (mainly for LSP).
(setq read-process-output-max (* 4 1024 1024))

;; Batch jobs should pick up source files newer than their byte-code.
(setq load-prefer-newer noninteractive)

;; Case-insensitive pass over `auto-mode-alist' is time wasted.
(setq auto-mode-case-fold nil)

;; Avoid processing command-line option tables irrelevant to this frame type.
(unless (eq system-type 'darwin)
  (setq command-line-ns-option-alist nil))
(unless (memq initial-window-system '(x pgtk))
  (setq command-line-x-option-alist nil))

;; `setopt' can load custom dependencies early for type checks. Keep it from
;; doing so during init; type checks will still happen when variables are defined.
(when (fboundp 'setopt--set)
  (define-advice setopt--set (:around (fn &rest args) inhibit-load-symbol -90)
    (let ((custom-load-recursion t))
      (apply fn args))))

;; `file-name-handler-alist' is consulted on each call to `require', `load', or
;; various file/io functions.  Clear it while starting, restore afterwards.
(unless (or (daemonp) noninteractive init-file-debug)
  (let ((old-value (default-toplevel-value 'file-name-handler-alist)))
    (put 'file-name-handler-alist 'initial-value (copy-sequence old-value))
    (define-advice command-line-1 (:around (fn args-left) restore-file-name-handlers)
      (let ((file-name-handler-alist
             (if args-left (copy-sequence old-value) file-name-handler-alist)))
        (funcall fn args-left)))
    (add-hook 'emacs-startup-hook
              (lambda ()
                "Recover file name handlers."
                (set-default-toplevel-value
                 'file-name-handler-alist
                 (delete-dups
                  (append (default-toplevel-value 'file-name-handler-alist)
                          old-value))))
              101)))

;; Skip VC backend detection until init-emacs-vcs has decided which backends to
;; keep; probing every backend on each file is wasted work during startup.
(setq vc-handled-backends nil)

;; optimize `load-suffixes'
(setq load-suffixes '(".elc" ".el")
      load-file-rep-suffixes '(""))

(defun +restore-load-suffixes-h ()
  "Restore dynamic module suffixes before loading the init file."
  (setq load-suffixes `(".elc" ".el"
                        ,(cond ((eq system-type 'darwin) ".dylib")
                               ((eq system-type 'gnu/linux) ".so")
                               ((eq system-type 'windows-nt) ".dll")
                               (t nil)))))

(add-hook 'before-init-hook #'+restore-load-suffixes-h 100)

;; Inhibit implicit frame resizing (font changes must not resize the frame).
(setq frame-inhibit-implied-resize 'force)

;; Disable these before the first frame is drawn, so users do not have to
;; toggle the modes twice.  init-modeline enables the tab bar later to avoid
;; clipping the PGTK echo area.
(push '(tab-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(internal-border-width . 0) default-frame-alist)
(when (featurep 'ns)
  (push '(ns-transparent-titlebar . t) default-frame-alist))
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil
      tab-bar-mode nil)

;; Avoid toolbar setup work during startup. It is unnecessary while the toolbar
;; is disabled, and can be reconstructed if `tool-bar-mode' is enabled later.
(when (fboundp 'tool-bar-setup)
  (advice-add #'tool-bar-setup :override #'ignore))

;; Name the frame so it can be picked by name (select-frame-by-name, window
;; manager switchers, and per-frame buffer grouping).
(add-hook 'after-init-hook (lambda () (set-frame-name "home")))

;; Inhibit startup screen & message.  `inhibit-startup-echo-area-message' only
;; works when it equals the user name, not when it is merely non-nil.
(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      inhibit-startup-buffer-menu t
      inhibit-x-resources t
      inhibit-default-init t
      initial-scratch-message nil
      initial-major-mode 'fundamental-mode)
(advice-add #'display-startup-echo-area-message :override #'ignore)
(advice-add #'display-startup-screen :override #'ignore)

;; Suppress flashing at startup
(setq-default inhibit-redisplay t
              inhibit-message t)
(add-hook 'window-setup-hook
          (lambda ()
            (setq-default inhibit-redisplay nil
                          inhibit-message nil)
            (unless (daemonp)
              (redraw-frame))))

;; Inhibit package.el initialization: straight owns the packages.
(setq package-enable-at-startup nil)
