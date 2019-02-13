# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements; and to You under the Apache License, Version 2.0.

exportVars() {
    vname=$1
    vals=$2

    let "idx=0"
    for v in $vals; do
        export $(echo $vname$idx)=$v
        let "idx=idx+1"
    done
}

echo "The contents of /etc/resolv.conf are:"
cat /etc/resolv.conf

nameservers=$(grep -e ^nameserver /etc/resolv.conf | sed 's/nameserver //')
search=$(grep -e ^search /etc/resolv.conf | sed 's/search //')
options=$(grep -e ^option /etc/resolv.conf | sed 's/option //')

exportVars "CONFIG_whisk_containerFactory_containerArgs_dnsServers_" "$nameservers"
exportVars "CONFIG_whisk_containerFactory_containerArgs_dnsSearch_" "$search"
exportVars "CONFIG_whisk_containerFactory_containerArgs_dnsOptions_" "$options"
