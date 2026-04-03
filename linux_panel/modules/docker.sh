#!/bin/bash

# 安装Docker
install_docker() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          安装 Docker${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查是否已安装
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker 已安装${NC}"
        echo -e "Docker 版本: $(docker --version)"
        echo ""
        docker_menu
        return
    fi
    
    echo -e "${CYAN}开始安装 Docker...${NC}"
    echo ""
    
    # 根据系统选择安装方法
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            echo -e "${CYAN}检测到 CentOS/RHEL/Fedora 系统${NC}"
            
            # 卸载旧版本
            yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
            
            # 安装依赖
            yum install -y yum-utils device-mapper-persistent-data lvm2
            
            # 添加Docker仓库
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            # 安装Docker
            yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # 启动Docker
            systemctl start docker
            systemctl enable docker
            ;;
            
        "ubuntu"|"debian")
            echo -e "${CYAN}检测到 Ubuntu/Debian 系统${NC}"
            
            # 卸载旧版本
            apt remove -y docker docker-engine docker.io containerd runc
            
            # 更新apt包索引
            apt update
            
            # 安装依赖
            apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
            
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 设置稳定版仓库
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装Docker
            apt update
            apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
            
        *)
            echo -e "${RED}不支持的系统: $DISTRO${NC}"
            echo -e "${YELLOW}请参考 Docker 官方文档进行安装${NC}"
            read -p "按回车键返回主菜单..."
            return
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker 安装完成！${NC}"
        echo -e "Docker 版本: $(docker --version)"
        echo ""
        
        # 测试Docker安装
        echo -e "${CYAN}测试 Docker 安装...${NC}"
        docker run hello-world
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker 测试成功！${NC}"
        else
            echo -e "${YELLOW}Docker 测试失败，但Docker已安装${NC}"
            
            # 如果测试失败，建议进行DNS检测与修复
            echo ""
            echo -e "${CYAN}Docker测试失败，可能是DNS污染问题${NC}"
            echo -e "${YELLOW}建议进行Docker镜像源DNS检测与修复${NC}"
            echo ""
            
            read -p "是否立即进行DNS检测与修复？(y/n, 默认y): " fix_dns
            fix_dns=${fix_dns:-y}
            
            if [[ $fix_dns =~ ^[Yy]$ ]]; then
                echo ""
                fix_docker_dns_integrated
            fi
        fi
        
        # 安装完成后，询问是否进行DNS检测与修复
        echo ""
        echo -e "${CYAN}Docker安装完成，现在可以进行DNS检测与修复${NC}"
        echo -e "${YELLOW}这可以解决DNS污染导致的镜像拉取问题${NC}"
        echo ""
        
        read -p "是否进行Docker镜像源DNS检测与修复？(y/n, 默认y): " do_dns_fix
        do_dns_fix=${do_dns_fix:-y}
        
        if [[ $do_dns_fix =~ ^[Yy]$ ]]; then
            echo ""
            fix_docker_dns_integrated
        fi
        
        # 进入Docker菜单
        docker_menu
    else
        echo -e "${RED}Docker 安装失败${NC}"
        read -p "按回车键返回主菜单..."
    fi
}

# Docker功能菜单
docker_menu() {
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}          Docker 功能菜单${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo ""
        echo -e "${CYAN}当前Docker状态:${NC}"
        docker --version
        echo -e "容器数量: $(docker ps -q | wc -l)"
        echo -e "镜像数量: $(docker images -q | wc -l)"
        echo ""
        echo -e "${GREEN}1.${NC} 一键安装 ELK (Elasticsearch + Logstash + Kibana)"
        echo -e "${GREEN}2.${NC} 一键安装 MySQL"
        echo -e "${GREEN}3.${NC} 一键安装 Nginx"
        echo -e "${GREEN}4.${NC} 一键安装 Redis"
        echo -e "${GREEN}5.${NC} 一键安装 WordPress"
        echo -e "${GREEN}6.${NC} 查看Docker状态"
        echo -e "${GREEN}7.${NC} 管理Docker容器"
        echo -e "${GREEN}8.${NC} 返回主菜单"
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo ""
        
        read -p "请选择功能 (1-8): " docker_choice
        
        case $docker_choice in
            1)
                install_elk
                ;;
            2)
                install_mysql
                ;;
            3)
                install_nginx
                ;;
            4)
                install_redis
                ;;
            5)
                install_wordpress
                ;;
            6)
                docker_status
                ;;
            7)
                docker_management
                ;;
            8)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 安装ELK
