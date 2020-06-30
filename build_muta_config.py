import copy
import json
import os
import subprocess
import toml
import sys

if not os.path.exists("./roles/muta/files/muta-keypair") or not os.path.exists("./roles/muta/files/muta-chain"):
    print ("muta-keypair or muta-chain is not found")
    sys.exit(0)

with open("./hosts") as f:
    lines = f.readlines()
    for num,value in enumerate(lines):
        if value.strip() == "[muta_node]":
            A_num = num + 1
        if value.strip() == "[prometheus_server]":
            B_num = num
    node_list = lines[A_num:B_num]
    node_list = [x.strip() for x in node_list if x.strip()!='']

muta_node = len(node_list)

def muta_config():
    with open("./config/genesis.toml") as f:
        config = toml.load(f)
    aid = config["asset"]["id"]
    name = config["asset"]["name"]
    symbol = config["asset"]["symbol"]
    supply = config["asset"]["supply"]
    issuer = config["asset"]["issuer"]

    chain_id = config["metadata"]["chain_id"]
    timeout_gap = config["metadata"]["timeout_gap"]
    cycles_limit = config["metadata"]["cycles_limit"]
    cycles_price = config["metadata"]["cycles_price"]
    interval = config["metadata"]["interval"]
    propose_ratio = config["metadata"]["propose_ratio"]
    prevote_ratio = config["metadata"]["prevote_ratio"]
    precommit_ratio = config["metadata"]["precommit_ratio"]
    brake_ratio = config["metadata"]["brake_ratio"]
    tx_num_limit = config["metadata"]["tx_num_limit"]
    max_tx_size = config["metadata"]["max_tx_size"]

    r = subprocess.getoutput("./roles/muta/files/muta-keypair -n %d" % (muta_node) )
    with open("./config/keypairs.json", "w") as f:
        f.write(r)
    keypairs = json.loads(r)

    assert "common_ref" in keypairs
    for e in keypairs["keypairs"]:
        assert "private_key" in e
        assert "public_key" in e
        assert "address" in e
        assert "bls_public_key" in e

    genesis = toml.load(config["muta"]["genesis_template"])
    assert genesis["services"][0]["name"] == "asset"
    assetpayload = json.loads(genesis["services"][0]["payload"])
    assetpayload["id"] = aid
    assetpayload["name"] = name
    assetpayload["symbol"] = symbol
    assetpayload["supply"] = supply
    assetpayload["issuer"] = issuer
     
    assert genesis["services"][1]["name"] == "metadata"
    payload = json.loads(genesis["services"][1]["payload"])
    payload["common_ref"] = keypairs["common_ref"]
    payload["chain_id"] = chain_id
    payload["timeout_gap"] = timeout_gap
    payload["cycles_limit"] = cycles_limit
    payload["cycles_price"] = cycles_price
    payload["interval"] = interval
    payload["verifier_list"] = []
    payload["propose_ratio"] = propose_ratio
    payload["prevote_ratio"] = prevote_ratio
    payload["precommit_ratio"] = precommit_ratio
    payload["brake_ratio"] = brake_ratio
    payload["tx_num_limit"] = tx_num_limit
    payload["max_tx_size"] = max_tx_size

    for i, e in enumerate(keypairs["keypairs"]):
        if i >= (len(node_list) - config["muta"]["sync_node_number"]):
            break
        a = {
            "bls_pub_key":  e["bls_public_key"],
            "address": e["address"],
            "propose_weight": 1,
            "vote_weight": 1,
        }
        payload["verifier_list"].append(a)
    genesis["services"][0]["payload"] = json.dumps(assetpayload)
    genesis["services"][1]["payload"] = json.dumps(payload)
    with open("./roles/muta/templates/genesis.toml.j2", "w") as f:
        toml.dump(genesis, f)
    
    with open("./config/config.toml") as f:
        config = toml.load(f) 
    node_config_raw = toml.load(config["muta"]["config_template"])
    for i in range(len(node_list)):
        node_config = copy.deepcopy(node_config_raw)
        keypair = keypairs["keypairs"][i]
        private_key = keypair["private_key"]
        node_config["privkey"] = private_key

        node_config["data_path"] = config["muta"]["data_path"]

        node_config["graphql"]["listening_address"] = "0.0.0.0:" + str(config["graphql"]["api_port"])
        node_config["graphql"]["workers"] = config["graphql"]["workers"]
        node_config["graphql"]["maxconn"] = config["graphql"]["maxconn"]
        node_config["graphql"]["max_payload_size"] = config["graphql"]["max_payload_size"]

        node_config["network"]["listening_address"] = "0.0.0.0:" + str(config["network"]["p2p_port"])
        node_config["network"]["rpc_timeout"] =  config["network"]["rpc_timeout"]

        node_config["network"]["bootstraps"] = [{
            "pubkey": keypairs["keypairs"][0]["public_key"],
            "address": node_list[0] + ":" + str(config["network"]["p2p_port"]),
        }]

        node_config["mempool"]["pool_size"] = config["mempool"]["pool_size"]
        node_config["mempool"]["broadcast_txs_size"] = config["mempool"]["broadcast_txs_size"]
        node_config["mempool"]["broadcast_txs_interval"] = config["mempool"]["broadcast_txs_interval"]

        node_config["executor"]["light"] = config["executor"]["light"]

        node_config["logger"]["filter"] = config["logger"]["filter"]
        node_config["logger"]["log_to_console"] = config["logger"]["log_to_console"]
        node_config["logger"]["console_show_file_and_line"] = config["logger"]["console_show_file_and_line"]
        node_config["logger"]["log_path"] = os.path.join(config["muta"]["data_path"], "logs")
        node_config["logger"]["log_to_file"] = config["logger"]["log_to_file"]
        node_config["logger"]["metrics"] = config["logger"]["metrics"]
        
        private_address = keypair["address"]
        node_ip = node_list[i]
        node_config["apm"] = {}
        node_config["apm"]["service_name"] = config["apm"]["service_name"] + "-" + node_ip + "-" + private_address
        node_config["apm"]["tracing_address"] = config["apm"]["tracing_address"]
        node_config["apm"]["tracing_batch_size"] = config["apm"]["tracing_batch_size"]

        with open("./roles/muta/templates/config_%s.toml.j2" % (node_ip), "w") as f:
            toml.dump(node_config, f)

muta_config()
