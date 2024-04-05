### Prerequisite :
#### Ensure 'git' already installed
    apt-get update -y && apt-get install git -y
### Steps
#### Clone this repository :
    git clone https://github.com/Zlkcyber/ore.git
#### run setup command : 
    cd ore && chmod ug+x *.sh && ./setup.sh
### Please do deposit to miner address before starting the miner
### You can get address list by running command :
    ./list_addresses.sh
#### follow the instruction and then run below command to start the node :
    ./start_miner.sh && tail -f miner.log
#### to stop miner, simply run :
    ./stop_miner.sh
#### to add miner, stop the miner first and then run :
    ./add_miner.sh