install_elk() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          安装 ELK 套件${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: ELK 套件需要较多的系统资源${NC}"
    echo -e "建议至少: 4GB RAM, 2CPU核心"
    echo ""
    
    read -p "是否继续安装 ELK？(y/n): " choice
    if [[ $choice != "y" && $choice != "Y" ]]; then
        return
    fi
    
    echo -e "${CYAN}创建 docker-compose.yml 文件...${NC}"
    
    cat > docker-compose-elk.yml << 'EOF'
version: '3.7'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms1g -Xmx1g
    volumes:
      - es_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
      - "9300:9300"
    networks:
      - elk

  logstash:
    image: docker.elastic.co/logstash/logstash:7.17.0
    container_name: logstash
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5000:5000"
    environment:
      LS_JAVA_OPTS: "-Xmx256m -Xms256m"
    networks:
      - elk
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:7.17.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    networks:
      - elk
    depends_on:
      - elasticsearch

networks:
  elk:
    driver: bridge

volumes:
  es_data:
    driver: local
EOF
    
    # 创建 Logstash 配置文件
    cat > logstash.conf << 'EOF'
input {
  tcp {
    port => 5000
    codec => json
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "logstash-%{+YYYY.MM.dd}"
  }
}
EOF
    
    echo -e "${CYAN}启动 ELK 服务...${NC}"
    docker_compose -f docker-compose-elk.yml up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}ELK 安装完成！${NC}"
        echo ""
        echo -e "${CYAN}访问地址:${NC}"
        echo -e "Kibana: http://$(get_primary_ip):5601"
        echo -e "Elasticsearch: http://$(get_primary_ip):9200"
        echo -e "Logstash: TCP端口 5000"
        echo ""
        echo -e "${YELLOW}管理命令:${NC}"
        local compose_cmd
        compose_cmd=$(get_docker_compose_cmd)
        echo -e "停止服务: ${compose_cmd} -f docker-compose-elk.yml stop"
        echo -e "启动服务: ${compose_cmd} -f docker-compose-elk.yml start"
        echo -e "查看日志: ${compose_cmd} -f docker-compose-elk.yml logs -f"
    else
        echo -e "${RED}ELK 安装失败${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 安装MySQL
install_mysql() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          安装 MySQL${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    read -p "请输入MySQL root密码 (默认: 123456): " mysql_pass
    mysql_pass=${mysql_pass:-123456}
    
    read -p "请输入MySQL数据目录 (默认: /opt/mysql_data): " mysql_data
    mysql_data=${mysql_data:-/opt/mysql_data}
    
    # 创建数据目录
    mkdir -p $mysql_data
    
    echo -e "${CYAN}拉取 MySQL 8.0 镜像...${NC}"
    docker pull mysql:8.0
    
    echo -e "${CYAN}启动 MySQL 容器...${NC}"
    docker run -d \
        --name mysql-server \
        -e MYSQL_ROOT_PASSWORD=$mysql_pass \
        -p 3306:3306 \
        -v $mysql_data:/var/lib/mysql \
        --restart unless-stopped \
        mysql:8.0
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}MySQL 安装完成！${NC}"
        echo ""
        echo -e "${CYAN}连接信息:${NC}"
        echo -e "主机: $(get_primary_ip)"
        echo -e "端口: 3306"
        echo -e "用户名: root"
        echo -e "密码: $mysql_pass"
        echo ""
        echo -e "${YELLOW}管理命令:${NC}"
        echo -e "进入容器: docker exec -it mysql-server mysql -uroot -p"
        echo -e "查看日志: docker logs mysql-server"
        echo -e "停止容器: docker stop mysql-server"
        echo -e "启动容器: docker start mysql-server"
    else
        echo -e "${RED}MySQL 安装失败${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 安装Nginx
