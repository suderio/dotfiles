;;; functions.el -*- lexical-binding: t; -*-

;; Check if font is installed and change
(defun sud/font-installed? (font-name)
  "Retorna t se a fonte font-name está instalada"
  (if (find-font (font-spec :name font-name))
      t nil))

;; Create interactive commands from every executable in directory
;; An idea taken from sachachua
(after! dash
  (defmacro sud/convert-shell-scripts-to-interactive-commands (directory)
    "Make the shell scripts in DIRECTORY available as interactive commands."

    "An idea taken from [[https://pages.sachachua.com/.emacs.d/#scan-bin-and-turn-the-scripts-into-interactive-commands][sachachua]]"
    (cons 'progn
          (-map
           (lambda (filename)
             (let ((function-name (intern (concat "sud/" (file-name-nondirectory filename)))))
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
  ;; Creates commands for everything in .local/bin
  (sud/convert-shell-scripts-to-interactive-commands "~/.local/bin"))

;; Clones git repo from clipboard and opens dired when finished
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

;; Copies every DONE task to the dailies file
;; Taken from System Crafters
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

(defun sud/org-copiar-tarefa-concluida-para-journal ()
  "Copiar o item atual para o arquivo do org-journal quando for marcado como DONE.

A função, para ser usada em `org-after-todo-state-change-hook`,
identifica a mudança para um estado final (contido em
`org-done-keywords`) e usa `org-refile` para copiar a entrada
para o arquivo de journal do dia."
  (when (member (org-state) org-done-keywords)
    ;; A função `org-journal-find-location` JÁ CRIA o arquivo do dia
    ;; com o cabeçalho padrão se ele não existir. Portanto,
    ;; nenhuma verificação manual é necessária.
    (let ((journal-file (org-journal-find-location)))
      (when journal-file
        ;; Chama `org-refile` de forma não-interativa para copiar (KEEP = t).
        ;; `org-refile-targets` é temporariamente limitado ao arquivo de journal
        ;; para garantir que a cópia seja direcionada corretamente.
        (let ((org-refile-targets (list journal-file))
              (org-refile-use-outline-path nil)
              (org-refile-use-cache nil)
              (org-refile-log-note "")) ; Evita o prompt "Refile note:"
          (org-refile nil nil 'keep)))))
  (add-hook 'org-after-todo-state-change-hook #'meu/org-copiar-tarefa-concluida-para-journal))

;; Sync org files in github
(defun sud/orgsync ()
  "Call sync."
  (interactive)
  (sud/git-sync "-C" "~/org" "-s" "sync"))

;; Collapse all DONE tasks
(defun sud/org-hide-done-entries-in-buffer ()
  (interactive)
  (org-map-entries #'org-fold-hide-subtree
                   "/+DONE" 'file 'archive 'comment))

;; Fast note insertion
(defun sud/org-roam-node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (cons arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))

;; Rundeck
(defun sud/cria-mudanca ()
  (interactive "P")
  (sud/cria-mudança.sh (buffer-file-name)))

;;; Submete arquivos YAML para um job do Rundeck

(require 'json)
(require 'url)

(defun sud/get-env (var-name)
  "Retorna o valor da variável de ambiente VAR-NAME.
Primeiro tenta obter do ambiente do SO. Se não encontrar,
tenta encontrar uma variável Elisp com o mesmo nome."
  (or (getenv var-name)
      (when (boundp (intern var-name))
        (symbol-value (intern var-name)))))

(defun sud/submete-mudança (yaml-file)
  "Envia um arquivo YAML para um job do Rundeck e monitora sua execução.

A função requer que as seguintes variáveis de ambiente (ou variáveis Elisp)
estejam definidas:
- rundeck_url
- rundeck_dir
- rundeck_token
- rundeck_cria_mudanca_job_id"
  (interactive "fArquivo para enviar: ")
  (let* ((rundeck-url (sud/get-env "rundeck_url"))
         (rundeck-dir (sud/get-env "rundeck_dir"))
         (rundeck-token (sud/get-env "rundeck_token"))
         (job-id (sud/get-env "rundeck_cria_mudanca_job_id"))
         (file-name (file-name-nondirectory yaml-file))
         (dest-file (expand-file-name file-name rundeck-dir)))

    ;; --- Validação das variáveis ---
    (unless (and rundeck-dir (file-directory-p rundeck-dir))
      (error "Variável 'rundeck_dir' não configurada ou não é um diretório válido"))
    (when (or (null rundeck-token) (string-empty-p rundeck-token))
      (error "Variável 'rundeck_token' não configurada"))
    (when (or (null job-id) (string-empty-p job-id))
      (error "Variável 'rundeck_cria_mudanca_job_id' não configurada"))
    (when (or (null rundeck-url) (string-empty-p rundeck-url))
      (error "Variável 'rundeck_url' não configurada"))

    ;; 1. Copiar o arquivo
    (message "Enviando %s para %s..." file-name rundeck-dir)
    (copy-file yaml-file dest-file t) ; O 't' permite sobrescrever

    ;; 2. Chamar o job para criar a mudança
    (message "Iniciando job %s..." job-id)
    (let* ((url-request-method "POST")
           (url-request-extra-headers `(("Content-Type" . "application/json")
                                        ("Accept" . "application/json")
                                        ("X-Rundeck-Auth-Token" . ,rundeck-token)))
           (url-request-data (json-encode `(:argString ,(format "-nome_arquivo %s" file-name))))
           (api-url (format "%s/api/14/job/%s/run" rundeck-url job-id))
           (buffer (url-retrieve-synchronously api-url))
           execution-id)
      (with-current-buffer buffer
        (goto-char (point-min))
        ;; Pula os cabeçalhos HTTP para chegar ao corpo JSON
        (re-search-forward "\n\n")
        (let ((json-object-type 'hash-table))
          (setq execution-id (gethash "id" (json-read)))))
      (kill-buffer buffer)

      (unless execution-id
        (error "Não foi possível obter o ID da execução do Rundeck"))

      (message "Job iniciado com ID de execução: %s. Aguardando 60s..." execution-id)
      (sleep-for 60)

      ;; 3. Verificar o estado da execução
      (message "Verificando estado da execução %s..." execution-id)
      (let* ((state-url (format "%s/api/14/execution/%s/state" rundeck-url execution-id))
             (state-buffer (url-retrieve-synchronously state-url))
             execution-state)
        (with-current-buffer state-buffer
          (goto-char (point-min))
          (re-search-forward "\n\n")
          (let ((json-object-type 'hash-table))
            (setq execution-state (gethash "executionState" (json-read)))))
        (kill-buffer state-buffer)

        (unless (string= execution-state "succeeded")
          (error "Execução falhou com status: %s" execution-state))

        (message "Mudança processada com sucesso."))

      ;; 4. Obter a saída do job e exibir o ID da mudança
      (let* ((output-url (format "%s/api/14/execution/%s/output" rundeck-url execution-id))
             (output-buffer (url-retrieve-synchronously output-url))
             output-text)
        (with-current-buffer output-buffer
          (goto-char (point-min))
          (re-search-forward "\n\n")
          (setq output-text (buffer-string)))
        (kill-buffer output-buffer)

        (if-let ((change-id-line (car (seq-filter (lambda (line)
                                                    (string-match-p "^ID da mudança criada = " line))
                                                  (split-string output-text "\n")))))
            (message "%s" change-id-line)
          (message "Não foi possível encontrar o ID da mudança na saída do job."))))))

;; Para usar: M-x sud/submete-mudança RET /caminho/para/o/arquivo.yaml RET

(defun sud/submete-mudança-buffer ()
  (interactive)
  (sud/submete-mudança (buffer-file-name)))

;; Inbox notes
(defun sud/org-roam-capture-inbox ()
  (interactive)
  (org-roam-capture- :node (org-roam-node-create)
                     :templates '(("i" "inbox" plain "* %?"
                                   :if-new (file+head "Inbox.org" "#+title: Inbox\n")))))

;; Add to agenda based on tags
(defun sud/org-roam-filter-by-tag (tag-name)
  (lambda (node)
    (member tag-name (org-roam-node-tags node))))

(defun sud/org-roam-list-notes-by-tag (tag-name)
  (mapcar #'org-roam-node-file
          (seq-filter
           (sud/org-roam-filter-by-tag tag-name)
           (org-roam-node-list))))

(defun sud/org-roam-refresh-agenda-list ()
  (interactive)
  ;; TODO add more tags and files (ex. work.org)
  (setq org-agenda-files (sud/org-roam-list-notes-by-tag "Project")))
