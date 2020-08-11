# Muta 自动化运维工具

自动化部署：exporter、prometheus、grafana、elasticsearch、jaeger、muta、muta-benchmark、Loki

#### 安装 ansible , 增加进程并发数
```
apt update 
apt install -y ansible
sudo sed -i "s/#host_key_checking = False/host_key_checking = False/" /etc/ansible/ansible.cfg 
sudo sed -i "s/#forks          = 5/forks          = 21/" /etc/ansible/ansible.cfg 
```

#### 添加服务器列表

    在 hosts 文件中添加对应服务器IP

#### 获取 Muta binary

1、 可去下载已编译好的 muta-chain 和 muta-keypair 文件到 ./roles/muta/files/

2、 自行编译，初始化服务器后 执行 make build # 服务器需要在墙外 

#### 自定义参数
muta 创世快和节点参数修改 config/

各模块自定义参数修改文件 vim roles/?/vars/main.yaml 

注：如果修改 collector port , jaeger 和 exporter , vars/main.yaml 都需修改
#### 自定义初始化、部署节点类型（共识、同步）
hosts 中参数说明：

init_chain_node:  #当新增同步节点时可按需初始化 

node_type:  #选项 muta_consensus_node|muta_rsync_node|muta_all_node 按类型部署与升级

#### 部署命令
```
Usage:
  make 

Targets:
  init        init all servers env
  init_chain_node  init muta chain node servers env
  init_benchmark_node  init benchmark server env
  prometheus  deploy prometheus and grafana
  jaeger      deploy jaeger server
  exporter    deploy muta monitor exporter
  benchmark   run muta-chain benchmark
  muta        deploy muta-chain services
  consensus_node  deploy muta-chain consensus node services
  rsync_node  deploy muta-chain rsync node services
  update      upgrade muta-Chain version
  start       start all muta-chain services as daemon
  restart     restart all muta-chain services
  stop        stop all muta-chain services
  clear       delete all muta-chain data
  logrotate   logrotate muta by daily
  block       query current block heigth
  version     show chain version
  log         get muta-chain node logs
  build       build muta-chain binary
  ps          list muta-chain process
  restart_promtai  restart muta_promtail
  test        Test node availability
  help        Display this help
```

#### 访问监控：

prometheus:   prometheus_server:3000

jaeger:   jaeger_server:16686
