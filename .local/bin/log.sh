#!/bin/bash

if [[ $# != 3 ]]
  then
      echo "Argumento inválido. > log.sh <DATA_INICIAL> <DATA_FINAL> <ARQUIVO>"
      exit 0
fi

ARQUIVO="$3"
DIA_INICIAL=$(date -d "$1" +%d)
MES_INICIAL=$(date -d "$1" +%b)
ANO_INICIAL=$(date -d "$1" +%Y)

DIA_FINAL=$(date -d "$2" +%d)
MES_FINAL=$(date -d "$2" +%b)
ANO_FINAL=$(date -d "$2" +%Y)

printf "Logs entre %s/%s/%s e %s/%s/%s\n" "$DIA_INICIAL" "$MES_INICIAL" "$ANO_INICIAL" "$DIA_FINAL" "$MES_FINAL" "$ANO_FINAL"

awk '/^\[$DIA_INICIAL\/$MES_INICIAL\/$ANO_INICIAL.*/,/$DIA_FINAL\/$MES_FINAL\/$ANO_FINAL.*/ {print $9, $7}' \
  <(gzip -dc "$ARQUIVO") \
  | cut --delimiter=\& -f1 \
  | cut --delimiter=: -f1 \
  | cut --delimiter== -f1 \
  | sort \
  | uniq -c \
  | sort -rn
