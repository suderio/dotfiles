;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(defun font-installed? (font-name)
  "Retorna t se a fonte font-name está instalada"
  (if (find-font (font-spec :name font-name))
      t nil))

(setq user-full-name "Paulo Suderio"
      user-mail-address "paulo.suderio@gmail.com")

(setq display-line-numbers-type 'relative
      evil-respect-visual-line-mode t
      which-key-idle-delay 0.8
      which-key-max-description-length 55
      which-key-separator " → " )

(map! :leader :desc "Open Journal" "n j o" #'org-journal-open-current-journal-file)

(setq global-auto-revert-mode-text "󰀘"
      global-auto-revert-non-file-buffers t)

(setenv "LANG" "pt_BR,en_US")
(setq-default ispell-program-name "hunspell")
(with-eval-after-load "ispell"
  (setq ispell-really-hunspell t)
  (setq ispell-program-name "hunspell")
  (setq ispell-dictionary "pt_BR,en_US")
  ;; ispell-set-spellchecker-params has to be called
  ;; before ispell-hunspell-add-multi-dic will work
  (ispell-set-spellchecker-params)
  (ispell-hunspell-add-multi-dic "pt_BR,en_US"))

(setq doom-theme 'doom-vibrant)
(add-to-list 'default-frame-alist '(alpha-background . 85)) ; For all new frames henceforth

(setq visible-bell nil)
(setq ring-bell-function 'ignore)

(setq fancy-splash-image (file-name-concat doom-user-dir "emacs-logo.png"))

(add-to-list '+doom-dashboard-menu-sections
    '("Open Journal"
     :icon (nerd-icons-octicon "nf-oct-note" :face 'doom-dashboard-menu-title)
     :key "SPC n j o"
     :when (featurep! :lang org +journal)
     :face (:inherit (doom-dashboard-menu-title))
     :action org-journal-open-current-journal-file)
)

(if (font-installed? "FiraCode Nerd Font")
    (setq doom-font (font-spec :family "FiraCode Nerd Font" :size 12 :weight 'semi-light)))

(if (font-installed? "FiraCode Nerd Font Propo")
    (setq doom-variable-pitch-font (font-spec :family "FiraCode Nerd Font Propo" :size 13)))

(if (font-installed? "FiraCode Nerd Font Mono")
    (setq doom-big-font (font-spec :family "FiraCode Nerd Font Mono" :size 16 :weight 'bold)))

(if (font-installed? "Noto Serif")
    (setq doom-serif-font (font-spec :family "Noto Serif" :size 12)))

(setq frame-title-format
    '((:eval (if (buffer-file-name) (abbreviate-file-name (buffer-file-name)) "%b"))
      (:eval (if (buffer-modified-p) "!")) " (" user-login-name "@" system-name ")"))

(setq org-directory "~/org/")
(setq org-agenda-files '("inbox.org" "work.org"))

;; Default tags
(setq org-tag-alist '(
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
;;(setq org-refile-targets 'FIXME)

;; Org-roam variables
(setq org-roam-directory "~/org/roam/")
(setq org-roam-index-file "~/org/roam/index.org")
;;; Optional variables

;; Advanced: Custom link types
;; This example is for linking a person's 7-character ID to their page on the
;; free genealogy website Family Search.
(setq org-link-abbrev-alist
      '(("family_search" . "https://www.familysearch.org/tree/person/details/%s")
        ("tarefa" . "http://itsmweb.bndes.net/servlet/ViewFormServlet?form=TMS%3ATask&server=itsm.bndes.net&eid=%s")
        ("incidente" . "http://itsmweb.bndes.net/servlet/ViewFormServlet?form=HPD%3AHelp+Desk&server=itsm.bndes.net&eid=%s")
        ))

(setq-default org-startup-indented t
              org-pretty-entities t
              org-use-sub-superscripts "{}"
              org-hide-emphasis-markers t
              org-startup-with-inline-images t
              org-image-actual-width '(300))

(custom-set-faces
 '(org-level-1 ((t (:inherit outline-1 :height 1.5))))
 '(org-level-2 ((t (:inherit outline-2 :height 1.4))))
 '(org-level-3 ((t (:inherit outline-3 :height 1.3))))
 '(org-level-4 ((t (:inherit outline-4 :height 1.2))))
 '(org-level-5 ((t (:inherit outline-5 :height 1.1)))))

(setq org-journal-dir "~/org/journal/"
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
(setq org-capture-templates
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

(after! org
(setq org-log-done 'time
      org-todo-keywords '((sequence "TODO" "WAITING" "DOING" "|" "DONE(!)" "CANCELLED(!)"))
;; Refile configuration
      org-outline-path-complete-in-steps nil
      org-refile-use-outline-path 'file))

(setq org-agenda-custom-commands
      '(("n" "Agenda and All Todos"
         ((agenda)
          (todo)))
        ("w" "Work" agenda ""
         ((org-agenda-files '("work.org"))))))

;; Make exporting quotes better
(setq org-export-with-smart-quotes t
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
  (setq magit-revision-show-gravatars '("^Author:     " . "^Commit:     ")))
(after! magit
  (setq magit-diff-refine-hunk 'all))

(setq lsp-julia-package-dir nil)
(after! lsp-julia
  (setq lsp-julia-default-environment "~/.julia/environments/v1.11"))

(setq! org-cite-csl-styles-dir "~/org/biblio")

(setq! citar-bibliography '("~/org/biblio/global.bib"))
