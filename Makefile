.DEFAULT_GOAL:=help

init:  ## init servers env
	ansible-playbook -i hosts init_server.yml

prometheus: ## deploy prometheus and grafana
	ansible-playbook -i hosts deploy_prometheus.yml

jaeger: ## deploy jaeger server
	ansible-playbook -i hosts deploy_jaeger.yml

exporter: ## deploy muta monitor exporter
	server=`grep -A 1  "\[jaeger_server\]"  hosts | grep -v "\[jaeger_server\]"`; \
	ansible-playbook -i hosts deploy_exporter.yml  --extra-vars "jaeger_server=$$server" 

benchmark: ## run muta-chain benchmark
	ansible-playbook -i hosts deploy_benchmark.yml 

muta: ## deploy muta-chain  services
	ansible-playbook -i hosts deploy_muta.yml

start: ## start all muta-chain services as daemon
	@echo "[start]Starting all services"
	ansible-playbook -i hosts deploy_muta.yml --skip-tags build_config -t start

restart: ## restart all muta-chain services
	ansible-playbook -i hosts deploy_muta.yml --skip-tags build_config -t "stop,start"

stop: ## stop all muta-chain services
	@echo "[stop]Stop all services"
	ansible-playbook -i hosts deploy_muta.yml --skip-tags build_config -t stop

clear: ## delete all muta-chain data
	ansible-playbook -i hosts deploy_muta.yml --skip-tags build_config -t "stop,clear"

build: ## build muta-chain binary
	ansible-playbook -i hosts build_muta.yml 

ps: ## list muta-chain process
	ansible -i hosts muta_node -m shell -a "ps -ef | grep -E 'huobi-chain|muta-chain' | grep -v grep"

test: ## Test node availability
	ansible -i hosts allhost -m ping

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
