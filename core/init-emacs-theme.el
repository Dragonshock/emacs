;;; -*- lexical-binding: t -*-
;; Declared here, not in init-emacs-ui: `init.el' requires init-emacs-theme before init-emacs-ui and
;; +load-theme runs immediately below (tty-setup-hook with
;; :unless-daemonp-call-immediately). The declaration is what puts
;; straight/build/ashen on `custom-theme-load-path' and `load-path', so it must
;; precede the first `load-theme' call.
(use-package ashen
  :straight (:host github :repo "LuciusChen/ashen")
  :demand t)

(defcustom +light-theme 'ashen-day
  "Theme used when the system appearance is light."
  :type 'symbol
  :group 'faces)

(defcustom +dark-theme 'ashen-night
  "Theme used when the system appearance is dark."
  :type 'symbol
  :group 'faces)
(defvar +system-appearance nil
  "Last reported system appearance, either `light' or `dark'.")

(defun +system-appearance-changed (appearance)
  "Remember APPEARANCE and update the theme using a graphical frame."
  (setq +system-appearance appearance)
  ;; Notifications may arrive while a terminal frame is selected.
  (when-let* ((frame (seq-find #'display-graphic-p (frame-list))))
    (with-selected-frame frame
      (+load-theme))))

(defun +theme-for-appearance (appearance)
  "Return the theme symbol for APPEARANCE, `light' or `dark'."
  (if (eq appearance 'dark) +dark-theme +light-theme))

(defun +tty-appearance (&optional frame)
  "Return the appearance FRAME's terminal reported, or nil.
Only the terminal parameter counts.  The terminal frame's
`background-mode' parameter may already be the xterm default `light'
chosen before the background was known."
  (terminal-parameter (or frame (selected-frame)) 'background-mode))

(add-hook! tty-setup-hook :unless-daemonp-call-immediately
  (defun +load-theme (&optional theme)
    "Load THEME, or choose the theme matching the selected frame.
Themes are global in Emacs, so a terminal frame never switches the
theme while a graphical frame exists: that would change the GUI too.
An unreported terminal background falls back to dark, not to the
xterm default light."
    (let* ((frame (selected-frame))
           (graphical (display-graphic-p frame))
           (gui-present (seq-find #'display-graphic-p (frame-list))))
      (when (or theme graphical (null gui-present))
        (when (and (not graphical) (+tty-appearance frame))
          ;; Make the frame parameter agree before the theme's face
          ;; specs are realized, then let the theme apply.
          (frame-set-background-mode frame))
        (setq theme
              (or theme
                  (+theme-for-appearance
                   (if graphical
                       (or +system-appearance
                           (and (boundp 'ns-system-appearance)
                                ns-system-appearance)
                           'dark)
                     (or (+tty-appearance frame) 'dark)))))
        (unless (member theme custom-enabled-themes)
          (mapc #'disable-theme custom-enabled-themes)
          (load-theme theme t))))))

(add-hook! after-make-frame-functions
  (defun +load-theme-for-frame (frame)
    "Choose the theme for a newly created graphical FRAME."
    (when (display-graphic-p frame)
      (with-selected-frame frame
        (+load-theme)))))

(defun +tty-apply-reported-background (&rest _)
  "Adopt a late OSC 11 reply for the selected terminal, then repick.
`xterm--report-background-handler' stores only the colour in
`xterm--background-color'; the terminal's `background-mode' parameter
and the theme stay stale, so the TTY keeps the xterm default light."
  (let* ((frame (selected-frame))
         (term (frame-terminal frame))
         (rgb (terminal-parameter term 'xterm--background-color)))
    (when (and rgb (not (display-graphic-p frame)))
      (apply #'xterm--set-background-mode rgb)
      (dolist (f (frame-list))
        (when (eq (frame-terminal f) term)
          (frame-set-background-mode f)))
      (+load-theme))))

(with-eval-after-load 'term/xterm
  (unless (advice-member-p #'+tty-apply-reported-background
                           'xterm--report-background-handler)
    (advice-add 'xterm--report-background-handler
                :after #'+tty-apply-reported-background)))

(defun +tty-query-background-once ()
  "Query the terminal background once for a non-daemon TUI start.
The initial terminal frame is created before any init file runs, so
`reportBackground' cannot be enabled in time for it."
  (when (and (not (daemonp))
             (not (display-graphic-p))
             (null (+tty-appearance (selected-frame)))
             (fboundp '+xterm-report-background))
    (let ((xterm-query-timeout 0.15))
      (+xterm-report-background))))

(add-hook 'window-setup-hook #'+tty-query-background-once)

(provide 'init-emacs-theme)
