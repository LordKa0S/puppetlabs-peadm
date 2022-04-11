#!/bin/bash

hostname=$(hostname -f)
version=$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)
arch=$(uname -m)
if grep -qi ubuntu /etc/os-release; then
  osfamily="ubuntu"
elif grep -qi sles /etc/os-release; then
  osfamily="sles"
else
  osfamily="el"
fi

# OS-specific modifications
[ "$osfamily" = "ubuntu" -a "$arch" = "x86_64" ] && arch="amd64"
[ "$osfamily" = "el"  ] || [ "$osfamily" = "sles"  ]  && version=$(echo "$version" | cut -d . -f 1)

# Output a JSON result for ease of Task usage in Puppet Task Plans
cat <<EOS
  {
    "hostname": "${hostname}",
    "platform": "${osfamily}-${version}-${arch}"
  }
EOS
