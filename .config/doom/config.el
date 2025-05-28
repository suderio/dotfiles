(defun sud/font-installed? (font-name)
  "Retorna t se a fonte font-name está instalada"
  (if (find-font (font-spec :name font-name))
       t nil))

(after! dash
  (defmacro sud/convert-shell-scripts-to-interactive-commands (directory)
    "Make the shell scripts in DIRECTORY available as interactive commands."
    (cons 'progn
          (-map
           (lambda (filename)
             (let ((function-name (intern (concat "sud/shell-" (file-name-nondirectory filename)))))
               `(defun ,function-name (&rest args)
                  (interactive)
                  (cond
                   ((not (called-interactively-p 'any))
                    (shell-command-to-string (mapconcat 'shell-quote-argument (cons ,filename args) " ")))
                   ((region-active-p)
                    (apply 'call-process-region (point) (mark) ,filename nil (if current-prefix-arg t nil) t args))
                   (t
                    (apply 'call-process ,filename nil (if current-prefix-arg t nil) nil args))))))
           (-filter (-not #'file-directory-p)
                    (-filter #'file-executable-p (directory-files directory t))))))
  (sud/convert-shell-scripts-to-interactive-commands "~/.local/bin")
)

(defvar sud/git-clone-destination "~/git/")
(defun sud/git-clone-clipboard-url ()
  "Clone git URL in clipboard asynchronously and open in dired when finished."
  (interactive)
  (cl-assert (string-match-p "^\\(http\\|https\\|ssh\\)://" (current-kill 0)) nil "No URL in clipboard")
  (let* ((url (current-kill 0))
         (download-dir (expand-file-name sud/git-clone-destination))
         (project-dir (concat (file-name-as-directory download-dir)
                              (file-name-base url)))
         (default-directory download-dir)
         (command (format "git clone %s" url))
         (buffer (generate-new-buffer (format "*%s*" command)))
         (proc))
    (when (file-exists-p project-dir)
      (if (y-or-n-p (format "%s exists. delete?" (file-name-base url)))
          (delete-directory project-dir t)
        (user-error "Bailed")))
    (switch-to-buffer buffer)
    (setq proc (start-process-shell-command (nth 0 (split-string command)) buffer command))
    (with-current-buffer buffer
      (setq default-directory download-dir)
      (shell-command-save-pos-or-erase)
      (require 'shell)
      (shell-mode)
      (view-mode +1))
    (set-process-sentinel proc (lambda (process state)
                                 (let ((output (with-current-buffer (process-buffer process)
                                                 (buffer-string))))
                                   (kill-buffer (process-buffer process))
                                   (if (= (process-exit-status process) 0)
                                       (progn
                                         (message "finished: %s" command)
                                         (dired project-dir))
                                     (user-error (format "%s\n%s" command output))))))
    (set-process-filter proc #'comint-output-filter)))

(defun sud/org-roam-copy-todo-to-today ()
  (interactive)
  (let ((org-refile-keep t) ;; Set this to nil to delete the original!
        (org-roam-dailies-capture-templates
          '(("t" "tasks" entry "%?"
             :if-new (file+head+olp "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n" ("Done!")))))
        (org-after-refile-insert-hook #'save-buffer)
        today-file
        pos)
    (save-window-excursion
      (org-roam-dailies--capture (current-time) t)
      (setq today-file (buffer-file-name))
      (setq pos (point)))

    ;; Only refile if the target file is different than the current file
    (unless (equal (file-truename today-file)
                   (file-truename (buffer-file-name)))
      (org-refile nil nil (list "Done!" today-file nil pos)))))

(after! org
(add-to-list 'org-after-todo-state-change-hook
             (lambda ()
               (when (equal org-state "DONE")
                 (sud/org-roam-copy-todo-to-today)))))

(defun orgsync ()
  "Call sync."
  (interactive)
  (shell-command "git-sync -C ~/org -s sync"))

(setq! user-full-name "Paulo Suderio"
      user-mail-address "paulo.suderio@gmail.com")

(setq! display-line-numbers-type 'relative
      evil-respect-visual-line-mode t
      which-key-idle-delay 0.8
      which-key-max-description-length 155
      which-key-separator " → "
      which-key-dont-use-unicode nil
      )

(map! :leader :desc "Open Journal" "n j o" #'org-journal-open-current-journal-file)

(setq! global-auto-revert-mode-text "󰀘"
      global-auto-revert-non-file-buffers t)

(setenv "LANG" "pt_BR,en_US")
(setq-default ispell-program-name "hunspell")
(with-eval-after-load "ispell"
  (setq! ispell-really-hunspell t)
  (setq! ispell-program-name "hunspell")
  (setq! ispell-dictionary "pt_BR,en_US")
  ;; ispell-set-spellchecker-params has to be called
  ;; before ispell-hunspell-add-multi-dic will work
  (ispell-set-spellchecker-params)
  (ispell-hunspell-add-multi-dic "pt_BR,en_US"))

(use-package! ws-butler
  :hook prog-mode-hook)

(setq! doom-theme 'modus-vivendi)
(add-to-list 'default-frame-alist '(alpha-background . 85)) ; For all new frames henceforth
(setq! modus-themes-bold-constructs t)
(setq! modus-themes-italic-constructs t)
(setq! modus-themes-prompts '(bold))
;; Important!
(setq! modus-themes-scale-headings t)
(setq!  modus-themes-variable-pitch-ui t)

(setq! visible-bell nil)
(setq! ring-bell-function 'ignore)

(setq! fancy-splash-image (file-name-concat doom-user-dir "emacs-logo.png"))

(add-to-list '+doom-dashboard-menu-sections
    '("Open Journal"
     :icon (nerd-icons-octicon "nf-oct-note" :face 'doom-dashboard-menu-title)
     :key "SPC n j o"
     :when (featurep! :lang org +journal)
     :face (:inherit (doom-dashboard-menu-title))
     :action org-journal-open-current-journal-file)
)

(if (sud/font-installed? "FiraCode Nerd Font")
    (setq! doom-font (font-spec :family "FiraCode Nerd Font" :size 12 :weight 'semi-light)))

(if (sud/font-installed? "FiraCode Nerd Font Propo")
    (setq! doom-variable-pitch-font (font-spec :family "FiraCode Nerd Font Propo" :size 12)))

(if (sud/font-installed? "FiraCode Nerd Font Mono")
    (setq! doom-big-font (font-spec :family "FiraCode Nerd Font Mono" :size 16 :weight 'bold)))

(if (sud/font-installed? "NotoSerif Nerd Font")
    (setq! doom-serif-font (font-spec :family "Noto Serif Nerd Font" :size 12)))

(if (sud/font-installed? "Symbols Nerd Font")
    (setq! doom-symbol-font (font-spec :family "Symbols Nerd Font")
           doom-emoji-font (font-spec :family "Symbols Nerd Font")
           doom-unicode-font (font-spec :family "Symbols Nerd Font")
           ))

(setq! frame-title-format
    '((:eval (if (buffer-file-name) (abbreviate-file-name (buffer-file-name)) "%b"))
      (:eval (if (buffer-modified-p) "!")) " (" user-login-name "@" system-name ")"))

(setq! org-directory "~/org/")
(setq! org-agenda-files '("inbox.org" "work.org"))

;; Default tags
(setq! org-tag-alist '(
                      ;; locale
                      (:startgroup)
                      ("personal" . ?h)
                      ("work" . ?w)
                      (:endgroup)
                      (:newline)
                      ;; misc
                      ("writing")
                      ("review")
                      ("reading")))

;; Org-refile: where should org-refile look?
;;(setq! org-refile-targets 'FIXME)

;; Org-roam variables
(setq! org-roam-directory "~/org/roam/")
(setq! org-roam-index-file "~/org/roam/index.org")
(setq! org-roam-dailies-directory "journal/")
;;; Optional variables

;; Advanced: Custom link types
;; This example is for linking a person's 7-character ID to their page on the
;; free genealogy website Family Search.
(setq! org-link-abbrev-alist
      '(("family_search" . "https://www.familysearch.org/tree/person/details/%s")
        ("tarefa" . "http://itsmweb.bndes.net/servlet/ViewFormServlet?form=TMS%3ATask&server=itsm.bndes.net&eid=%s")
        ("incidente" . "http://itsmweb.bndes.net/servlet/ViewFormServlet?form=HPD%3AHelp+Desk&server=itsm.bndes.net&eid=%s")
        ("google" . "https://www.google.com/#q=%s")
        ("github" . "https://www.github.com/%s")
))

(add-hook 'org-ctrl-c-ctrl-c-hook 'orgsync)

(setq-default org-startup-indented t
              org-pretty-entities t
              org-use-sub-superscripts "{}"
              org-hide-emphasis-markers t
              org-startup-with-inline-images t
              org-image-actual-width '(300))
(use-package! toc-org
  :commands toc-org-enable
  :init (add-hook 'org-mode-hook 'toc-org-enable))

(after! org
(custom-set-faces
 '(org-level-1 ((t (:inherit outline-1 :height 1.5))))
 '(org-level-2 ((t (:inherit outline-2 :height 1.4))))
 '(org-level-3 ((t (:inherit outline-3 :height 1.3))))
 '(org-level-4 ((t (:inherit outline-4 :height 1.2))))
 '(org-level-5 ((t (:inherit outline-5 :height 1.1))))))

(setq! org-journal-dir "~/org/journal/"
      org-journal-file-format "%Y%m.org")
(after! org-journal
  (setq
   org-journal-date-format "%Y-%m-%d (%A)"
   org-journal-enable-agenda-integration t
   org-journal-file-type 'monthly
   org-icalendar-store-UID t
   org-icalendar-include-todo "all"
   org-icalendar-combined-agenda-file "~/org/org-journal.ics" ;; export with (org-icalendar-combine-agenda-files)
))

(after! org
        (setq! org-capture-templates
              '(("c" "Default Capture" entry (file "inbox.org")
                 "* TODO %?\n%U\n%i")
                ;; Capture and keep an org-link to the thing we're currently working with
                ("r" "Capture with Reference" entry (file "inbox.org")
                 "* TODO %?\n%U\n%i\n%a")
                ;; Define a section
                ("w" "Work")
                ("wm" "Work meeting" entry (file+headline "work.org" "Meetings")
                 "** TODO %?\n%U\n%i\n%a")
                ("wt" "Work task" entry (file+headline "work.org" "Tasks")
                 "** TODO %c\n%U\n[[tarefa:%c][remedy]]\n%?")
                ("wi" "Work incident" entry (file+headline "work.org" "Incidents")
                 "** TODO %c\n%U\n[[incidente:%c][remedy]]\n%?")
                ("wa" "Work adhoc" entry (file+headline "work.org" "Ad hoc")
                 "** TODO %?\n%U\n%i\n%a")
                ("wr" "Work report" entry (file+headline "work.org" "Reports")
                 "** TODO %?\n%U\n%i\n%a")
                )))

(after! org-roam
        (setq! org-roam-capture-templates
              '(("d" "default" plain "%?"
                 :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n") :unnarrowed t)

                ("i" "ideas" plain "%?"
                 :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n"))
                ))
        (setq! org-roam-dailies-capture-templates
              '(("d" "default" entry "* %<%I:%M %p>: %?"
                 :if-new (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))))
        )

(after! org
(setq! org-log-done 'time
      org-todo-keywords '((sequence "TODO" "WAITING" "DOING" "|" "DONE(!)" "CANCELLED(!)"))
;; Refile configuration
      org-outline-path-complete-in-steps nil
      org-refile-use-outline-path 'file))

(setq! org-agenda-custom-commands
      '(("n" "Agenda and All Todos"
         ((agenda)
          (todo)))
        ("w" "Work" agenda ""
         ((org-agenda-files '("work.org"))))))

;; Make exporting quotes better
(setq! org-export-with-smart-quotes t
      org-export-with-drawers nil
      org-export-with-todo-keywords nil
      org-export-with-broken-links t
      org-export-with-toc nil
      org-export-date-timestamp-format "%d %B %Y")
;; Export ODT to MS-Word
;;(setq-default org-odt-preferred-output-format "docx")
;; Export ODT to PDF
(setq-default org-odt-preferred-output-format "pdf")

(require 'org-tempo)

(after! magit
  (setq! magit-revision-show-gravatars '("^Author:     " . "^Commit:     ")
        magit-diff-refine-hunk 'all))

(setq! lsp-java-server-install-dir "~/.local/etc/eclipse.jdt.ls")

(setq! lsp-julia-package-dir nil)
(after! lsp-julia
  (setq! lsp-julia-default-environment "~/.julia/environments/v1.11"))

(setq! lsp-clients-lua-language-server-bin "~/.local/bin")



(use-package! lsp-ui
  :hook (lsp-mode . lsp-ui-mode))

;; Disable format-on-save behavior in Emacs Lisp buffers
 ;(setq-hook! 'emacs-lisp-mode-hook +format-inhibit t)

 ;; To permenantly disable a formatter:
 (after! csharp-mode
   (set-formatter! 'csharpier nil))

 ;; To define new formatters:
 ;; From modules/tools/docker/config.el:
 (after! dockerfile-mode
   (set-formatter! 'dockfmt '("dockfmt" "fmt" filepath) :modes '(dockerfile-mode)))

 ;; From modules/lang/sh/config.el:
 (after! sh-script
   (set-formatter! 'shfmt '("shfmt" "-ci"
                            (unless indent-tabs-mode
                              (list "-i" (number-to-string tab-width))))))

(setq! +format-on-save-disabled-modes
      '(emacs-lisp-mode  ; elisp's mechanisms are good enough
        sql-mode         ; sqlformat is currently broken
        tex-mode         ; latexindent is broken
        latex-mode
        sh-mode))

(setq! org-cite-csl-styles-dir "~/org/biblio")

(setq! citar-bibliography '("~/org/biblio/global.bib"))

;(setq! reftex-default-bibliography "/your/bib/file.bib")
(use-package! ox-latex
  :ensure nil
  :demand t
  :custom
  ;; Multiple LaTeX passes for bibliographies
  (org-latex-pdf-process
   '("pdflatex -interaction nonstopmode -output-directory %o %f"
     "bibtex %b"
     "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
     "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
  ;; Clean temporary files after export
  (org-latex-logfiles-extensions
   (quote ("lof" "lot" "tex~" "aux" "idx" "log" "out"
           "toc" "nav" "snm" "vrb" "dvi" "fdb_latexmk"
           "blg" "brf" "fls" "entoc" "ps" "spl" "bbl"
           "tex" "bcf"))))
(use-package! latex-preview-pane
  :defer t
  :commands  (latex-preview-pane-mode)
  :hook ((latex-mode . latex-preview-pane-mode)))
(use-package! ox-epub
  :demand t)

(after! ox-latex
        (add-to-list 'org-latex-classes
                     '("abntex2"
"[NO-DEFAULT-PACKAGES]
\\documentclass{abntex2}
\\usepackage{lmodern}
\\usepackage[T1]{fontenc}
\\usepackage[utf8]{inputenc}
\\usepackage{indentfirst}
\\usepackage{nomencl}
\\usepackage{color}
\\usepackage{graphicx}
\\usepackage{microtype}
\\usepackage[brazilian,hyperpageref]{backref}
\\usepackage[alf]{abntex2cite}
\\usepackage{fourier}
[EXTRA]"
                       ("\\section{%s}" . "\\section*{%s}")
                       ("\\subsection{%s}" . "\\subsection*{%s}")
                       ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                       ("\\paragraph{%s}" . "\\paragraph*{%s}")
                       ("\\subparagraph{%s}" . "\\subparagraph*{%s}")
                       )))

(setq! org-latex-hyperref-template
"\\hypersetup{
 pdftitle={%t},
 pdfauthor={%a},
 pdfsubject={%d},
 pdfcreator={%c},
 pdfkeywords={%k},
 pdflang={%L},
 colorlinks=true,
 linkcolor=blue,
 citecolor=blue,
 filecolor=magenta,
 urlcolor=blue,
 bookmarksdepth=4}
")
