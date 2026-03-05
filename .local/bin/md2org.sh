#!/usr/bin/env bash


# Configurações
SOURCE_DIR="$1"
DEST_DIR="$2"

# Garante que o diretório de destino existe
mkdir -p "$DEST_DIR"

# Busca recursiva
find "$SOURCE_DIR" -type f -name "*.md" -print0 | while IFS= read -r -d '' file; do
    # 1. Calcula o caminho relativo para manter a estrutura de pastas
    rel_path="${file#$SOURCE_DIR/}"
    output_file="$DEST_DIR/${rel_path%.md}.org"

    # 2. Cria a subpasta no destino se ela não existir
    mkdir -p "$(dirname "$output_file")"

    # 3. Gera metadados
    uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    title=$(pandoc "$file" --template <(echo '$title$'))
    [ -z "$title" ] && title=$(basename "${file%.md}")

    # 4. Constrói o arquivo Org
    {
        echo ":PROPERTIES:"
        echo ":ID:       $uuid"
        echo ":END:"
        echo "#+title: $title"
        echo ""
        pandoc "$file" -f markdown -t org
    } > "$output_file"

    echo "✅ Convertido: $rel_path -> $(basename "$output_file")"
done
