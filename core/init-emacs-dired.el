;;; -*- lexical-binding: t -*-

;; [dired] File manager
(use-package dired
  :bind (:map dired-mode-map
              ("C-c C-p" . wdired-change-to-wdired-mode)
              ;; Emacs-native commands worth a key (they exist upstream, just unbound):
              ;; create a file here, open the file at point with the OS, VC next-action.
              ("C-+" . dired-create-empty-file)
              ("C-<return>" . dired-do-open)
              ("C-x v v" . dired-vc-next-action))
  :config
  (setq
   ;; Always delete and copy recursively
   dired-recursive-deletes 'top
   dired-recursive-copies 'always
   ;; Move between two dired buffer quickly
   dired-dwim-target t
   ;; don't prompt to revert, just do it
   dired-auto-revert-buffer #'dired-buffer-stale-p
   ;; symlink
   dired-hide-details-hide-symlink-targets nil
   ;; free disk
   dired-free-space nil
   ;; Deleting goes to the system trash instead of `rm' (recoverable on macOS).
   delete-by-moving-to-trash t
   ;; Emacs 29+: clickable directory names, and drag files out of Dired.
   dired-make-directory-clickable t
   dired-mouse-drag-files t
   ;; `dired-do-revert-buffer': skip auto-revert for remote (TRAMP) dirs, where a
   ;; round-trip per revisit is expensive and often times out.
   dired-do-revert-buffer (lambda (dir) (not (file-remote-p dir))))

  (if (executable-find "gls")
      (setq insert-directory-program "gls") ; Use GNU ls as `gls' from `coreutils' if available.
    ;; Suppress the warning: `ls does not support --dired'.
    (setq dired-use-ls-dired nil))

  (when (executable-find "gls")
    (setq ls-lisp-use-insert-directory-program t ; Using `insert-directory-program'
          ;; Show directory first
          dired-listing-switches "-alh --group-directories-first")))

;; [dired-git-info] Show git info in dired
(use-package dired-git-info
  :straight t
  :after dired
  :bind (:map dired-mode-map
              ("G" . dired-git-info-mode))
  :config
  (setq dgi-commit-message-format "%h %cs %s"
        dgi-auto-hide-details-p nil))

;; [dired-aux] Extra Dired functionality
(use-package dired-aux
  :after dired
  :config
  ;; Ask whether destination dirs should get created when copying/removing files.
  (setq dired-create-destination-dirs 'ask
        dired-vc-rename-file t
        ;; `C-s' in Dired searches filenames, not buffer text (dwim = only here).
        dired-isearch-filenames 'dwim
        ;; Emacs 29+: treat a trailing slash in the target as "create the dir".
        dired-create-destination-dirs-on-trailing-dirsep t))

;; [dired-x] Extra Dired functionality
(use-package dired-x
  :after dired
  :bind (:map dired-mode-map
              ("." . dired-omit-mode)
              ("I" . dired-info))
  :config
  (setq dired-omit-verbose nil
        ;; hide dot files
        dired-omit-files "^\\..*\\'"
        ;; Disable the prompt about killing the Dired buffer for a deleted directory.
        dired-clean-confirm-killing-deleted-buffers nil
        ;; prot's dired settings (all built-in defcustoms):
        ;; clean up the Dired buffers of a deleted directory too; keep dired-x
        ;; from rebinding keys behind our back, and free up M and I so that I can
        ;; be `dired-info' below.
        dired-clean-up-buffers-too t
        dired-x-hands-off-my-keys t
        dired-bind-man nil
        dired-bind-info nil))

;; [wdired] Editable Dired buffer
(use-package wdired
  :after dired
  :config
  (setq wdired-allow-to-change-permissions t
        wdired-create-parent-directories t))

;; [image-dired] Thumbnail grid, externally-opened previews
(use-package image-dired
  :after dired
  :config
  (with-eval-after-load 'image-dired
    (define-key image-dired-thumbnail-mode-map (kbd "<return>")
                #'image-dired-thumbnail-display-external)
    (setq image-dired-thumbnail-storage 'standard
          ;; macOS: `open' instead of prot's Linux `xdg-open'.
          image-dired-external-viewer "open"
          image-dired-thumb-size 80
          image-dired-thumb-margin 2
          image-dired-thumb-relief 0
          image-dired-thumbs-per-row 4)))

;; [fd-dired] Using `fd' with `find-dired'
(use-package fd-dired
  :straight t
  :bind ([remap find-dired] . fd-dired))

;; [dired-subtree] Expand/collapse directory subtrees in place
(use-package dired-subtree
  :straight t
  :after dired
  :bind (:map dired-mode-map
              ("TAB" . dired-subtree-toggle)
              ("S-TAB" . dired-subtree-remove))
  ;; No depth backgrounds: the depth faces are hardcoded dark greens
  ;; (#252e30 ...) that ignore the theme.  The line prefix still nests.
  :custom
  (dired-subtree-use-backgrounds nil)
  :config
  (setq dired-subtree-line-prefix "  |  "))

;; [ffx] `dired-collapse'-style folding for file-name completion.
;; When a directory holds a single sub-directory chain (ignoring the same
;; entries `dired-omit-mode' hides), offer an extra candidate that jumps
;; straight to the end of the chain, alongside the normal one-level candidate.
;; e.g. when "a/" only ever contains "a/b/c/d/", both show up:
;;   a/
;;   a/b/c/d/
(use-package ffx
  :straight (:host github :repo "roife/ffx.el")
  :hook (after-init . ffx-mode))

;; [diredfl] Make dired colorful
(use-package diredfl
  :straight t
  :hook (dired-mode . diredfl-mode))

;; [dired-preview] Preview the file at point
(use-package dired-preview
  :straight t
  :hook (dired-mode . dired-preview-mode)
  :bind (:map dired-mode-map ("V" . dired-preview-mode))
  :config
  (setq dired-preview-trigger-on-start nil
        dired-preview-max-size (* (expt 2 20) 10)
        dired-preview-delay 0.5))

(provide 'init-emacs-dired)
