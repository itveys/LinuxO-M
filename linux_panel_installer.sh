#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 系统信息
OS_INFO=""
ARCH=""
DISTRO=""

# DNS检测相关
GITHUB_DOMAINS="github.com raw.githubusercontent.com github.github.io api.github.com"
DNS_TEST_URL="https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/oh-my-zsh.sh"

# 检查是否以root用户运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 此脚本必须以root权限运行${NC}"
        echo -e "请使用: ${YELLOW}sudo bash $0${NC}"
        exit 1
    fi
}

# 获取系统信息
get_system_info() {
    echo -e "${CYAN}正在获取系统信息...${NC}"
    
    # 获取系统架构
    ARCH=$(uname -m)
    
    # 获取发行版信息
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        OS_INFO="$PRETTY_NAME"
    elif [ -f /etc/centos-release ]; then
        DISTRO="centos"
        OS_INFO=$(cat /etc/centos-release)
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
        OS_INFO=$(cat /etc/redhat-release)
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        OS_INFO="Debian $(cat /etc/debian_version)"
    else
        DISTRO="unknown"
        OS_INFO="Unknown Linux Distribution"
    fi
    
    echo -e "${GREEN}系统信息:${NC} $OS_INFO"
    echo -e "${GREEN}系统架构:${NC} $ARCH"
    echo -e "${GREEN}发行版:${NC} $DISTRO"
    echo ""
}

# 显示系统信息
show_system_info() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          服务器信息${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 基本系统信息
    echo -e "${CYAN}=== 基本系统信息 ===${NC}"
    echo -e "${GREEN}主机名:${NC} $(hostname)"
    echo -e "${GREEN}操作系统:${NC} $OS_INFO"
    echo -e "${GREEN}内核版本:${NC} $(uname -r)"
    echo -e "${GREEN}系统架构:${NC} $ARCH"
    echo ""
    
    # CPU信息
    echo -e "${CYAN}=== CPU信息 ===${NC}"
    echo -e "${GREEN}CPU型号:${NC} $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')"
    echo -e "${GREEN}CPU核心数:${NC} $(grep -c 'processor' /proc/cpuinfo)"
    echo ""
    
    # 内存信息
    echo -e "${CYAN}=== 内存信息 ===${NC}"
    total_mem=$(free -h | grep Mem | awk '{print $2}')
    used_mem=$(free -h | grep Mem | awk '{print $3}')
    free_mem=$(free -h | grep Mem | awk '{print $4}')
    echo -e "${GREEN}总内存:${NC} $total_mem"
    echo -e "${GREEN}已使用:${NC} $used_mem"
    echo -e "${GREEN}可用内存:${NC} $free_mem"
    echo ""
    
    # 磁盘信息
    echo -e "${CYAN}=== 磁盘信息 ===${NC}"
    df -h | grep -E '^/dev/|^Filesystem' | head -10
    echo ""
    
    # 网络信息
    echo -e "${CYAN}=== 网络信息 ===${NC}"
    echo -e "${GREEN}公网IP:${NC} $(curl -s ifconfig.me || echo "无法获取")"
    echo -e "${GREEN}内网IP:${NC} $(hostname -I | awk '{print $1}')"
    echo ""
    
    # 系统运行时间
    echo -e "${CYAN}=== 系统运行时间 ===${NC}"
    uptime
    echo ""
    
    read -p "按回车键返回主菜单..."
}

# 安装宝塔面板
install_baota() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          安装宝塔面板${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}警告: 安装宝塔面板需要几分钟时间，请耐心等待...${NC}"
    echo ""
    
    # 检查是否已安装
    if command -v bt &> /dev/null; then
        echo -e "${GREEN}宝塔面板已安装${NC}"
        echo -e "面板地址: https://$(hostname -I | awk '{print $1}'):8888"
        echo -e "默认用户名: admin"
        echo -e "获取默认密码: bt default"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    # 根据系统选择安装命令
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            echo -e "${CYAN}检测到 CentOS/RHEL/Fedora 系统，使用yum安装...${NC}"
            yum install -y wget && wget -O install.sh https://download.bt.cn/install/install_6.0.sh && bash install.sh
            ;;
        "ubuntu"|"debian")
            echo -e "${CYAN}检测到 Ubuntu/Debian 系统，使用apt安装...${NC}"
            wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh && bash install.sh
            ;;
        *)
            echo -e "${RED}不支持的系统: $DISTRO${NC}"
            echo -e "${YELLOW}请访问宝塔官网查看安装方法: https://www.bt.cn/new/download.html${NC}"
            read -p "按回车键返回主菜单..."
            return
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}宝塔面板安装完成！${NC}"
        echo ""
        echo -e "${CYAN}安装信息:${NC}"
        echo -e "面板地址: https://$(hostname -I | awk '{print $1}'):8888"
        echo -e "默认用户名: admin"
        echo -e "获取默认密码请执行: bt default"
        echo ""
        echo -e "${YELLOW}请妥善保管登录信息！${NC}"
    else
        echo -e "${RED}宝塔面板安装失败${NC}"
    fi
    
    read -p "按回车键返回主菜单..."
}

