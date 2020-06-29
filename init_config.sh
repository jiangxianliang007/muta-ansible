#!/bin/bash 


COMMAND=$1
muta_node_list=`sed -n '/^\[muta_node/,/^\[prometheus_server/p' hosts | grep -v "^\["`
api_port=`cat config/config.toml | grep api_port |awk -F "[= ]+" '{print $2}'`


usage() {
    name=$(basename "$0")
    printf "[%-5s] %-18s  %-10s\n"   $name "set_exporter"             "- set exporter node ip"
    printf "[%-5s] %-10s  %-10s\n"   $name "set_benchmark_node"       "- set benchmark node ip"
    printf "[%-5s] %-18s  %-10s\n"   $name "help"                    "- Print usage info"
}

set_exporter() {

    node_exporters=
    muta_exporters=
    for i in ${muta_node_list};
      do
        node_exporter=\"${i}:9100\"
        muta_exporter=\"${i}:${api_port}\"

        node_exporters=${node_exporters},${node_exporter}
        muta_exporters=${muta_exporters},${muta_exporter}
    done

    node_exporters=`echo ${node_exporters} | sed 's/^.//1'`
    muta_exporters=`echo ${muta_exporters} | sed 's/^.//1'`

    cp -rp ./roles/prometheus/templates/prometheus.yml.j2 ./roles/prometheus/templates/prometheus.yml_new.j2
    sed -i "s/node_exporter_ip/${node_exporters}/g" ./roles/prometheus/templates/prometheus.yml_new.j2
    sed -i "s/muta_exporter_ip/${muta_exporters}/g" ./roles/prometheus/templates/prometheus.yml_new.j2
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

    *)
    echo  "Unknown  command ${COMMAND}"
    usage
    ;;

esac
