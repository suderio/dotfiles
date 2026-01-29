#!/bin/bash

# Parâmetros
JKS_FILE=$1
PASSWORD=$2
ALIAS=$3
# Se o quarto parâmetro estiver vazio, usa o ALIAS como alvo da conexão
REMOTE=${4:-$ALIAS}

if [[ -z "$JKS_FILE" || -z "$PASSWORD" || -z "$ALIAS" ]]; then
    echo "Uso: $0 <arquivo.jks> <senha> <alias_no_jks> [dominio_remoto_opcional]"
    exit 1
fi

TMP_DIR=$(mktemp -d)
REMOTE_CERT="$TMP_DIR/remote.pem"

echo "-------------------------------------------------------"
echo "Target JKS: $JKS_FILE"
echo "Alias:      $ALIAS"
echo "Conectando: $REMOTE"
echo "-------------------------------------------------------"

# 1. Download do certificado (e cadeia de intermediários via -showcerts)
# O timeout de 10s evita que o script trave em caso de rede instável
echo "🌐 Baixando certificado de https://$REMOTE..."
timeout 10s openssl s_client -connect "${REMOTE}:443" -servername "$REMOTE" -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM > "$REMOTE_CERT"

# 2. Verifica se o arquivo foi criado e não está vazio
if [[ ! -s "$REMOTE_CERT" ]]; then
    echo "❌ Erro: Não foi possível obter o certificado de $REMOTE."
    rm -rf "$TMP_DIR"
    exit 0 # Encerra sem erro para não quebrar automações
fi

echo "✅ Certificado baixado com sucesso."

# 3. Remover entrada antiga no JKS
# Necessário para que o import não falhe por 'Alias já existente'
echo "🗑️  Limpando entrada antiga '$ALIAS' no JKS..."
keytool -delete -alias "$ALIAS" -keystore "$JKS_FILE" -storepass "$PASSWORD" 2>/dev/null

# 4. Importar o novo certificado com a cadeia de confiança
# -trustcacerts: Usa os certificados do sistema/jks para validar a cadeia
echo "📥 Importando novo certificado..."
keytool -importcert -trustcacerts -file "$REMOTE_CERT" \
    -alias "$ALIAS" \
    -keystore "$JKS_FILE" \
    -storepass "$PASSWORD" \
    -noprompt

if [ $? -eq 0 ]; then
    echo "🎉 SUCESSO: O alias '$ALIAS' foi atualizado com o certificado vindo de $REMOTE."
else
    echo "❌ ERRO: Falha ao importar o certificado no Keystore."
fi

# Limpeza
rm -rf "$TMP_DIR"
