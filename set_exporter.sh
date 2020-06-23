#!/bin/bash 

muta_node_list=`sed -n '/^\[muta_node/,/^\[prometheus_server/p' hosts | grep -v "^\["`

node_exporters=
muta_exporters=
for i in ${muta_node_list};
  do
    echo $i
    node_exporter=\"${i}:9100\"
    muta_exporter=\"${i}:8000\"

    node_exporters=${node_exporters},${node_exporter}
    muta_exporters=${muta_exporters},${muta_exporter}
done

node_exporters=`echo ${node_exporters} | sed 's/^.//1'`
muta_exporters=`echo ${muta_exporters} | sed 's/^.//1'`

cp -rp ./roles/prometheus/templates/prometheus.yml.j2 ./roles/prometheus/templates/prometheus.yml_new.j2
sed -i "s/node_exporter_ip/${node_exporters}/g" ./roles/prometheus/templates/prometheus.yml_new.j2
sed -i "s/muta_exporter_ip/${muta_exporters}/g" ./roles/prometheus/templates/prometheus.yml_new.j2