install_nginx() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          安装 Nginx${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    read -p "请输入Nginx配置目录 (默认: /opt/nginx_conf): " nginx_conf
    nginx_conf=${nginx_conf:-/opt/nginx_conf}
    
    read -p "请输入Nginx日志目录 (默认: /opt/nginx_logs): " nginx_logs
    nginx_logs=${nginx_logs:-/opt/nginx_logs}
    
    read -p "请输入网站目录 (默认: /opt/nginx_html): " nginx_html
    nginx_html=${nginx_html:-/opt/nginx_html}
    
    # 创建目录
    mkdir -p $nginx_conf $nginx_logs $nginx_html
    
    # 创建默认配置文件
    cat > $nginx_conf/default.conf << 'EOF'
server {
    listen       80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
    
    # 创建测试页面
    cat > $nginx_html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Nginx!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
</head>
<body>
    <h1>Welcome to Nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and working.</p>
    <p>This page is served from Docker container.</p>
    
    <h2>Server Information</h2>
    <p>Hostname: <strong>SERVER_HOSTNAME</strong></p>
    <p>IP Address: <strong>SERVER_IP</strong></p>
    <p>Date: <strong>SERVER_DATE</strong></p>
    
    <hr>
    <p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOF
    
    # 替换占位符
    sed -i "s/SERVER_HOSTNAME/$(hostname)/g" $nginx_html/index.html
    sed -i "s/SERVER_IP/$(get_primary_ip)/g" $nginx_html/index.html
    sed -i "s/SERVER_DATE/$(date)/g" $nginx_html/index.html
    
    echo -e "${CYAN}拉取 Nginx 镜像...${NC}"
    docker pull nginx:alpine
    
    echo -e "${CYAN}启动 Nginx 容器...${NC}"
    docker run -d \
        --name nginx-server \
        -p 80:80 \
        -p 443:443 \
        -v $nginx_conf:/etc/nginx/conf.d \
        -v $nginx_html:/usr/share/nginx/html \
        -v $nginx_logs:/var/log/nginx \
        --restart unless-stopped \
        nginx:alpine
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Nginx 安装完成！${NC}"
        echo ""
        echo -e "${CYAN}访问地址:${NC}"
        echo -e "HTTP: http://$(get_primary_ip)"
        echo -e "HTTPS: https://$(get_primary_ip) (需要配置证书)"
        echo ""
        echo -e "${CYAN}目录结构:${NC}"
        echo -e "配置文件: $nginx_conf"
        echo -e "网站文件: $nginx_html"
        echo -e "日志文件: $nginx_logs"
        echo ""
        echo -e "${YELLOW}管理命令:${NC}"
        echo -e "重载配置: docker exec nginx-server nginx -s reload"
        echo -e "查看日志: docker logs nginx-server"
    else
        echo -e "${RED}Nginx 安装失败${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 安装Redis
install_redis() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          安装 Redis${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    read -p "请输入Redis密码 (留空表示无密码): " redis_pass
    read -p "请输入Redis数据目录 (默认: /opt/redis_data): " redis_data
    redis_data=${redis_data:-/opt/redis_data}
    
    # 创建数据目录
    mkdir -p $redis_data
    
    echo -e "${CYAN}拉取 Redis 镜像...${NC}"
    docker pull redis:alpine
    
    # 构建启动命令
    if [ -z "$redis_pass" ]; then
        redis_cmd="docker run -d \
            --name redis-server \
            -p 6379:6379 \
            -v $redis_data:/data \
            --restart unless-stopped \
            redis:alpine \
            redis-server --appendonly yes"
    else
        redis_cmd="docker run -d \
            --name redis-server \
            -p 6379:6379 \
            -v $redis_data:/data \
            --restart unless-stopped \
            redis:alpine \
            redis-server --requirepass $redis_pass --appendonly yes"
    fi
    
    echo -e "${CYAN}启动 Redis 容器...${NC}"
    eval $redis_cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Redis 安装完成！${NC}"
        echo ""
        echo -e "${CYAN}连接信息:${NC}"
        echo -e "主机: $(get_primary_ip)"
        echo -e "端口: 6379"
        if [ -n "$redis_pass" ]; then
            echo -e "密码: $redis_pass"
        else
            echo -e "密码: 无"
        fi
        echo ""
        echo -e "${YELLOW}管理命令:${NC}"
        echo -e "连接Redis: docker exec -it redis-server redis-cli"
        if [ -n "$redis_pass" ]; then
            echo -e "带密码连接: docker exec -it redis-server redis-cli -a $redis_pass"
        fi
    else
        echo -e "${RED}Redis 安装失败${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 安装WordPress
install_wordpress() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          安装 WordPress${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    read -p "请输入WordPress端口 (默认: 8080): " wp_port
    wp_port=${wp_port:-8080}
    
    read -p "请输入MySQL root密码 (默认: wordpress123): " mysql_pass
    mysql_pass=${mysql_pass:-wordpress123}
    
    read -p "请输入WordPress数据库密码 (默认: wordpress123): " wp_db_pass
    wp_db_pass=${wp_db_pass:-wordpress123}
    
    echo -e "${CYAN}创建 docker-compose.yml 文件...${NC}"
    
    cat > docker-compose-wordpress.yml << EOF
version: '3.7'

services:
  db:
    image: mysql:8.0
    container_name: wp_db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: $mysql_pass
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: $wp_db_pass
    volumes:
      - wp_db_data:/var/lib/mysql
    networks:
      - wp_network

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    container_name: wp_app
    restart: unless-stopped
    ports:
      - "$wp_port:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: $wp_db_pass
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_app_data:/var/www/html
    networks:
      - wp_network

volumes:
  wp_db_data:
  wp_app_data:

networks:
  wp_network:
    driver: bridge
EOF
    
    echo -e "${CYAN}启动 WordPress 服务...${NC}"
    docker_compose -f docker-compose-wordpress.yml up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}WordPress 安装完成！${NC}"
        echo ""
        echo -e "${CYAN}访问地址:${NC}"
        echo -e "WordPress: http://$(get_primary_ip):$wp_port"
        echo ""
        echo -e "${CYAN}数据库信息:${NC}"
        echo -e "主机: db (容器内)"
        echo -e "端口: 3306"
        echo -e "数据库名: wordpress"
        echo -e "用户名: wordpress"
        echo -e "密码: $wp_db_pass"
        echo ""
        echo -e "${YELLOW}管理命令:${NC}"
        local compose_cmd
        compose_cmd=$(get_docker_compose_cmd)
        echo -e "停止服务: ${compose_cmd} -f docker-compose-wordpress.yml stop"
        echo -e "启动服务: ${compose_cmd} -f docker-compose-wordpress.yml start"
        echo -e "查看日志: ${compose_cmd} -f docker-compose-wordpress.yml logs -f"
    else
        echo -e "${RED}WordPress 安装失败${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 查看Docker状态
docker_status() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          Docker 状态${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}=== Docker 版本 ===${NC}"
    docker --version
    if command_exists docker-compose; then
        docker-compose --version
    elif command_exists docker && docker compose version >/dev/null 2>&1; then
        docker compose version
    else
        echo -e "${YELLOW}Docker Compose 未安装${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}=== Docker 系统信息 ===${NC}"
    docker info --format '{{json .}}' | python3 -m json.tool 2>/dev/null || docker info
    echo ""
    
    echo -e "${CYAN}=== 运行中的容器 ===${NC}"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo -e "${CYAN}=== 所有容器 ===${NC}"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo -e "${CYAN}=== 镜像列表 ===${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
    echo ""
    
    echo -e "${CYAN}=== 卷列表 ===${NC}"
    docker volume ls
    echo ""
    
    echo -e "${CYAN}=== 网络列表 ===${NC}"
    docker network ls
    echo ""
    
    echo -e "${CYAN}=== 资源使用情况 ===${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo ""
    
    read -p "按回车键继续..."
}

# Docker容器管理
docker_management() {
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}          Docker 容器管理${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo ""
        
        echo -e "${CYAN}当前运行中的容器:${NC}"
        echo -e "${YELLOW}ID\t名称\t状态\t端口${NC}"
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | tail -n +2
        
        echo ""
        echo -e "${GREEN}1.${NC} 启动容器"
        echo -e "${GREEN}2.${NC} 停止容器"
        echo -e "${GREEN}3.${NC} 重启容器"
        echo -e "${GREEN}4.${NC} 删除容器"
        echo -e "${GREEN}5.${NC} 查看容器日志"
        echo -e "${GREEN}6.${NC} 进入容器终端"
        echo -e "${GREEN}7.${NC} 返回上一级"
        echo ""
        
        read -p "请选择操作 (1-7): " mgmt_choice
        
        case $mgmt_choice in
            1)
                read -p "请输入容器名称或ID: " container_name
                if [ -n "$container_name" ]; then
                    docker start $container_name
                    echo -e "${GREEN}已启动容器: $container_name${NC}"
                    sleep 2
                fi
                ;;
            2)
                read -p "请输入容器名称或ID: " container_name
                if [ -n "$container_name" ]; then
                    docker stop $container_name
                    echo -e "${GREEN}已停止容器: $container_name${NC}"
                    sleep 2
                fi
                ;;
            3)
                read -p "请输入容器名称或ID: " container_name
                if [ -n "$container_name" ]; then
                    docker restart $container_name
                    echo -e "${GREEN}已重启容器: $container_name${NC}"
                    sleep 2
                fi
                ;;
            4)
                read -p "请输入容器名称或ID: " container_name
                if [ -n "$container_name" ]; then
                    docker rm -f $container_name
                    echo -e "${GREEN}已删除容器: $container_name${NC}"
                    sleep 2
                fi
                ;;
            5)
                read -p "请输入容器名称或ID: " container_name
                if [ -n "$container_name" ]; then
                    clear
                    echo -e "${CYAN}容器 $container_name 的日志:${NC}"
                    echo -e "${YELLOW}按 Ctrl+C 退出日志查看${NC}"
                    echo ""
                    docker logs -f $container_name
                fi
                ;;
            6)
                read -p "请输入容器名称或ID: " container_name
                if [ -n "$container_name" ]; then
                    clear
                    echo -e "${CYAN}进入容器 $container_name 的终端${NC}"
                    echo -e "${YELLOW}按 Ctrl+D 退出容器终端${NC}"
                    echo ""
                    docker exec -it $container_name bash || docker exec -it $container_name sh
                fi
                ;;
            7)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}
