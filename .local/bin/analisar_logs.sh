#!/usr/bin/env bash
# ==============================================================================
# Função: analisar_logs
#
# Descrição:
#   Processa um arquivo de log para extrair, contar e classificar endpoints
#   acessados dentro de um intervalo de tempo específico.
#
# Uso:
#   analisar_logs [-i "data_inicial"] [-f "data_final"] <arquivo_de_log>
#
# Opções:
#   -i <data>  (Opcional) Data Inicial no formato "DD/Mon/YYYY:HH:MM:SS".
#              Se omitida, o padrão é a meia-noite do dia atual.
#
#   -f <data>  (Opcional) Data Final no formato "DD/Mon/YYYY:HH:MM:SS".
#              Se omitida, o padrão é a meia-noite do dia seguinte.
#
# Parâmetros:
#   arquivo_de_log (Obrigatório) O caminho para o arquivo de log que será analisado.
#
# Retorno:
#   - Em caso de sucesso, exibe a contagem de acessos aos endpoints.
#   - Em caso de erro, exibe uma mensagem no stderr e retorna um código de saída != 0.
#
# Exemplos:
#   ./script_analise.sh -i "22/Jul/2025:10:00:00" -f "22/Jul/2025:11:00:00" access.log
#   ./script_analise.sh access.log
# ==============================================================================
analisar_logs() {
    # --- 1. Tratamento de Parâmetros com getopts ---

    # Zera o índice de opções, importante se a função for chamada múltiplas vezes no mesmo shell.
    OPTIND=1

    # Inicializa as variáveis de data.
    local data_inicial=""
    local data_final=""

    # Processa as opções (-i e -f) usando o getopts.
    # O ":" após cada letra (i:f:) indica que a opção espera um argumento.
    # O primeiro ":" (:i:f:) habilita o modo silencioso para tratar erros manualmente.
    while getopts ":i:f:" opt; do
        case ${opt} in
            i)
                data_inicial="$OPTARG"
                ;;
            f)
                data_final="$OPTARG"
                ;;
            \?) # Caso de opção inválida
                echo "Erro: Opção inválida: -$OPTARG" >&2
                return 1
                ;;
            :) # Caso de opção sem o argumento esperado
                echo "Erro: A opção -$OPTARG requer um argumento." >&2
                return 1
                ;;
        esac
    done

    # Remove da lista de parâmetros todas as opções que já foram processadas pelo getopts.
    shift "$((OPTIND - 1))"

    # O que sobrar na lista de parâmetros é o nome do arquivo.
    local arquivo="$1"

    # --- 2. Validação e Definição de Padrões ---

    # Validação do parâmetro obrigatório: nome do arquivo.
    if [[ -z "$arquivo" ]]; then
        echo "Erro: O nome do arquivo é um parâmetro obrigatório." >&2
        echo "Uso: analisar_logs [-i data_inicial] [-f data_final] <nome_do_arquivo>" >&2
        return 1
    fi

    # Verifica se o arquivo existe e se pode ser lido.
    if [[ ! -r "$arquivo" ]]; then
        echo "Erro: O arquivo '$arquivo' não existe ou não possui permissão de leitura." >&2
        return 1
    fi

    # Define a data inicial padrão se a opção -i não for fornecida.
    # O formato agora é "DD/Mon/YYYY:HH:MM:SS" para corresponder ao solicitado.
    if [[ -z "$data_inicial" ]]; then
        # LC_ALL=C garante que o mês seja em inglês (ex: Jul), que é comum em logs.
        data_inicial=$(LC_ALL=C date '+%d/%b/%Y:00:00:00')
        echo "Info: Data inicial não informada. Usando o padrão: $data_inicial" >&2
    fi

    # Define a data final padrão se a opção -f não for fornecida.
    if [[ -z "$data_final" ]]; then
        data_final=$(LC_ALL=C date -d "tomorrow" '+%d/%b/%Y:00:00:00')
        echo "Info: Data final não informada. Usando o padrão: $data_final" >&2
    fi

    # --- 3. Execução do Comando de Análise ---

    sed -n "/$data_inicial/,/$data_final/p" "$arquivo" | \
    awk '{print $7}' | \
    cut --delimiter=/ -f2 | \
    cut --delimiter=? -f1 | \
    sort | \
    uniq -c | \
    sort -rn
}

# --- Chamada da Função ---
# Chama a função 'analisar_logs' passando todos os argumentos
# que foram recebidos pelo script.
analisar_logs "$@"
