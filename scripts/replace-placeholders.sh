#!/usr/bin/env bash
# Substitui os placeholders nos manifestos YAML com os valores do config.env
# Uso: bash scripts/replace-placeholders.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SCRIPT_DIR/config.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Erro: arquivo $CONFIG_FILE não encontrado."
  echo "Copie scripts/config.env.example para scripts/config.env e preencha seus valores."
  exit 1
fi

# Carregar variáveis do arquivo de configuração
source "$CONFIG_FILE"

# Verificar variáveis obrigatórias
REQUIRED_VARS=(
  AWS_ACCOUNT_ID CLUSTER_NAME AWS_REGION KMS_KEY_ARN
  HARBOR_S3_BUCKET GITHUB_USERNAME HARBOR_ADMIN_PASSWORD HARBOR_ALB_HOSTNAME
)

for VAR in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!VAR:-}" ]]; then
    echo "Erro: variável $VAR não definida em $CONFIG_FILE"
    exit 1
  fi
done

echo "Substituindo placeholders em: $REPO_ROOT"

# Encontrar todos os arquivos YAML e substituir placeholders
find "$REPO_ROOT" \
  -type f \
  \( -name "*.yaml" -o -name "*.yml" \) \
  -not -path "*/scripts/*" \
  | while read -r FILE; do
    sed -i.bak \
      -e "s|<AWS_ACCOUNT_ID>|$AWS_ACCOUNT_ID|g" \
      -e "s|<CLUSTER_NAME>|$CLUSTER_NAME|g" \
      -e "s|<AWS_REGION>|$AWS_REGION|g" \
      -e "s|<KMS_KEY_ARN>|$KMS_KEY_ARN|g" \
      -e "s|<HARBOR_S3_BUCKET>|$HARBOR_S3_BUCKET|g" \
      -e "s|<GITHUB_USERNAME>|$GITHUB_USERNAME|g" \
      -e "s|<HARBOR_ADMIN_PASSWORD>|$HARBOR_ADMIN_PASSWORD|g" \
      -e "s|<HARBOR_ALB_HOSTNAME>|$HARBOR_ALB_HOSTNAME|g" \
      "$FILE"
    rm -f "$FILE.bak"
    echo "  ✓ $FILE"
done

echo ""
echo "Concluído. Verifique os arquivos antes de fazer push para o repositório privado."
echo "Para reverter: git checkout -- ."
