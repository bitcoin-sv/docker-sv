#!/bin/bash
set -e

core_pattern=$(cat /proc/sys/kernel/core_pattern)
pattern_start="$(echo $core_pattern | head -c 1)"

# In case core pattern doesn't start with pipe make sure that specified
# directory exists and has sufficient permissions to write core dump.
if [[ $pattern_start != "|" ]]; then
	directory=`dirname "$core_pattern"`
	mkdir -p "$directory"
	chmod 777 "$directory"
fi

if [[ "$1" == "bitcoin-cli" || "$1" == "bitcoin-tx" || "$1" == "bitcoind" || "$1" == "test_bitcoin" ]]; then
	mkdir -p "$BITCOIN_DATA"

	if [[ ! -s "$BITCOIN_DATA/bitcoin.conf" ]]; then
		cat <<-EOF > "$BITCOIN_DATA/bitcoin.conf"
		printtoconsole=1
		rpcallowip=::/0
		rpcpassword=${BITCOIN_RPC_PASSWORD:-password}
		rpcuser=${BITCOIN_RPC_USER:-bitcoin}
		excessiveblocksize=1000000000
		maxstackmemoryusageconsensus=100000000
		EOF
		chown bitcoin:bitcoin "$BITCOIN_DATA/bitcoin.conf"
	fi

	# ensure correct ownership and linking of data directory
	# we do not update group ownership here, in case users want to mount
	# a host directory and still retain access to it
	chown -R bitcoin "$BITCOIN_DATA"
	ln -sfn "$BITCOIN_DATA" /home/bitcoin/.bitcoin
	chown -h bitcoin:bitcoin /home/bitcoin/.bitcoin

	exec gosu bitcoin "$@"
fi

exec "$@"
