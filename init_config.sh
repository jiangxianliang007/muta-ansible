#!/bin/bash 


COMMAND=$1
muta_node_list=`sed -n '/^\[muta_rsync_node/,/^\[prometheus_server/p' hosts | grep -v "^\["`
api_port=`cat config/chainconfig.toml | grep listening_address |head -1 |awk -F"[:\"]+" '{print $3}'`
j=1
config_dir="roles/muta/templates"

usage() {
    name=$(basename "$0")
    printf "[%-5s] %-18s  %-10s\n"   $name "set_exporter"             "- set exporter node ip"
    printf "[%-5s] %-10s  %-10s\n"   $name "set_benchmark_node"       "- set benchmark node ip"
    printf "[%-5s] %-10s  %-10s\n"   $name "init_muta_rsync_node_config"       "- create rsync node config"
    printf "[%-5s] %-18s  %-10s\n"   $name "help"                    "- Print usage info"
}

set_exporter() {
    jaeger_agents=
    node_exporters=
    muta_exporters=
    promtail_agents=
    for i in ${muta_node_list};
      do
        node_exporter=\"${i}:9100\"
        muta_exporter=\"${i}:${api_port}\"
        jaeger_agent=\"${i}:14271\"
        promtail_agent=\"${i}:9080\"

        jaeger_agents=${jaeger_agents},${jaeger_agent}
        node_exporters=${node_exporters},${node_exporter}
        muta_exporters=${muta_exporters},${muta_exporter}
        promtail_agents=${promtail_agents},${promtail_agent}
    done

    jaeger_agents=`echo ${jaeger_agents} | sed 's/^.//1'`
    node_exporters=`echo ${node_exporters} | sed 's/^.//1'`
    muta_exporters=`echo ${muta_exporters} | sed 's/^.//1'`
    promtail_agents=`echo ${promtail_agents} | sed 's/^.//1'`

    cp -rp ./roles/prometheus/templates/prometheus.yml.j2 ./roles/prometheus/templates/prometheus.yml_new.j2
    sed -i "s/jaeger_agent_ip/${jaeger_agents}/g" ./roles/prometheus/templates/prometheus.yml_new.j2
    sed -i "s/node_exporter_ip/${node_exporters}/g" ./roles/prometheus/templates/prometheus.yml_new.j2
    sed -i "s/muta_exporter_ip/${muta_exporters}/g" ./roles/prometheus/templates/prometheus.yml_new.j2
    sed -i "s/promtail_agent_ip/${promtail_agents}/g" ./roles/prometheus/templates/prometheus.yml_new.j2
}


set_benchmark_node() {
    benchmarknodes=
    for i in ${muta_node_list};
      do
        benchmarknode="http:\/\/${i}:${api_port}\/graphql"
        benchmarknodes="${benchmarknodes} ${benchmarknode}"
    done


    cp -rp ./roles/benchmark/templates/benchmark.conf.j2 ./roles/benchmark/templates/benchmark.conf_new.j2
    sed -i "s/benchmark_nodes/${benchmarknodes}/g" ./roles/benchmark/templates/benchmark.conf_new.j2
}

init_muta_rsync_node_config() {
    rsync_nodeip=`awk '/\[muta_rsync_node/,/\[muta_consensus_node/' hosts | grep -Ev "^$|^\["`
    rsync_nodes=`awk '/\[muta_rsync_node/,/\[muta_consensus_node/' hosts | grep -Ev "^$|^\[" |wc -l`
    consensus_node=`awk '/\[muta_consensus_node/,/\[prometheus_server/' hosts | grep -Ev "^$|^\[" |tail -1`
    roles/muta/files/muta-keypair -n ${rsync_nodes} > config/rsyncnode_keypairs.json
    privkey=`cat ${config_dir}/config_${consensus_node}.toml.j2 | grep privkey |awk -F "=" '{print $2}'`
    apm=`cat ${config_dir}/config_${consensus_node}.toml.j2 | grep apm |wc -l`
    for i in ${rsync_nodeip}; do
        cp -rp ${config_dir}/config_${consensus_node}.toml.j2 ${config_dir}/config_${i}.toml.j2
	newprivkey=`cat config/rsyncnode_keypairs.json | grep private_key|awk -F"[:,]+" '{print $2}' | eval sed -n ${j}p`
	sed -i "s/${privkey}/${newprivkey}/" ${config_dir}/config_${i}.toml.j2
	if [ $apm -eq 1 ]; then
            service_name=`cat ${config_dir}/config_${consensus_node}.toml.j2 | grep service_name |awk -F"[=-]+" '{print $3"-"$4}'`
	    newservice_name=`cat config/rsyncnode_keypairs.json | grep address | awk -F"[:,]+" '{print $2}' | eval sed -n ${j}p |sed 's/\"//'|sed 's/ //g'`
            sed -i "s/${service_name}/${i}-${newservice_name}/" ${config_dir}/config_${i}.toml.j2
        fi
	j=$(($j+1))
    done
}
case "$COMMAND" in
    -h | help | -help | --help)
        usage
        ;;

    set_exporter)
        set_exporter
	;;
      
    set_benchmark_node)
        set_benchmark_node
	;;

    init_muta_rsync_node_config)
        init_muta_rsync_node_config
        ;;

    *)
    echo  "Unknown  command ${COMMAND}"
    usage
    ;;

esac
