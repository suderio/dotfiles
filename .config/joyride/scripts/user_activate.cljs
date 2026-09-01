(ns activate
  (:require ["vscode" :as vscode]
            [promesa.core :as p]
            [joyride.core :as joyride]
            [clojure.string :as str]))
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

(defn reformat-job-entry! []
  (let [editor (.-activeTextEditor vscode/window)]
    (if-not editor
      (vscode/window.showErrorMessage "Nenhum editor ativo encontrado.")
      (let [doc (.-document editor)
            pos (.. editor -selection -active)
            current-line-num (.-line pos)
            total-lines (.-lineCount doc)]

        ;; Validação: verifica se há pelo menos 3 linhas a partir da posição atual
        (if (> (+ current-line-num 3) total-lines)
          (vscode/window.showErrorMessage "Não há linhas suficientes abaixo da linha atual para processar.")
          
          (let [line0 (.. doc (lineAt current-line-num) -text)
                line1 (.. doc (lineAt (+ current-line-num 1)) -text)
                line2 (.. doc (lineAt (+ current-line-num 2)) -text)
                
                ;; Regex para capturar: [dia1 hora1 dia2 hora2]
                pattern #"^(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2}:\d{2})\s+(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2}:\d{2})"
                match (re-find pattern (str/trim line0))]

            (cond
              (nil? match)
              (vscode/window.showErrorMessage 
               (str "Formato inválido na linha atual. Esperado: DD/MM/AAAA HH:MM:SS DD/MM/AAAA HH:MM:SS"))

              :else
              (let [[_ day1 start day2 end] match]
                (if (not= day1 day2)
                  ;; Validação dos dias
                  (vscode/window.showErrorMessage 
                   (str "Erro: As datas de início e fim são diferentes! (" day1 " != " day2 ")"))

                  ;; Executa a substituição das 3 linhas
                  (let [day   day1
                        inc   (str/trim line1)
                        job   (str/trim line2)
                        
                        output-text (str "day: " day "\n"
                                         "start: " start "\n"
                                         "end: " end "\n"
                                         "inc: " inc "\n"
                                         "text: execução do job " job)
                        
                        ;; Seleciona do início da linha 0 ao final da linha 2
                        start-pos (.. doc (lineAt current-line-num) -range -start)
                        end-pos   (.. doc (lineAt (+ current-line-num 2)) -range -end)
                        range-to-replace (vscode/Range. start-pos end-pos)]

                    (.edit editor
                           (fn [edit-builder]
                             (.replace edit-builder range-to-replace output-text))))))))))))
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

