#!/usr/bin/env bash
CONFIG_FILE="huly_v7.conf"
# Parse command line arguments
RESET_VOLUMES=false
SECRET=false
for arg in "$@"; do
    case $arg in
        --secret)
            SECRET=true
            ;;
        --reset-volumes)
            RESET_VOLUMES=true
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --secret         Generate a new secret key"
            echo "  --reset-volumes  Reset all volume paths to default Docker named volumes"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done
if [ "$RESET_VOLUMES" == true ]; then
    echo -e "\033[33m--reset-volumes flag detected: Resetting all volume paths to default Docker named volumes.\033[0m"
    sed -i \
        -e '/^VOLUME_ELASTIC_PATH=/s|=.*|=|' \
        -e '/^VOLUME_FILES_PATH=/s|=.*|=|' \
        -e '/^VOLUME_CR_DATA_PATH=/s|=.*|=|' \
        -e '/^VOLUME_CR_CERTS_PATH=/s|=.*|=|' \
        -e '/^VOLUME_REDPANDA_PATH=/s|=.*|=|' \
        "$CONFIG_FILE"
    exit 0
fi
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi
# Disable interactive prompts on Railway to prevent build hang
_HOST_ADDRESS="${HOST_ADDRESS:-localhost}"
_HTTP_PORT="${HTTP_PORT:-80}"
_SECURE="${SECURE:-}"

# Skip all interactive prompts and volume config -- set defaults if not already present

if [ ! -f .huly.secret ] || [ "$SECRET" == true ]; then
  openssl rand -hex 32 > .huly.secret
  echo "Secret generated and stored in .huly.secret"
else
  echo -e "\033[33m.huly.secret already exists, not overwriting."
  echo "Run this script with --secret to generate a new secret."
fi

if [ ! -f .cr.secret ]; then
  openssl rand -hex 32 > .cr.secret
  echo "Secret generated and stored in .cr.secret"
fi

if [ ! -f .rp.secret ]; then
  openssl rand -hex 32 > .rp.secret
  echo "Secret generated and stored in .rp.secret"
fi

export HOST_ADDRESS=$_HOST_ADDRESS
export SECURE=$_SECURE
export HTTP_PORT=$_HTTP_PORT
export HTTP_BIND=$HTTP_BIND
export TITLE=${TITLE:-Huly}
export DEFAULT_LANGUAGE=${DEFAULT_LANGUAGE:-en}
export LAST_NAME_FIRST=${LAST_NAME_FIRST:-true}
export CR_DATABASE=${CR_DATABASE:-defaultdb}
export CR_USERNAME=${CR_USERNAME:-selfhost}
export REDPANDA_ADMIN_USER=${REDPANDA_ADMIN_USER:-superadmin}
export VOLUME_ELASTIC_PATH=$_VOLUME_ELASTIC_PATH
export VOLUME_FILES_PATH=$_VOLUME_FILES_PATH
export VOLUME_CR_DATA_PATH=$_VOLUME_CR_DATA_PATH
export VOLUME_CR_CERTS_PATH=$_VOLUME_CR_CERTS_PATH
export VOLUME_REDPANDA_PATH=$_VOLUME_REDPANDA_PATH
export HULY_SECRET=$(cat .huly.secret)
export COCKROACH_SECRET=$(cat .cr.secret)
export REDPANDA_SECRET=$(cat .rp.secret)
# Commented out: Railway build does not support envsubst
# envsubst < .template.huly.conf > $CONFIG_FILE

source "$CONFIG_FILE"
export CR_DB_URL=$CR_DB_URL

echo -e "\n\033[1;34mConfiguration Summary:\033[0m"
echo -e "Host Address: \033[1;32m$_HOST_ADDRESS\033[0m"
echo -e "HTTP Port: \033[1;32m$_HTTP_PORT\033[0m"
if [[ -n "$SECURE" ]]; then
    echo -e "SSL Enabled: \033[1;32mYes\033[0m"
else
    echo -e "SSL Enabled: \033[1;31mNo\033[0m"
fi
echo -e "Elasticsearch Volume: \033[1;32m${_VOLUME_ELASTIC_PATH:-Docker named volume}\033[0m"
echo -e "Files Volume: \033[1;32m${_VOLUME_FILES_PATH:-Docker named volume}\033[0m"
echo -e "CockroachDB Volume: \033[1;32m${_VOLUME_CR_DATA_PATH:-Docker named volume}\033[0m"
echo -e "CockroachDB Certs Volume: \033[1;32m${_VOLUME_CR_CERTS_PATH:-Docker named volume}\033[0m"
echo -e "Redpanda Volume: \033[1;32m${_VOLUME_REDPANDA_PATH:-Docker named volume}\033[0m"

# Remove or comment out Docker/compose and nginx commands, which won't work on Railway
# read -p "Do you want to run 'docker compose up -d' now to start Huly? (Y/n): " RUN_DOCKER
# case "${RUN_DOCKER:-Y}" in
#     [Yy]* )
#          echo -e "\033[1;32mRunning 'docker compose up -d' now...\033[0m"
#          docker compose up -d
#          ;;
#     [Nn]* )
#         echo "You can run 'docker compose up -d' later to start Huly."
#         ;;
# esac

echo -e "\033[1;32mSetup is complete!"
# Commented: ./nginx.sh requires nginx, which Railway does not provide by default
# ./nginx.sh
