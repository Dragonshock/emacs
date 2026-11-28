;;; test-init-server.el --- Regression test: init must start an Emacs server. -*- lexical-binding: t; -*-

;; Failure it pins (2026-11-21): this config has no server block at all,
;; so `emacsclient -t' cannot attach to a running instance.  The adopted
;; fix (dev-docs/notes/ghostty-tty-performance-research-2026-11-21.md,
;; sections 一 and 七.A1, taken from prot) is that the terminal is only a
;; VIEW onto one long-lived graphical instance, and init-emacs-core must
;; run:
;;
;;   (setq server-client-instructions nil) ; already present since before
;;   (require 'server)
;;   (unless (or (server-running-p) (daemonp))
;;     (server-start))
;;
;; Reality check done when writing this test (Emacs 31.1, this machine):
;; a BATCH Emacs starts a real server fine -- `server-socket-dir'
;; defaults to $TMPDIR/emacs501, is created on demand, and
;; `server-running-p' returns t afterwards.  So the runtime check below is
;; primary.
;;
;; Two subtleties the test accounts for:
;;   * `server-running-p' also returns non-nil when the socket belongs to
;;     some OTHER Emacs process (its docstring: use `server-process' to
;;     check whether *this* process started a server).  When a foreign
;;     server is detected the config is supposed to have SKIPPED
;;     server-start -- that is a pass -- but the load-bearing evidence is
;;     then the static org check, which fails when the block is missing.
;;   * If the batch environment cannot host a unix socket dir at all, the
;;     runtime check degrades to a SKIP backed by the static org check
;;     instead of FAILing on an environment quirk.
;;
;; Run: cd ~/.config/emacs && \
;;      emacs -Q --batch -l early-init.el -l init.el \
;;        -l scripts/test-init-server.el
;; Exit: 0 = all checks pass, 1 = at least one failed.

(require 'server)

(defvar test-serving--fails 0)

(defconst test-serving--org-file
  (expand-file-name "../emacs-config.org"
                    (file-name-directory load-file-name))
  "The org source that tangling regenerates core/*.el from.
The config is authored ONLY here; core files are never edited by hand.")

(defun test-serving--org-has-p (needle)
  "Return non-nil if the org source contains the literal string NEEDLE."
  (with-temp-buffer
    (insert-file-contents test-serving--org-file)
    (goto-char (point-min))
    (not (null (search-forward needle nil t)))))

(defun test-serving--report (ok desc &optional extra)
  "Print a PASS/FAIL line for DESC; keep a failure count.
OK non-nil means the check passed.  EXTRA is appended in brackets."
  (princ (format "%s  %s%s\n"
                 (if ok "PASS" "FAIL")
                 desc
                 (if (and extra (not (string= extra "")))
                     (format " [%s]" extra)
                   "")))
  (unless ok
    (setq test-serving--fails (1+ test-serving--fails))))

;;; --- Informational: server state in this session -----------------------

(let ((running (and (server-running-p) t))
      (here (and (boundp 'server-process)
                 (processp server-process)
                 (process-live-p server-process))))
  (princ (format "NAME=%S\n" (and (boundp 'server-name) server-name)))
  (princ (format "SOCKDIR=%S\n"
                 (and (boundp 'server-socket-dir) server-socket-dir)))
  (princ (format "RUNNING=%S\n" running))
  (princ (format "STARTED-HERE=%S\n" here))
  (princ (format "CLIENT-INSTRUCTIONS=%S\n"
                 (and (boundp 'server-client-instructions)
                      server-client-instructions))))

;;; --- Static: the server block exists in the org source -------------------

;; The parenthesized call forms are searched as literals; prose mentions
;; of `server-start' would not match.  The already-present
;; `server-client-instructions' setq-default is NOT checked here because
;; it predates this change and is not load-bearing for the server itself.
(test-serving--report
 (test-serving--org-has-p "(server-start)")
 "org defines the (server-start) call")
(test-serving--report
 (test-serving--org-has-p "(server-running-p)")
 "org guards the start with (server-running-p)")
(test-serving--report
 (or (test-serving--org-has-p "(require 'server)")
     (test-serving--org-has-p "(require (quote server))")
     (test-serving--org-has-p "(load \"server\")"))
 "org loads the server library itself")

;;; --- Runtime: a server is up after init ---------------------------------

;; PREFER plain behavior (research note section 七.A1): expected invariant
;; is that after loading init, `server-running-p' is non-nil -- either
;; because this batch process started a server itself, or because a
;; foreign live server made the config's (unless (server-running-p) ...)
;; correctly skip.  If no server is up at all, that is a failure, unless
;; the batch environment demonstrably cannot host a socket dir, in which
;; case fall back to the static evidence above (graceful degradation).
(let* ((running (and (server-running-p) t))
       (here (and (boundp 'server-process)
                  (processp server-process)
                  (process-live-p server-process)))
       (dir-parent (and (boundp 'server-socket-dir)
                        (stringp server-socket-dir)
                        (directory-file-name
                         (file-name-directory server-socket-dir))))
       (dir-usable (and dir-parent
                        (or (file-directory-p server-socket-dir)
                            (file-writable-p dir-parent)))))
  (cond
   ;; This process started the server: the strongest possible result.
   ((and running here)
    (test-serving--report
     t "server running and started by this process" "STARTED-HERE=t"))
   ;; Running, but the socket belongs to another Emacs process.  The
   ;; config then *should* have skipped server-start; the static org
   ;; checks above are what actually prove the block exists.
   (running
    (test-serving--report
     t "server running; socket owned by another Emacs (config skipped)"
     "foreign server: STARTED-HERE=nil"))
   ;; No server up and the org block IS present: report whether this is an
   ;; environment limitation (socket dir unusable -> SKIP on static
   ;; evidence) or a genuine behavioral failure.
   ((and (test-serving--org-has-p "(server-start)")
         (not dir-usable))
    (test-serving--report
     t "runtime check skipped: batch socket dir unusable here" "static evidence only"))
   (t
    (test-serving--report
     nil "server running after init ((server-running-p) non-nil)"
     (format "RUNNING=%S SOCKDIR=%S" running
             (and (boundp 'server-socket-dir) server-socket-dir))))))

;;; --- Result -------------------------------------------------------------

(princ (format "\nRESULT: %s\n"
               (if (zerop test-serving--fails) "PASS" "FAIL")))
(kill-emacs (if (zerop test-serving--fails) 0 1))
