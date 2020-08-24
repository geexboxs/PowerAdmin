# 映射MobyLinux目录
docker container run --name host -v /:/host alpine
# 增加max_map_count配置以安装es7
docker exec host bash -c "chroot /host;sysctl -w vm.max_map_count=262144;"
# 兼容wsl docker版本
wsl sysctl -w vm.max_map_count=262144
"version: `"2`"
networks:
  elastic:
    driver: bridge
volumes:
  elastic-data:
    driver: local
services:
  elasticsearch:
    container_name: elasticsearch
    environment:
      - node.name=elasticsearch
      - cluster.name=elasticsearch
      - bootstrap.memory_lock=true
      - cluster.initial_master_nodes=elasticsearch
      - `"ES_JAVA_OPTS=-Xms512m -Xmx512m`"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    image: docker.elastic.co/elasticsearch/elasticsearch:7.9.0
    volumes:
      - elastic-data:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - elastic
  kibana:
    container_name: kibana
    image: docker.elastic.co/kibana/kibana:7.9.0
    ports:
      - 5601:5601
    environment:
      SERVER_NAME: ims-kibana
    networks:
      - elastic
">docker-compse.yml
docker-compse up
rm .\docker-compse.yml
