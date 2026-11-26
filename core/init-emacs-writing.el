;;; -*- lexical-binding: t -*-

;; [visual-fill-column] Center text in markdown and org
(use-package visual-fill-column
  :straight t
  :config
  (setq-default visual-fill-column-center-text t))

;; [visual-line-mode] Soft line-wrapping
(add-hook! (org-mode-hook markdown-ts-mode-hook) #'visual-line-mode)

;; [pangu] Add pangu spaces
(use-package pangu-spacing
  :straight t)

(use-package markdown-ts-mode
  :straight (:type built-in)
  :mode (("\\.md\\'" . markdown-ts-mode)
         ("\\.markdown\\'" . markdown-ts-mode))
  :config
  (setq-default markdown-ts-hide-markup t
                markdown-ts-inline-images t)
  (setq
   ;; Fold bodies on open, keep all heading levels visible
   markdown-ts-default-folding 'fold-headings
   ;; Highlight fenced code blocks with the embedded language's mode
   markdown-ts-fontify-code-blocks-natively t
   ;; TAB/newline run in the code block's language when point is inside it
   markdown-ts-enable-code-block-context-mode t
   ;; org-table-like editing/auto-align when point is in a pipe table
   markdown-ts-enable-table-mode t)

  ;; markdown-ts-mode gives all 6 heading levels the same face; inherit the
  ;; Org level faces instead so they differ and follow the current theme.
  (dotimes (i 6)
    (set-face-attribute (intern (format "markdown-ts-heading-%d" (1+ i))) nil
                        :inherit (intern (format "org-level-%d" (1+ i)))
                        :weight 'unspecified)))

;; [etaf-md] Markdown reading view on ETAF/Ebox
;; Straight resolves Package-Requires through the recipe cache, so a
;; dependency later in the dolist is still "not found" when an earlier
;; package pulls it in. Register all four recipes first, then build.
(dolist (recipe '((ecss :type git :host github :repo "emacs-taf/ecss")
                  (ebox :type git :host github :repo "emacs-taf/ebox")
                  (etaf-ui :type git :host github :repo "emacs-taf/etaf-ui")
                  (etaf :type git :host github :repo "emacs-taf/etaf")))
  (straight-register-package recipe))
(dolist (package '(ecss ebox etaf-ui etaf))
  (straight-use-package package))

(use-package etaf-md
  ;; The renderer looks for scripts/mermaid-render.mjs under the built
  ;; package directory, and straight flattens plain :files entries to the
  ;; build root, so the prefixed sub-list keeps the scripts/ path.
  :straight (:host github :repo "emacs-taf/etaf-md"
                    :files (:defaults ("scripts" "scripts/mermaid-render.mjs")))
  :commands (etaf-md-open etaf-md-preview)
  :config
  ;; 'auto: follow the active Emacs theme (also: dark / light / sepia)
  (setq etaf-md-theme 'auto))

;; [md-babel] Execute Markdown fenced blocks through Org Babel
(use-package md-babel
  :straight (:host github :repo "roife/md-babel")
  :hook (markdown-ts-mode . md-babel-mode))

;; [typst-ts-mode]
(use-package typst-ts-mode
  :straight (:host sourcehut :repo "meow_king/typst-ts-mode")
  :init
  (setq typst-ts-lsp-download-path
        (no-littering-expand-var-file-name "lsp/tinymist/tinymist"))
  (make-directory (file-name-directory typst-ts-lsp-download-path) t)
  :custom
  (typst-ts-watch-options "--open"))

;; [auctex]
(use-package tex
  :straight auctex
  :config
  (setq TeX-parse-self t             ; parse on load
        TeX-auto-save t              ; parse on save
        ;; Use hidden directories for AUCTeX files.
        TeX-auto-local ".auctex-auto"
        TeX-style-local ".auctex-style"
        TeX-source-correlate-mode t
        TeX-source-correlate-method 'synctex
        ;; Don't start the Emacs server when correlating sources.
        TeX-source-correlate-start-server nil
        ;; Automatically insert braces after sub/superscript in `LaTeX-math-mode'.
        TeX-electric-sub-and-superscript t
        ;; Just save, don't ask before each compilation.
        TeX-save-query nil))

;; [cdlatex]
(use-package cdlatex
  :straight t)

;; [reftex]
(use-package reftex
  :straight (:type built-in))

(use-package mermaid-mode
  :straight t
  :config
  (setq mermaid-output-format ".svg"))

(provide 'init-emacs-writing)
