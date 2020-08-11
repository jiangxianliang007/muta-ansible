.DEFAULT_GOAL:=help
init_node := `grep -i init_chain_node hosts  |awk -F":" '{print $$2}'`
node_type := `grep -i node_type hosts |awk -F"[: ]+" '{print $$2}'`

init:  ## init all servers env
	ansible-playbook -i hosts init_server.yml --extra-vars "init_node=$(init_node)"

init_chain_node: ## init muta chain node servers env
	ansible-playbook -i hosts init_server.yml --skip-tags "init_build_node,init_localhost_node,init_benchmark_node" -t init_chain_node --extra-vars "init_node=$(init_node)"

init_benchmark_node: ## init benchmark server env
	ansible-playbook -i hosts init_server.yml -t init_benchmark_node

prometheus: ## deploy prometheus and grafana
	ansible-playbook -i hosts deploy_prometheus.yml

jaeger: ## deploy jaeger server
	ansible-playbook -i hosts deploy_jaeger.yml

exporter: ## deploy muta monitor exporter
	server=`grep -A 1  "\[jaeger_server\]" hosts | grep -v "\[jaeger_server\]"`; \
        loki_ip=`grep -A 1  "\[prometheus_server\]" hosts | grep -v "\[prometheus_server\]"`; \
	ansible-playbook -i hosts deploy_exporter.yml --extra-vars "jaeger_server=$$server" --extra-vars "loki_server=$$loki_ip" 

benchmark: ## run muta-chain benchmark
	ansible-playbook -i hosts deploy_benchmark.yml 

muta: ## deploy muta-chain services
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "logrotate,block_height" --extra-vars "node_type=muta_all_node"

consensus_node: ## deploy muta-chain consensus node services
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "init_rsync_node_config,logrotate,block_height" --extra-vars "node_type=muta_consensus_node"

rsync_node: ## deploy muta-chain rsync node services
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "build_config,delete_es_data,logrotate,block_height" --extra-vars "node_type=muta_rsync_node"

update: ## upgrade muta-Chain version
	make stop
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "build_config,delete_es_data,init_rsync_node_config" -t "upload_bin,start" --extra-vars "node_type=$(node_type)"

start: ## start all muta-chain services as daemon
	@echo "[start]Starting all services"
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "build_config,delete_es_data,init_rsync_node_config" -t start --extra-vars "node_type=$(node_type)"

restart: ## restart all muta-chain services
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "build_config,delete_es_data,init_rsync_node_config" -t "stop,start" --extra-vars "node_type=$(node_type)"

stop: ## stop all muta-chain services
	@echo "[stop]Stop all services"
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "build_config,delete_es_data,init_rsync_node_config" -t stop --extra-vars "node_type=$(node_type)"

clear: ## delete all muta-chain data
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "build_config,delete_es_data,init_rsync_node_config" -t "stop,clear" --extra-vars "node_type=$(node_type)"

logrotate: ## logrotate muta by daily
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "build_config,delete_es_data,init_rsync_node_config" -t logrotate --extra-vars "node_type=$(node_type)"

block: ## query current block heigth
	api_port=`grep -A1 "\[graphql\]" config/chainconfig.toml |tail -1 |awk -F "[=:\"]+" '{print $$4}'`; \
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "build_config,delete_es_data,init_rsync_node_config" -t block_height --extra-vars "api_port=$$api_port" --extra-vars "node_type=$(node_type)"

version: ## show chain version
	ansible-playbook -i hosts deploy_muta.yml --skip-tags "build_config,delete_es_data,init_rsync_node_config" -t show_version --extra-vars "node_type=$(node_type)"

log: ## get muta-chain node logs
	ansible-playbook -i hosts get_mutalogs.yml

build: ## build muta-chain binary
	ansible-playbook -i hosts build_muta.yml 

ps: ## list muta-chain process
	ansible -i hosts muta_all_node -m shell -a "ps -ef | grep -E 'huobi-chain|muta-chain' | grep -v grep"

restart_promtai: ## restart muta_promtail
	ansible -i hosts muta_all_node -m command -a "docker restart muta_promtail"

test: ## Test node availability
	ansible -i hosts allhost -m ping

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
