#!/bin/bash

JKS_FILE=$1
PASSWORD=$2

if [[ -z "$JKS_FILE" || -z "$PASSWORD" ]]; then
  echo "Uso: $0 <arquivo.jks> <senha>"
  exit 1
fi

# 1. Listar todos os aliases do JKS
ALIASES=$(keytool -list -v -keystore "$JKS_FILE" -storepass "$PASSWORD" | grep "Alias name:" | awk '{print $3}')

echo "====================================================="
echo "   RELATÓRIO DE VALIDAÇÃO DE KEYSTORE (JKS)          "
echo "====================================================="

for ALIAS in $ALIASES; do
  echo -e "\n🔍 ANALISANDO ALIAS: $ALIAS"
  echo "-----------------------------------------------------"

  # Pasta temporária para análise
  TMP_JKS="/tmp/${ALIAS}_jks.pem"
  TMP_REMOTE="/tmp/${ALIAS}_remote.pem"

  # 2. Extrair certificado do JKS
  keytool -exportcert -alias "$ALIAS" -keystore "$JKS_FILE" -storepass "$PASSWORD" -rfc >"$TMP_JKS" 2>/dev/null

  if [ ! -s "$TMP_JKS" ]; then
    echo "❌ Erro ao extrair certificado do JKS para o alias $ALIAS."
    continue
  fi

  # 3. Verificar Validade Temporal
  VALID_DATES=$(openssl x509 -noout -dates -in "$TMP_JKS")
  echo "📅 $VALID_DATES"

  # 4. Verificar SAN (Subject Alternative Name)
  # Extrai a lista de SANs
  SAN_LIST=$(openssl x509 -noout -ext subjectAltName -in "$TMP_JKS" | grep -v "Subject Alternative Name" | tr -d '[:space:]' | tr ',' '\n')

  VALID_SAN=false

  for san in $SAN_LIST; do
    # Remove o prefixo 'DNS:' que o openssl adiciona
    clean_san=${san#DNS:}

    # Se for um Wildcard (ex: *.xpto.com)
    if [[ "$clean_san" == \** ]]; then
      # Transforma *.xpto.com em uma regex que valida subdomínios
      # Escapa os pontos e troca o * por uma regex de subdomínio
      suffix=${clean_san#*.}
      if [[ "$ALIAS" == *".$suffix" && "$ALIAS" != *.*."$suffix" ]]; then
        VALID_SAN=true
        break
      fi
    # Se for uma correspondência exata
    elif [[ "$clean_san" == "$ALIAS" ]]; then
      VALID_SAN=true
      break
    fi
  done

  if [ "$VALID_SAN" = true ]; then
    echo "✅ SAN: Domínio '$ALIAS' autorizado (via correspondência direta ou Wildcard)."
  else
    echo "❌ AVISO SAN: '$ALIAS' NÃO autorizado. Certificado cobre: $SAN_LIST"
  fi
  # 5. Comparação com Certificado Remoto (URL)
  echo "🌐 Conectando a https://$ALIAS..."
  echo | openssl s_client -connect "${ALIAS}:443" -servername "$ALIAS" 2>/dev/null | openssl x509 >"$TMP_REMOTE"

  if [ -s "$TMP_REMOTE" ]; then
    FP_JKS=$(openssl x509 -noout -fingerprint -sha256 -in "$TMP_JKS")
    FP_REMOTE=$(openssl x509 -noout -fingerprint -sha256 -in "$TMP_REMOTE")

    if [ "$FP_JKS" == "$FP_REMOTE" ]; then
      echo "✅ INTEGRIDADE: O certificado no JKS é idêntico ao da URL."
    else
      echo "❌ DIVERGÊNCIA: O certificado local difere do remoto!"
    fi
  else
    echo "❓ Não foi possível obter o certificado remoto para $ALIAS."
  fi

  # 6. Verificação da Cadeia de Confiança (Trust Chain)
  # Tenta verificar o certificado contra o próprio JKS (caso ele seja uma TrustStore)
  echo "🛡️  Verificando Cadeia de Confiança..."
  openssl verify -CAfile <(keytool -list -rfc -keystore "$JKS_FILE" -storepass "$PASSWORD") "$TMP_JKS" >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "✅ CADEIA: Certificado confiável dentro deste Keystore."
  else
    echo "❌ CADEIA: Certificado NÃO possui cadeia completa/confiável no Keystore."
  fi

  # Limpeza
  rm -f "$TMP_JKS" "$TMP_REMOTE"
done

echo -e "\n====================================================="
