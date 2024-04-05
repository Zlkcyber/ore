#!/bin/bash
INSTALLATION_DIR=$(dirname "$(realpath "$0")")
curl https://sh.rustup.rs -sSf | sh
sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
source ~/.profile
cargo install ore-cli
echo '#!/bin/bash' > master_miner.sh
read -p "How many miner do you want to generate? " NUM
solana-keygen new -o id.json
solana address -k id.json
for ((i=1; i<=$NUM; i++))
do
  tee mine$i.sh > /dev/null <<EOF
  while true; do
    echo "Mining $i starting..."
    ore --rpc https://api.mainnet-beta.solana.com --keypair ${INSTALLATION_DIR}/id.json --priority-fee 1000 mine --threads 4
    echo "Mining $i finished."
  done
EOF
  echo "sh mine$i.sh >> miner.log 2>&1 & echo \$! >> miner.pid" >> master_miner.sh
done
chmod ug+x mine*.sh

tee add_miner.sh > /dev/null <<EOF
  highest=0
  for file in id*.json; do
    num=\${file//[^0-9]/}
    if [ -n "\$num" ] && [ "\$num" -gt "\$highest" ]; then
      highest=\$num
    fi
  done
  i=\$((highest+1))
  echo '#!/bin/bash' > mine\$i.sh
  echo "while true; do" >> mine\$i.sh
  echo "  echo "Mining \$i starting..."" >> mine\$i.sh
  echo "  ore --rpc https://api.mainnet-beta.solana.com --keypair ${INSTALLATION_DIR}/id.json --priority-fee 10000 mine --threads 4" >> mine\$i.sh
  echo "  echo "Mining \$i finished."" >> mine\$i.sh
  echo "done" >> mine\$i.sh
  chmod ug+x mine\$i.sh
  echo "sh mine\$i.sh >> miner.log 2>&1 & echo \\\$! >> miner.pid" >> master_miner.sh
EOF
chmod ug+x add_miner.sh

tee start_miner.sh > /dev/null <<EOF
  sh master_miner.sh
EOF
chmod ug+x start_miner.sh

tee stop_miner.sh > /dev/null <<EOF
  kill \$(cat miner.pid)
  rm miner.pid
EOF
chmod ug+x stop_miner.sh

tee list_addresses.sh > /dev/null <<EOF
  for key in id*.json; do
    echo "Address \$key: "
    solana address -k ${INSTALLATION_DIR}/\$key
  done
EOF
chmod ug+x list_addresses.sh

tee check_rewards.sh > /dev/null <<EOF
  for key in id*.json; do
    echo "Rewards \$key: "
    ore --keypair ${INSTALLATION_DIR}/\$key rewards
  done
EOF
chmod ug+x check_rewards.sh

sudo tee /etc/logrotate.d/ore > /dev/null <<EOF
  $INSTALLATION_DIR/miner.log {
    rotate 5
    hourly
    missingok
    notifempty
    copytruncate
    gzip
  }
EOF