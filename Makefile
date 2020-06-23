# init servers env
init:
	ansible-playbook -i hosts init_server.yml

# deploy prometheus
prometheus:
	ansible-playbook -i hosts deploy_prometheus.yml

# deploy jaeger server
jaeger:
	ansible-playbook -i hosts deploy_jaeger.yml

# deploy muta exporter
exporter:
	server=`grep -A 1  "\[jaeger_server\]"  hosts | grep -v "\[jaeger_server\]"`; \
	ansible-playbook -i hosts deploy_exporter.yml  --extra-vars "jaeger_server=$$server" 

# run muta-chain benchmark
benchmark:
	ansible-playbook -i hosts deploy_benchmark.yml 

# deploy muta-chain  services
muta:
	ansible-playbook -i hosts deploy_muta.yml

# start all muta-chain services as daemon
start:
	@echo "[start]Starting all services"
	ansible-playbook -i hosts deploy_muta.yml --skip-tags build_config -t start

# restart all muta-chain services
restart:
	ansible-playbook -i hosts deploy_muta.yml --skip-tags build_config -t "stop,start"

# stop all muta-chain services
stop:
	@echo "[stop]Stop all services"
	ansible-playbook -i hosts deploy_muta.yml --skip-tags build_config -t stop

# delete all muta-chain data
clear:
	ansible-playbook -i hosts deploy_muta.yml --skip-tags build_config -t "stop,clear"

# list muta-chain process
ps:
	ansible -i hosts muta_node -m shell -a "ps -ef | grep muta-chain | grep -v grep"

# Test node availability
test:
	ansible -i hosts allhost -m ping
