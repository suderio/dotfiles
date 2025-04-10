;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(defun font-installed? (font-name)
  "Retorna t se a fonte font-name está instalada"
  (if (find-font (font-spec :name font-name))
      t nil))

(setq user-full-name "Paulo Suderio"
       user-mail-address "paulo.suderio@gmail.com")

(setq display-line-numbers-type 'relative)

(setq doom-theme 'doom-vibrant)

(setq fancy-splash-image (file-name-concat doom-user-dir "emacs-logo.png"))

(if (and (font-installed? "FiraCode Nerd Font") (font-installed? "FiraCode Nerd Font Mono"))
(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 12 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "FiraCode Nerd Font Mono" :size 13)))

(setq org-directory "~/Org/")

(after! magit
  (setq magit-revision-show-gravatars '("^Author:     " . "^Commit:     ")))
(after! magit
  (setq magit-diff-refine-hunk 'all))

(use-package! justl
  :config
  (map! :n "e" 'justl-exec-recipe))
