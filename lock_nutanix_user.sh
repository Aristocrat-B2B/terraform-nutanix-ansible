#!/usr/bin/env bash

# Expected env variables
# SSH_USER - service user name to be created
# SSH_PASSWORD - password for the service user
# Argument #1 is expected to be host name/ip
HOST="${1}"

ensure_var_present() {
  arg_name="${1}"
  arg_value="${!arg_name}"

  if [[ -z ${arg_value} ]]; then
    echo "Nutanix user lock can't be performed as '${arg_name}' parameter was not specified"
    exit 1
  fi
}

ensure_var_present 'SSH_USER'
ensure_var_present 'SSH_PASSWORD'
ensure_var_present 'HOST'

INVALID_PSWD_ERROR=5

echo "Checking whether nutanix user has been locked on the host '${HOST}'..."
sshpass -p nutanix ssh -o StrictHostKeyChecking=no "nutanix@${HOST}" 'echo ok'
remote_rslt=$?

if [[ ${remote_rslt} -eq 0 ]]; then
  echo "Nutanix user has not been locked yet on the host '${HOST}'. Checking whether new service user has been created..."

  sshpass -p "${SSH_PASSWORD}" ssh -o StrictHostKeyChecking=no "${SSH_USER}@${HOST}" 'echo ok'
  remote_rslt=$?

  if [[ ${remote_rslt} -eq 0 ]]; then
    echo "New service user has been created earlier on the host '${HOST}'"
  elif [[ ${remote_rslt} -eq ${INVALID_PSWD_ERROR} ]]; then
    echo "New service user has not been created on the host '${HOST}'. Creating it..."
    sshpass -p nutanix ssh -o StrictHostKeyChecking=no "nutanix@${HOST}" "echo 'nutanix' | sudo -S useradd -m -g sudo -c 'Service Account for Ansible' -s /bin/bash -p \$(echo '${SSH_PASSWORD}' | openssl passwd -1 -stdin) ${SSH_USER}"
    remote_rslt=$?

    if [[ ${remote_rslt} -eq 0 ]]; then
      echo "New service user has just been created on the host '${HOST}'"
    else
      echo "Failed to create new service user on the host '${HOST}'. sshpass error was '${remote_rslt}'"
      exit ${remote_rslt}
    fi
  else
    echo "Unexpected error '${remote_rslt}' happened during an attempt to check new service user status on the host '${HOST}'"
    exit ${remote_rslt}
  fi

  echo "Locking nutanix user on the host '${HOST}'"
  sshpass -p "${SSH_PASSWORD}" ssh -o StrictHostKeyChecking=no "${SSH_USER}@${HOST}" "echo '${SSH_PASSWORD}' | sudo -S usermod -L -s /sbin/nologin nutanix"
  remote_rslt=$?

  if [[ ${remote_rslt} -eq 0 ]]; then
    echo "Nutanix user has just been locked on the host '${HOST}'"
  else
    echo "Failed to lock nutanix user on the host '${HOST}'. sshpass error was '${remote_rslt}'"
    exit ${remote_rslt}
  fi
elif [[ ${remote_rslt} -eq ${INVALID_PSWD_ERROR} ]]; then
  echo "Nutanix user has been locked earlier on the host '${HOST}'"
else
  echo "Unexpected error '${remote_rslt}' happened during an attempt to check nutanix user status on the host '${HOST}'"
  exit ${remote_rslt}
fi
