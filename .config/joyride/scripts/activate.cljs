(ns activate
  (:require ["vscode" :as vscode]
            [promesa.core :as p]
            [joyride.core :as joyride]))

;; -------------------------------------------------------------
;; 1. Utilitários para manipular o editor ativo
;; -------------------------------------------------------------
(defn active-editor []
  (.-activeTextEditor vscode/window))

(defn active-document []
  (some-> (active-editor) .-document))

;; -------------------------------------------------------------
;; 2. Registro dinâmico de comandos (defun interativo)
;; -------------------------------------------------------------
(defn duplicate-and-comment! []
  (when (active-editor)
    (p/do
      (vscode/commands.executeCommand "editor.action.copyLinesDownAction")
      (vscode/commands.executeCommand "editor.action.commentLine"))))

;; Registra no VS Code para uso via Command Palette ou atalho
(joyride/defcommand user.duplicate-and-comment
  "Duplica a linha atual e a comenta."
  duplicate-and-comment!)

;; -------------------------------------------------------------
;; 3. Hooks de eventos (add-hook)
;; -------------------------------------------------------------
(defonce ^:private listeners (atom []))

;; Limpa listeners anteriores em caso de reavaliação do arquivo
(doseq [d @listeners] (.dispose d))
(reset! listeners [])

;; Hook disparado ao salvar arquivos
(swap! listeners conj
  (vscode/workspace.onDidSaveTextDocument
    (fn [doc]
      (let [lang (.-languageId doc)
            file-name (.-fileName doc)]
        (when (= lang "clojure")
          (println (str "Salvo buffer Clojure: " file-name)))))))

(println "🚀 Joyride inicializado com sucesso!")

