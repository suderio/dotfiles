#!/bin/bash

if [ ! -e $1 ]; then
  exit 1
fi

if [ ! -e .env ]; then
  exit 2
fi

source .env

if [ ! -d "$rundeck_dir" ]; then
  exit 3
fi

cp "$1" "$rundeck_dir"/$(basename "$1")
BODY="{\"argString\":\"-nome_arquivo $nome_arquivo\",}"
curl -s -X POST --data "$BODY" \
  -H "Content-Type:application/json" \
  -H "X-Rundeck-Auth-Token:$rundeck_token" \
  "$rundeck_job_cria_mudanca"
