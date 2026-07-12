#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ANSIBLE_ROLES_PATH="$SCRIPT_DIR/ansible/roles"

ansible-playbook -i ansible/inventory.ini ansible/site.yml "$@"