# 安装哪吒面板
install_ne_zha() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          安装哪吒监控面板${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: 哪吒面板需要访问 GitHub，请确保网络连接正常${NC}"
    echo ""
    
    # 检查是否已安装
    if [ -f "/opt/nezha/agent/nezha-agent" ]; then
        echo -e "${GREEN}哪吒面板客户端已安装${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    # 安装依赖
    echo -e "${CYAN}安装必要依赖...${NC}"
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            yum install -y wget curl unzip
            ;;
        "ubuntu"|"debian")
            apt update && apt install -y wget curl unzip
            ;;
    esac
    
    # 下载安装脚本
    echo -e "${CYAN}下载哪吒面板安装脚本...${NC}"
    wget -O nezha.sh https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh
    chmod +x nezha.sh
    
    if [ ! -f "nezha.sh" ]; then
        echo -e "${RED}下载安装脚本失败，请检查网络连接${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}哪吒面板需要以下信息:${NC}"
    echo -e "1. 面板地址 (例如: https://dashboard.example.com)"
    echo -e "2. 通信密钥 (在面板后台获取)"
    echo -e "3. 客户端ID (在面板后台添加客户端后获得)"
    echo ""
    echo -e "${CYAN}请准备好以上信息后再继续${NC}"
    echo ""
    
    read -p "是否继续安装？(y/n): " choice
    if [[ $choice != "y" && $choice != "Y" ]]; then
        echo -e "${YELLOW}已取消安装${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    # 运行安装脚本
    echo -e "${CYAN}开始安装哪吒面板客户端...${NC}"
    bash nezha.sh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}哪吒面板客户端安装完成！${NC}"
        echo ""
        echo -e "${CYAN}使用说明:${NC}"
        echo -e "1. 访问哪吒面板管理后台"
        echo -e "2. 添加新的客户端"
        echo -e "3. 获取通信密钥和客户端ID"
        echo -e "4. 编辑配置文件: /opt/nezha/agent/config.yaml"
        echo -e "5. 重启服务: systemctl restart nezha-agent"
    else
        echo -e "${RED}哪吒面板安装失败${NC}"
    fi
    
    read -p "按回车键返回主菜单..."
}

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
        fi
        
        # 进入Docker菜单
        docker_menu
    else
        echo -e "${RED}Docker 安装失败${NC}"
        read -p "按回车键返回主菜单..."
    fi
}

