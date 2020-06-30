# muta 自动化运维工具

#### 安装 ansible , 增加进程并发数
```
apt update 
apt install -y ansible
sudo sed -i "s/#host_key_checking = False/host_key_checking = False/" /etc/ansible/ansible.cfg 
sudo sed -i "s/#forks          = 5/forks          = 21/" /etc/ansible/ansible.cfg 
```

#### 下载 muta 二进制文件
```
cd muta-ansible
download  muta-chain  and  muta-keypair to ./roles/muta/files/ 
```
#### 添加服务器列表

    在 hosts 文件中添加对应服务器IP

#### 自定义参数
muta 创世快和节点参数修改 config/

各模块自定义参数修改文件 vim roles/?/vars/main.yaml 

注：如果修改 collector port , jaeger 和 exporter , vars/main.yaml 都需修改
#### 部署命令
```
make init # 初始化环境
make prometheus
make jaeger
make exporter
make muta  # 部署muta-chain   
make benchmark
make start
make stop 
make clear 
```

#### 访问监控：

prometheus:   prometheus_server:3000

jaeger:   jaeger_server:16686