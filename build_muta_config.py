import copy
import json
import os
import subprocess
import toml
import sys
import yaml

with open("./roles/muta/vars/main.yaml") as f:
    data = yaml.load(f, Loader=yaml.FullLoader)
chain_type = data["chain_type"]

if chain_type == "muta":
    if not os.path.exists("./roles/muta/files/muta-keypair") or not os.path.exists("./roles/muta/files/muta-chain"):
        print ("muta-keypair or muta-chain is not found")
        sys.exit(0)
elif chain_type == "huobi":
    if not os.path.exists("./roles/muta/files/muta-keypair") or not os.path.exists("./roles/muta/files/huobi-chain"):
        print ("muta-keypair or huobi-chain is not found")
        sys.exit(0) 

os.chmod("./roles/muta/files/muta-keypair",755)

with open("./hosts") as f:
    lines = f.readlines()
    for num,value in enumerate(lines):
        if value.strip() == "[muta_consensus_node]":
            A_num = num + 1
        if value.strip() == "[prometheus_server]":
            B_num = num
    node_list = lines[A_num:B_num]
    node_list = [x.strip() for x in node_list if x.strip()!='']

muta_consensus_node = len(node_list)

def muta_config():
    global chain_type
    if chain_type == "muta":
        with open("./config/mutagenesis.toml") as f:
            config = toml.load(f)
    else:        
        with open("./config/huobigenesis.toml") as f:
            config = toml.load(f)

    r = subprocess.getoutput("./roles/muta/files/muta-keypair -n %d" % (muta_consensus_node))
    with open("./config/keypairs.json", "w") as f:
        f.write(r)
    keypairs = json.loads(r)
    
    assert "common_ref" in keypairs
    for e in keypairs["keypairs"]:
        assert "private_key" in e
        assert "public_key" in e
        assert "address" in e
        assert "bls_public_key" in e

    for i,v in enumerate(config["services"]):
         for k,v in v.items():
             if v == "metadata":
                  list_index = i
    
    payload = json.loads(config["services"][list_index]["payload"])
    payload["common_ref"] = keypairs["common_ref"]
    payload["verifier_list"] = []

    for i, e in enumerate(keypairs["keypairs"]):
       # if i >= (len(node_list) - config["muta"]["sync_node_number"]):
       #    break
        a = {
            "bls_pub_key":  e["bls_public_key"],
            "address": e["address"],
            "pub_key": e["public_key"],
            "propose_weight": 1,
            "vote_weight": 1,
        }
        payload["verifier_list"].append(a)

    config["services"][list_index]["payload"] = json.dumps(payload)

    with open("./roles/muta/templates/genesis.toml.j2", "w") as f:
        toml.dump(config, f)
    
    with open("./config/chainconfig.toml") as f:
        config = toml.load(f) 
    for i in range(len(node_list)):
        node_config = copy.deepcopy(config)
        keypair = keypairs["keypairs"][i]
        private_key = keypair["private_key"]
        node_config["privkey"] = private_key
        node_config["network"]["bootstraps"] = [{
            "peer_id": keypairs["keypairs"][0]["peer_id"],
            "address": node_list[0] + ":" + str(node_config["network"]["bootstraps"][0]["address"]).split(':')[1] ,
        }]

        private_address = keypair["address"]
        node_ip = node_list[i]
        if 'apm' in config.keys():
            node_config["apm"] = {}
            node_config["apm"]["service_name"] = chain_type + "-" + node_ip + "-" + private_address
            node_config["apm"]["tracing_address"] = config["apm"]["tracing_address"]
            node_config["apm"]["tracing_batch_size"] = config["apm"]["tracing_batch_size"]

        # if chain_type == "huobi":
            # node_config.pop("consensus")
        with open("./roles/muta/templates/config_%s.toml.j2" % (node_ip), "w") as f:
            toml.dump(node_config, f)

muta_config()
