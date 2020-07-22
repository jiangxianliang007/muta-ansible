# Muta 自动化运维工具

自动化部署：exporter、prometheus、grafana、elasticsearch、jaeger、muta、muta-benchmark 

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

2、 自行编译，初始化服务器后 执行 make build # 建议服务器在墙外 

#### 自定义参数
muta 创世快和节点参数修改 config/

各模块自定义参数修改文件 vim roles/?/vars/main.yaml 

注：如果修改 collector port , jaeger 和 exporter , vars/main.yaml 都需修改
#### 部署命令
```
Usage:
  make 

Targets:
  init        init servers env
  prometheus  deploy prometheus and grafana
  jaeger      deploy jaeger server
  exporter    deploy muta monitor exporter
  benchmark   run muta-chain benchmark
  muta        deploy muta-chain  services
  start       start all muta-chain services as daemon
  restart     restart all muta-chain services
  stop        stop all muta-chain services
  clear       delete all muta-chain data
  logrotate   logrotate muta by daily
  block       query current block heigth
  log         get muta-chain node logs
  build       build muta-chain binary
  ps          list muta-chain process
  test        Test node availability
  help        Display this help
```

#### 访问监控：

prometheus:   prometheus_server:3000

jaeger:   jaeger_server:16686