# 安装X-UI面板
install_xui() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          安装 X-UI 面板${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: X-UI 是一个多协议代理工具，请遵守当地法律法规${NC}"
    echo ""
    
    # 检查是否已安装
    if [ -f "/usr/local/x-ui/x-ui" ]; then
        echo -e "${GREEN}X-UI 已安装${NC}"
        echo -e "面板地址: http://$(hostname -I | awk '{print $1}'):54321"
        echo -e "默认用户名: admin"
        echo -e "默认密码: admin"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo -e "${CYAN}安装必要依赖...${NC}"
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            yum install -y wget curl unzip
            ;;
        "ubuntu"|"debian")
            apt update && apt install -y wget curl unzip
            ;;
    esac
    
    echo -e "${CYAN}下载 X-UI 安装脚本...${NC}"
    wget -O x-ui-install.sh https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh
    
    if [ ! -f "x-ui-install.sh" ]; then
        echo -e "${RED}下载安装脚本失败，请检查网络连接${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    chmod +x x-ui-install.sh
    
    echo ""
    echo -e "${YELLOW}X-UI 安装选项:${NC}"
    echo -e "1. 全新安装"
    echo -e "2. 更新已有安装"
    echo ""
    
    read -p "请选择安装类型 (默认1): " install_type
    install_type=${install_type:-1}
    
    echo ""
    echo -e "${CYAN}开始安装 X-UI...${NC}"
    
    if [ "$install_type" = "1" ]; then
        bash x-ui-install.sh
    else
        bash x-ui-install.sh update
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}X-UI 安装完成！${NC}"
        echo ""
        echo -e "${CYAN}安装信息:${NC}"
        echo -e "面板地址: http://$(hostname -I | awk '{print $1}'):54321"
        echo -e "默认用户名: admin"
        echo -e "默认密码: admin"
        echo ""
        echo -e "${CYAN}常用命令:${NC}"
        echo -e "启动服务: systemctl start x-ui"
        echo -e "停止服务: systemctl stop x-ui"
        echo -e "重启服务: systemctl restart x-ui"
        echo -e "查看状态: systemctl status x-ui"
        echo -e "查看日志: journalctl -u x-ui -f"
        echo ""
        echo -e "${YELLOW}安全提示:${NC}"
        echo -e "1. 请立即修改默认密码"
        echo -e "2. 建议修改默认端口"
        echo -e "3. 配置防火墙规则"
        echo -e "4. 定期更新系统和X-UI"
    else
        echo -e "${RED}X-UI 安装失败${NC}"
        echo -e "请检查日志文件: /var/log/x-ui/install.log"
    fi
    
    read -p "按回车键返回主菜单..."
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
    docker-compose -f docker-compose-elk.yml up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}ELK 安装完成！${NC}"
        echo ""
        echo -e "${CYAN}访问地址:${NC}"
        echo -e "Kibana: http://$(hostname -I | awk '{print $1}'):5601"
        echo -e "Elasticsearch: http://$(hostname -I | awk '{print $1}'):9200"
        echo -e "Logstash: TCP端口 5000"
        echo ""
        echo -e "${YELLOW}管理命令:${NC}"
        echo -e "停止服务: docker-compose -f docker-compose-elk.yml stop"
        echo -e "启动服务: docker-compose -f docker-compose-elk.yml start"
        echo -e "查看日志: docker-compose -f docker-compose-elk.yml logs -f"
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
        echo -e "主机: $(hostname -I | awk '{print $1}')"
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
    sed -i "s/SERVER_IP/$(hostname -I | awk '{print $1}')/g" $nginx_html/index.html
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
        echo -e "HTTP: http://$(hostname -I | awk '{print $1}')"
        echo -e "HTTPS: https://$(hostname -I | awk '{print $1}') (需要配置证书)"
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
        echo -e "主机: $(hostname -I | awk '{print $1}')"
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
    docker-compose -f docker-compose-wordpress.yml up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}WordPress 安装完成！${NC}"
        echo ""
        echo -e "${CYAN}访问地址:${NC}"
        echo -e "WordPress: http://$(hostname -I | awk '{print $1}'):$wp_port"
        echo ""
        echo -e "${CYAN}数据库信息:${NC}"
        echo -e "主机: db (容器内)"
        echo -e "端口: 3306"
        echo -e "数据库名: wordpress"
        echo -e "用户名: wordpress"
        echo -e "密码: $wp_db_pass"
        echo ""
        echo -e "${YELLOW}管理命令:${NC}"
        echo -e "停止服务: docker-compose -f docker-compose-wordpress.yml stop"
        echo -e "启动服务: docker-compose -f docker-compose-wordpress.yml start"
        echo -e "查看日志: docker-compose -f docker-compose-wordpress.yml logs -f"
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
    docker-compose --version
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
                    echo -e "${CYAN}正在进入容器 $container_name ...${NC}"
                    echo -e "${YELLOW}输入 'exit' 退出容器${NC}"
                    docker exec -it $container_name /bin/bash || docker exec -it $container_name /bin/sh
                fi
                ;;
            7)
                return
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# DNS污染检测与GitHub IP修复
fix_github_dns() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}      GitHub DNS污染检测与修复${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}正在检测GitHub域名DNS污染情况...${NC}"
    echo ""
    
    # 检查DNS解析是否正常
    local dns_ok=true
    local domains=($GITHUB_DOMAINS)
    
    for domain in "${domains[@]}"; do
        echo -e "检测域名: ${YELLOW}$domain${NC}"
        
        # 尝试解析域名
        local ip_result
        ip_result=$(dig +short $domain @8.8.8.8 2>/dev/null | head -1)
        
        if [ -z "$ip_result" ]; then
            echo -e "  ${RED}✗ DNS解析失败${NC}"
            dns_ok=false
        elif [[ $ip_result =~ ^(127\.|0\.|169\.254|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.) ]]; then
            echo -e "  ${RED}✗ 检测到污染IP: $ip_result${NC}"
            dns_ok=false
        else
            echo -e "  ${GREEN}✓ 解析正常: $ip_result${NC}"
        fi
    done
    
    echo ""
    
    if $dns_ok; then
        echo -e "${GREEN}DNS解析正常，无需修复${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo -e "${YELLOW}检测到DNS污染问题，正在获取最新可用的GitHub IP地址...${NC}"
    echo ""
    
    # 从多个来源获取最新的GitHub IP地址
    echo -e "${CYAN}尝试从多个来源获取GitHub IP地址...${NC}"
    
    # 常见的GitHub IP地址（这些需要定期更新）
    local github_ips=()
    
    # 尝试从ipaddress.com获取
    echo -e "1. 从ipaddress.com获取..."
    local ip1=$(curl -s https://ipaddress.com/website/github.com | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -5 | tail -1 2>/dev/null)
    if [ -n "$ip1" ]; then
        github_ips+=("$ip1")
        echo -e "   ${GREEN}获取到IP: $ip1${NC}"
    else
        echo -e "   ${YELLOW}获取失败${NC}"
    fi
    
    # 尝试从chinaz.com获取
    echo -e "2. 从站长之家获取..."
    local ip2=$(curl -s "http://ping.chinaz.com/github.com" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -3 | tail -1 2>/dev/null)
    if [ -n "$ip2" ]; then
        github_ips+=("$ip2")
        echo -e "   ${GREEN}获取到IP: $ip2${NC}"
    else
        echo -e "   ${YELLOW}获取失败${NC}"
    fi
    
    # 备用IP地址列表（这些是GitHub的常用IP段）
    local backup_ips=(
        "20.205.243.166"  # GitHub常用IP
        "20.27.177.113"   # GitHub常用IP
        "192.30.255.113"  # GitHub官方IP
        "140.82.114.4"    # GitHub官方IP
        "140.82.112.4"    # GitHub官方IP
        "140.82.113.4"    # GitHub官方IP
    )
    
    # 如果没有获取到IP，使用备用IP
    if [ ${#github_ips[@]} -eq 0 ]; then
        echo -e "${YELLOW}从在线服务获取失败，使用备用IP地址${NC}"
        github_ips=("${backup_ips[@]}")
    fi
    
    echo ""
    echo -e "${CYAN}测试IP地址连通性...${NC}"
    
    local best_ip=""
    local best_time=99999
    
    # 测试每个IP的连通性
    for ip in "${github_ips[@]}"; do
        echo -e "测试IP: ${YELLOW}$ip${NC}"
        
        # 使用ping测试延迟
        local ping_result
        ping_result=$(timeout 3 ping -c 2 -W 1 $ip 2>/dev/null | grep "time=" | head -1 | awk -F'time=' '{print $2}' | awk '{print $1}')
        
        if [ -n "$ping_result" ]; then
            echo -e "  ${GREEN}✓ 延迟: ${ping_result}ms${NC}"
            
            # 转换为整数比较
            local ping_int=$(echo "$ping_result" | cut -d'.' -f1)
            
            if [ -z "$ping_int" ]; then
                ping_int=0
            fi
            
            if [ $ping_int -lt $best_time ]; then
                best_time=$ping_int
                best_ip=$ip
            fi
        else
            echo -e "  ${RED}✗ 无法连接${NC}"
        fi
    done
    
    echo ""
    
    if [ -z "$best_ip" ]; then
        echo -e "${RED}所有IP地址都无法连接，无法修复DNS问题${NC}"
        echo -e "${YELLOW}建议检查网络连接或使用代理${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo -e "${GREEN}找到最佳IP地址: ${best_ip} (延迟: ${best_time}ms)${NC}"
    echo ""
    
    echo -e "${CYAN}备份当前hosts文件...${NC}"
    cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "备份文件: ${YELLOW}/etc/hosts.backup.$(date +%Y%m%d_%H%M%S)${NC}"
    
    echo ""
    echo -e "${CYAN}更新hosts文件...${NC}"
    
    # 创建临时hosts文件
    local temp_hosts=$(mktemp)
    
    # 复制原有hosts文件，但移除旧的GitHub条目
    grep -v -E "(github\.com|raw\.githubusercontent\.com|github\.github\.io|api\.github\.com)" /etc/hosts > "$temp_hosts"
    
    # 添加新的GitHub条目
    echo "" >> "$temp_hosts"
    echo "# GitHub domains (updated by Linux Panel Installer on $(date))" >> "$temp_hosts"
    echo "$best_ip github.com" >> "$temp_hosts"
    echo "$best_ip raw.githubusercontent.com" >> "$temp_hosts"
    echo "$best_ip github.github.io" >> "$temp_hosts"
    echo "$best_ip api.github.com" >> "$temp_hosts"
    
    # 替换原有hosts文件
    cp "$temp_hosts" /etc/hosts
    rm -f "$temp_hosts"
    
    echo -e "${GREEN}hosts文件更新完成！${NC}"
    echo ""
    
    # 刷新DNS缓存
    echo -e "${CYAN}刷新DNS缓存...${NC}"
    
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            systemctl restart systemd-resolved 2>/dev/null || systemctl restart NetworkManager 2>/dev/null
            ;;
        "ubuntu"|"debian")
            systemctl restart systemd-resolved 2>/dev/null || /etc/init.d/nscd restart 2>/dev/null
            ;;
    esac
    
    echo -e "${GREEN}DNS缓存已刷新${NC}"
    echo ""
    
    # 测试修复效果
    echo -e "${CYAN}测试修复效果...${NC}"
    
    local test_result
    test_result=$(curl -s -I --connect-timeout 5 "$DNS_TEST_URL" 2>/dev/null | head -1)
    
    if [[ "$test_result" == *"200"* ]] || [[ "$test_result" == *"302"* ]]; then
        echo -e "${GREEN}✓ 修复成功！GitHub访问已恢复正常${NC}"
        
        # 显示更新后的hosts文件相关部分
        echo ""
        echo -e "${CYAN}更新后的hosts文件内容（GitHub相关）:${NC}"
        grep -A5 "GitHub domains" /etc/hosts
    else
        echo -e "${YELLOW}⚠ 修复可能未完全生效，建议重启网络服务${NC}"
        echo -e "  可以尝试执行: systemctl restart network 或 systemctl restart networking"
    fi
    
    echo ""
    echo -e "${YELLOW}提示:${NC}"
    echo -e "1. 如果GitHub访问仍然有问题，可能需要重启系统"
    echo -e "2. GitHub IP地址可能会变化，建议定期运行此功能更新"
    echo -e "3. 原始hosts文件已备份: /etc/hosts.backup.*"
    
    read -p "按回车键返回主菜单..."
}

# 主菜单
main_menu() {
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}      Linux 面板与工具安装脚本${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo ""
        echo -e "${CYAN}系统信息:${NC} $OS_INFO"
        echo -e "${CYAN}系统架构:${NC} $ARCH"
        echo -e "${CYAN}当前时间:${NC} $(date)"
        echo ""
        echo -e "${GREEN}1.${NC} 安装宝塔面板"
        echo -e "${GREEN}2.${NC} 安装哪吒监控面板"
        echo -e "${GREEN}3.${NC} 安装 X-UI 面板"
        echo -e "${GREEN}4.${NC} DNS污染检测与修复"
        echo -e "${GREEN}5.${NC} 安装 Docker"
        echo -e "${GREEN}6.${NC} 服务器信息"
        echo -e "${GREEN}7.${NC} 退出脚本"
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}提示: 请确保系统有足够的磁盘空间和内存${NC}"
        echo ""
        
        read -p "请选择功能 (1-7): " choice
        
        case $choice in
            1)
                install_baota
                ;;
            2)
                install_ne_zha
                ;;
            3)
                install_xui
                ;;
            4)
                fix_github_dns
                ;;
            5)
                install_docker
                ;;
            6)
                show_system_info
                ;;
            7)
                echo -e "${GREEN}感谢使用，再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 脚本入口
main() {
    # 检查root权限
    check_root
    
    # 显示欢迎信息
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}      Linux 面板与工具安装脚本${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${CYAN}版本: 1.2${NC}"
    echo -e "${CYAN}更新: 添加DNS污染检测与修复功能${NC}"
    echo -e "${CYAN}作者: Linux运维助手${NC}"
    echo -e "${CYAN}日期: $(date)${NC}"
    echo ""
    
    # 获取系统信息
    get_system_info
    
    # 显示主菜单
    main_menu
}

# 运行主函数
main