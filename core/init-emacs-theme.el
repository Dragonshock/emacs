;;; -*- lexical-binding: t -*-
;; Declared here, not in init-emacs-ui: `init.el' requires init-emacs-theme before init-emacs-ui and
;; +load-theme runs immediately below (tty-setup-hook with
;; :unless-daemonp-call-immediately). The declaration is what puts
;; straight/build/ashen on `custom-theme-load-path' and `load-path', so it must
;; precede the first `load-theme' call.
(use-package ashen
  :straight (:host github :repo "LuciusChen/ashen")
  :demand t)

;; Quantize the three neutral keys onto exact xterm palette entries
;; (235/236/237).  In a 256-colour terminal #222328 and #2e323a are
;; approximated to the blue/teal indexes 17/23, which is why blocks and
;; the tab bar looked wrong; GUI and TUI now render the same values.
;; REVERT: delete this form and tangle; the theme's own palette returns.
(setq ashen-night-palette-overrides
      '((current-line   . "#262626")
        (alt-background . "#303030")
        (selection      . "#3a3a3a")))

;; Quantize the day neutral keys onto the 232-255 grayscale ramp.  Warm
;; near-whites (#fffaf4 etc.) approximate to ANSI 15/7, which Ghostty's
;; Gruvbox theme remaps to cream/tan -- the TUI showed yellow blocks.
;; Grayscale entries render identically on GUI and TUI.
;; REVERT: delete this form and tangle; the theme's own palette returns.
(setq ashen-day-palette-overrides
      '((background     . "#eeeeee")   ; 255
        (current-line   . "#e4e4e4")   ; 254
        (alt-background . "#dadada")   ; 253
        (selection      . "#d0d0d0")   ; 252
        (region         . "#c6c6c6"))) ; 251

(defcustom +theme 'ashen-day
  "The fixed theme used by both GUI and TUI frames."
  :type 'symbol
  :group 'faces)

(add-hook! tty-setup-hook :unless-daemonp-call-immediately
  (defun +load-theme (&optional theme)
    "Load THEME, or the fixed default theme.  GUI and TUI both use it."
    (setq theme (or theme +theme))
    (unless (member theme custom-enabled-themes)
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme theme t))))

(add-hook! after-make-frame-functions
  (defun +load-theme-for-frame (frame)
    "Ensure the fixed default theme on every newly created FRAME."
    (with-selected-frame frame
      (+load-theme))))

(provide 'init-emacs-theme)
