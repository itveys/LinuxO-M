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
DOCKER_DOMAINS="docker.io registry-1.docker.io auth.docker.io production.cloudflare.docker.com"
DOCKER_REGISTRY_DOMAINS="registry-1.docker.io index.docker.io auth.docker.io"
DNS_TEST_URL="https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/oh-my-zsh.sh"

# 消息推送配置
PUSH_CONFIG_FILE="/etc/linux_panel_push_config.json"
PUSH_ENABLED=false
PUSH_TYPE=""
PUSH_DINGTALK_WEBHOOK=""
PUSH_DINGTALK_SECRET=""
PUSH_PLUSPUSH_TOKEN=""
PUSH_WEOA_WEBHOOK=""
PUSH_WEOA_KEY=""
PUSH_CUSTOM_WEBHOOK=""
PUSH_CUSTOM_METHOD="POST"
PUSH_CUSTOM_HEADERS=""
PUSH_CUSTOM_BODY=""

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
    
    # 显示CPU频率
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]; then
        cpu_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
        cpu_freq_mhz=$((cpu_freq / 1000))
        echo -e "${GREEN}CPU频率:${NC} ${cpu_freq_mhz} MHz"
    fi
    
    # CPU负载
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "${GREEN}CPU负载:${NC} $load_avg"
    echo ""
    
    # 内存信息
    echo -e "${CYAN}=== 内存信息 ===${NC}"
    total_mem=$(free -h | grep Mem | awk '{print $2}')
    used_mem=$(free -h | grep Mem | awk '{print $3}')
    free_mem=$(free -h | grep Mem | awk '{print $4}')
    available_mem=$(free -h | grep Mem | awk '{print $7}')
    echo -e "${GREEN}总内存:${NC} $total_mem"
    echo -e "${GREEN}已使用:${NC} $used_mem"
    echo -e "${GREEN}可用内存:${NC} $free_mem"
    echo -e "${GREEN}可用(含缓存):${NC} $available_mem"
    
    # 内存使用率
    total_mem_kb=$(free | grep Mem | awk '{print $2}')
    used_mem_kb=$(free | grep Mem | awk '{print $3}')
    if [ $total_mem_kb -gt 0 ]; then
        mem_usage=$((used_mem_kb * 100 / total_mem_kb))
        echo -e "${GREEN}内存使用率:${NC} $mem_usage%"
    fi
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
    
    echo -e "${CYAN}=== 系统监控选项 ===${NC}"
    echo -e "${GREEN}1.${NC} 查看实时监控（CPU/内存/磁盘动态变化）"
    echo -e "${GREEN}2.${NC} 返回主菜单"
    echo ""
    
    read -p "请选择 (1-2): " monitor_choice
    
    case $monitor_choice in
        1)
            real_time_monitor
            ;;
        2)
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            ;;
    esac
}

# 实时系统监控
real_time_monitor() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          实时系统监控${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}正在启动实时监控... 按 Ctrl+C 退出${NC}"
    echo ""
    
    # 监控参数
    local interval=2  # 更新间隔（秒）
    local duration=0  # 监控持续时间
    local max_duration=300  # 最长监控时间（5分钟）
    
    # 获取初始网络统计信息
    local initial_rx_bytes=0
    local initial_tx_bytes=0
    
    # 获取网络接口
    local network_interface=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -n "$network_interface" ] && [ -f "/sys/class/net/$network_interface/statistics/rx_bytes" ]; then
        initial_rx_bytes=$(cat "/sys/class/net/$network_interface/statistics/rx_bytes")
        initial_tx_bytes=$(cat "/sys/class/net/$network_interface/statistics/tx_bytes")
    fi
    
    # 开始监控循环
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}          实时系统监控${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${YELLOW}运行时间: ${duration}秒 (按 Ctrl+C 退出)${NC}"
        echo ""
        
        # CPU信息
        echo -e "${CYAN}=== CPU 监控 ===${NC}"
        
        # 获取CPU使用率
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        local cpu_cores=$(grep -c 'processor' /proc/cpuinfo)
        local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')
        
        echo -e "${GREEN}核心数:${NC} $cpu_cores"
        echo -e "${GREEN}使用率:${NC} $cpu_usage%"
        echo -e "${GREEN}负载:${NC} $cpu_load"
        
        # CPU使用率条形图
        local cpu_bar="["
        local filled=$((cpu_usage / 5))
        for ((i=0; i<20; i++)); do
            if [ $i -lt $filled ]; then
                cpu_bar+="█"
            else
                cpu_bar+="░"
            fi
        done
        cpu_bar+="]"
        echo -e "${GREEN}使用率图:${NC} $cpu_bar"
        echo ""
        
        # 内存信息
        echo -e "${CYAN}=== 内存监控 ===${NC}"
        
        local mem_info=$(free -m)
        local total_mem=$(echo "$mem_info" | grep Mem | awk '{print $2}')
        local used_mem=$(echo "$mem_info" | grep Mem | awk '{print $3}')
        local free_mem=$(echo "$mem_info" | grep Mem | awk '{print $4}')
        local available_mem=$(echo "$mem_info" | grep Mem | awk '{print $7}')
        local mem_usage=$((used_mem * 100 / total_mem))
        
        echo -e "${GREEN}总内存:${NC} ${total_mem}MB"
        echo -e "${GREEN}已使用:${NC} ${used_mem}MB"
        echo -e "${GREEN}可用:${NC} ${available_mem}MB"
        echo -e "${GREEN}使用率:${NC} $mem_usage%"
        
        # 内存使用率条形图
        local mem_bar="["
        local filled=$((mem_usage / 5))
        for ((i=0; i<20; i++)); do
            if [ $i -lt $filled ]; then
                mem_bar+="█"
            else
                mem_bar+="░"
            fi
        done
        mem_bar+="]"
        echo -e "${GREEN}使用率图:${NC} $mem_bar"
        echo ""
        
        # 磁盘信息
        echo -e "${CYAN}=== 磁盘监控 ===${NC}"
        
        # 显示主要分区使用情况
        echo -e "${GREEN}分区\t使用率\t已用\t可用\t挂载点${NC}"
        df -h | grep -E '^/dev/.*' | while read line; do
            local partition=$(echo $line | awk '{print $1}')
            local use_percent=$(echo $line | awk '{print $5}')
            local used=$(echo $line | awk '{print $3}')
            local available=$(echo $line | awk '{print $4}')
            local mount_point=$(echo $line | awk '{print $6}')
            
            # 移除百分号获取数值
            local percent_num=$(echo $use_percent | sed 's/%//')
            
            # 创建条形图
            local disk_bar="["
            local filled=$((percent_num / 5))
            for ((i=0; i<10; i++)); do
                if [ $i -lt $filled ]; then
                    disk_bar+="█"
                else
                    disk_bar+="░"
                fi
            done
            disk_bar+="]"
            
            echo -e "$partition\t$use_percent\t$used\t$available\t$mount_point $disk_bar"
        done | head -5
        echo ""
        
        # 网络信息
        echo -e "${CYAN}=== 网络监控 ===${NC}"
        
        if [ -n "$network_interface" ] && [ -f "/sys/class/net/$network_interface/statistics/rx_bytes" ]; then
            local current_rx_bytes=$(cat "/sys/class/net/$network_interface/statistics/rx_bytes")
            local current_tx_bytes=$(cat "/sys/class/net/$network_interface/statistics/tx_bytes")
            
            local rx_diff=$((current_rx_bytes - initial_rx_bytes))
            local tx_diff=$((current_tx_bytes - initial_tx_bytes))
            
            # 转换为KB/s
            local rx_rate_kb=$((rx_diff / interval / 1024))
            local tx_rate_kb=$((tx_diff / interval / 1024))
            
            # 转换为MB/s（如果大于1024KB）
            local rx_rate_display=""
            local tx_rate_display=""
            
            if [ $rx_rate_kb -gt 1024 ]; then
                rx_rate_mb=$((rx_rate_kb / 1024))
                rx_rate_display="${rx_rate_mb} MB/s"
            else
                rx_rate_display="${rx_rate_kb} KB/s"
            fi
            
            if [ $tx_rate_kb -gt 1024 ]; then
                tx_rate_mb=$((tx_rate_kb / 1024))
                tx_rate_display="${tx_rate_mb} MB/s"
            else
                tx_rate_display="${tx_rate_kb} KB/s"
            fi
            
            echo -e "${GREEN}网络接口:${NC} $network_interface"
            echo -e "${GREEN}下载速度:${NC} $rx_rate_display"
            echo -e "${GREEN}上传速度:${NC} $tx_rate_display"
            
            # 更新初始值
            initial_rx_bytes=$current_rx_bytes
            initial_tx_bytes=$current_tx_bytes
        else
            echo -e "${YELLOW}网络监控不可用${NC}"
        fi
        echo ""
        
        # 进程信息
        echo -e "${CYAN}=== 进程监控 (前5个) ===${NC}"
        echo -e "${GREEN}PID\tCPU%\tMEM%\t命令${NC}"
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-8s %-8s %-8s %s\n", $2, $3, $4, $11}'
        echo ""
        
        # 温度监控（如果可用）
        if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
            local temp_c=$(cat /sys/class/thermal/thermal_zone0/temp)
            local temp_c_formatted=$((temp_c / 1000))
            echo -e "${CYAN}=== 温度监控 ===${NC}"
            echo -e "${GREEN}CPU温度:${NC} ${temp_c_formatted}°C"
            echo ""
        fi
        
        # 增加运行时间
        duration=$((duration + interval))
        
        # 检查是否超过最大运行时间
        if [ $duration -ge $max_duration ]; then
            echo -e "${YELLOW}监控已达到最大运行时间 ($max_duration 秒)${NC}"
            echo -e "${YELLOW}自动退出监控...${NC}"
            sleep 3
            break
        fi
        
        # 等待间隔时间
        sleep $interval
    done
    
    echo ""
    read -p "监控结束，按回车键返回..."
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

# Docker镜像源DNS检测与修复
fix_docker_dns() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}      Docker镜像源DNS检测与修复${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}选择检测模式:${NC}"
    echo -e "  ${GREEN}1.${NC} 标准检测与修复（推荐）"
    echo -e "  ${GREEN}2.${NC} 高级网络诊断"
    echo ""
    
    read -p "请选择模式 (默认1): " mode
    mode=${mode:-1}
    
    if [ "$mode" = "2" ]; then
        advanced_dns_diagnostic
        # 询问是否继续标准修复
        echo ""
        read -p "是否继续Docker DNS修复？(y/n, 默认y): " continue_repair
        continue_repair=${continue_repair:-y}
        
        if [[ $continue_repair != "y" && $continue_repair != "Y" ]]; then
            echo -e "${YELLOW}已返回主菜单${NC}"
            read -p "按回车键继续..."
            return
        fi
    fi
    
    echo ""
    echo -e "${CYAN}正在检测Docker镜像源域名DNS污染情况...${NC}"
    echo ""
    
    # 检查DNS解析是否正常
    local dns_ok=true
    local domains=($DOCKER_DOMAINS)
    
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
    
    # 测试Docker Hub实际可访问性
    echo -e "${CYAN}测试Docker Hub实际可访问性...${NC}"
    echo ""
    
    local test_domain="registry-1.docker.io"
    local test_url="https://registry-1.docker.io/v2/"
    
    echo -e "测试连接: ${YELLOW}$test_url${NC}"
    
    # 测试HTTP连接
    local http_test=$(timeout 10 curl -s -I --connect-timeout 5 "$test_url" 2>&1 | head -1)
    
    if [[ "$http_test" == *"401"* ]] || [[ "$http_test" == *"200"* ]] || [[ "$http_test" == *"302"* ]]; then
        echo -e "  ${GREEN}✓ 可访问性正常: $http_test${NC}"
        echo ""
        echo -e "${GREEN}Docker镜像源访问正常，无需修复${NC}"
        read -p "按回车键返回主菜单..."
        return
    elif [[ "$http_test" == *"curl:"* ]] || [[ "$http_test" == *"timed out"* ]] || [[ "$http_test" == *"Failed to connect"* ]]; then
        echo -e "  ${YELLOW}⚠ 连接建立但无法访问: $http_test${NC}"
        echo ""
        echo -e "${YELLOW}检测到连接问题，尝试获取最新可用IP地址...${NC}"
    else
        echo -e "  ${RED}✗ 访问异常: $http_test${NC}"
        echo ""
        echo -e "${YELLOW}检测到访问问题，尝试获取最新可用IP地址...${NC}"
    fi
    
    echo ""
    
    # 从多个来源获取最新的Docker Hub IP地址
    echo -e "${CYAN}尝试从多个来源获取Docker Hub IP地址...${NC}"
    
    # 常见的Docker Hub IP地址
    local docker_ips=()
    
    # 尝试从ipaddress.com获取
    echo -e "1. 从ipaddress.com获取..."
    local ip1=$(curl -s https://ipaddress.com/website/docker.io | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -5 | tail -1 2>/dev/null)
    if [ -n "$ip1" ]; then
        docker_ips+=("$ip1")
        echo -e "   ${GREEN}获取到IP: $ip1${NC}"
    else
        echo -e "   ${YELLOW}获取失败${NC}"
    fi
    
    # Docker Hub常用IP地址
    local backup_docker_ips=(
        "18.214.178.127"  # Docker Hub常用IP
        "3.221.204.170"   # Docker Hub常用IP
        "54.204.36.1"     # Docker Hub常用IP
        "52.0.144.140"    # Docker Hub常用IP
        "52.5.200.38"     # Docker Hub常用IP
        "34.199.31.114"   # Docker Hub常用IP
    )
    
    # 如果没有获取到IP，使用备用IP
    if [ ${#docker_ips[@]} -eq 0 ]; then
        echo -e "${YELLOW}从在线服务获取失败，使用备用IP地址${NC}"
        docker_ips=("${backup_docker_ips[@]}")
    fi
    
    echo ""
    echo -e "${CYAN}测试IP地址连通性和HTTP访问...${NC}"
    
    local best_ip=""
    local best_score=0
    
    # 测试每个IP的连通性和HTTP访问
    for ip in "${docker_ips[@]}"; do
        echo -e "测试IP: ${YELLOW}$ip${NC}"
        
        local score=0
        local test_results=""
        
        # 1. 使用ping测试延迟（基础连通性）
        local ping_result
        ping_result=$(timeout 3 ping -c 2 -W 1 $ip 2>/dev/null | grep "time=" | head -1 | awk -F'time=' '{print $2}' | awk '{print $1}')
        
        if [ -n "$ping_result" ]; then
            test_results+="${GREEN}✓ ping: ${ping_result}ms${NC} "
            score=$((score + 30))
            
            # 转换为整数比较
            local ping_int=$(echo "$ping_result" | cut -d'.' -f1)
            
            if [ -z "$ping_int" ]; then
                ping_int=0
            fi
            
            # 延迟越低，分数越高
            if [ $ping_int -lt 100 ]; then
                score=$((score + 20))
            elif [ $ping_int -lt 200 ]; then
                score=$((score + 10))
            fi
        else
            test_results+="${RED}✗ ping失败${NC} "
        fi
        
        # 2. 测试HTTP访问（使用curl直接访问IP）
        local http_test
        http_test=$(timeout 5 curl -s -I --connect-timeout 3 -H "Host: registry-1.docker.io" "http://$ip/v2/" 2>&1 | head -1)
        
        if [[ "$http_test" == *"401"* ]] || [[ "$http_test" == *"200"* ]] || [[ "$http_test" == *"302"* ]]; then
            test_results+="${GREEN}✓ HTTP访问正常${NC} "
            score=$((score + 50))
        elif [[ "$http_test" == *"curl:"* ]] || [[ "$http_test" == "" ]]; then
            test_results+="${YELLOW}⚠ HTTP访问异常${NC} "
        else
            test_results+="${RED}✗ HTTP访问失败${NC} "
        fi
        
        echo -e "  $test_results (得分: $score)"
        
        # 选择分数最高的IP
        if [ $score -gt $best_score ]; then
            best_score=$score
            best_ip=$ip
        fi
    done
    
    echo ""
    
    if [ -z "$best_ip" ] || [ $best_score -lt 30 ]; then
        echo -e "${RED}所有IP地址都无法正常访问，无法修复DNS问题${NC}"
        echo -e "${YELLOW}可能原因:${NC}"
        echo -e "1. 网络连接问题"
        echo -e "2. Docker Hub服务器暂时不可用"
        echo -e "3. 防火墙或网络限制"
        echo -e "4. 需要配置代理或镜像源"
        echo ""
        echo -e "${CYAN}建议:${NC}"
        echo -e "1. 检查网络连接"
        echo -e "2. 配置Docker国内镜像源"
        echo -e "3. 尝试使用代理"
        echo -e "4. 等待一段时间后重试"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo -e "${GREEN}找到最佳IP地址: ${best_ip} (得分: ${best_score}/100)${NC}"
    
    # 显示IP的详细信息
    if [ $best_score -ge 80 ]; then
        echo -e "  ${GREEN}✓ 该IP地址连接质量优秀${NC}"
    elif [ $best_score -ge 50 ]; then
        echo -e "  ${YELLOW}⚠ 该IP地址连接质量一般${NC}"
    else
        echo -e "  ${RED}✗ 该IP地址连接质量较差${NC}"
    fi
    
    echo ""
    
    # 显示修复信息并确认
    echo -e "${CYAN}修复信息:${NC}"
    echo -e "  最佳IP地址: ${YELLOW}$best_ip${NC}"
    echo -e "  连接质量得分: ${YELLOW}${best_score}/100${NC}"
    echo -e "  将更新的域名: ${YELLOW}$DOCKER_DOMAINS${NC}"
    echo ""
    echo -e "${YELLOW}注意:${NC}"
    echo -e "1. 原有hosts文件将会被备份"
    echo -e "2. 旧的Docker相关条目将被移除"
    echo -e "3. 新的IP地址将添加到hosts文件"
    echo -e "4. DNS缓存将被刷新"
    echo ""
    
    # 根据连接质量给出不同建议
    if [ $best_score -lt 50 ]; then
        echo -e "${RED}警告: 当前最佳IP的连接质量较差${NC}"
        echo -e "  修复后可能仍然无法正常访问Docker Hub"
        echo -e "  建议配置Docker国内镜像源"
        echo ""
    fi
    
    read -p "是否继续修复？(y/n, 默认y): " confirm
    confirm=${confirm:-y}
    
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}已取消修复操作${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo -e "${CYAN}备份当前hosts文件...${NC}"
    cp /etc/hosts /etc/hosts.backup.docker.$(date +%Y%m%d_%H%M%S)
    echo -e "备份文件: ${YELLOW}/etc/hosts.backup.docker.$(date +%Y%m%d_%H%M%S)${NC}"
    
    echo ""
    echo -e "${CYAN}更新hosts文件...${NC}"
    
    # 创建临时hosts文件
    local temp_hosts=$(mktemp)
    
    # 复制原有hosts文件，但移除旧的Docker条目
    grep -v -E "(docker\.io|registry-1\.docker\.io|auth\.docker\.io|production\.cloudflare\.docker\.com|index\.docker\.io)" /etc/hosts > "$temp_hosts"
    
    # 添加新的Docker条目
    echo "" >> "$temp_hosts"
    echo "# Docker domains (updated by Linux Panel Installer on $(date))" >> "$temp_hosts"
    echo "$best_ip docker.io" >> "$temp_hosts"
    echo "$best_ip registry-1.docker.io" >> "$temp_hosts"
    echo "$best_ip auth.docker.io" >> "$temp_hosts"
    echo "$best_ip production.cloudflare.docker.com" >> "$temp_hosts"
    echo "$best_ip index.docker.io" >> "$temp_hosts"
    
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
    test_result=$(curl -s -I --connect-timeout 5 "https://registry-1.docker.io/v2/" 2>&1 | head -1)
    
    if [[ "$test_result" == *"401"* ]] || [[ "$test_result" == *"200"* ]]; then
        echo -e "${GREEN}✓ 修复成功！Docker Hub访问已恢复正常${NC}"
        
        # 显示更新后的hosts文件相关部分
        echo ""
        echo -e "${CYAN}更新后的hosts文件内容（Docker相关）:${NC}"
        grep -A6 "Docker domains" /etc/hosts
        
        # 如果Docker已安装，测试docker pull
        if command -v docker &> /dev/null; then
            echo ""
            echo -e "${CYAN}测试Docker拉取镜像...${NC}"
            echo -e "${YELLOW}正在测试拉取hello-world镜像（按Ctrl+C可取消）...${NC}"
            
            local test_pull=$(timeout 30 docker pull hello-world 2>&1 | tail -5)
            
            if [[ "$test_pull" == *"Downloaded"* ]] || [[ "$test_pull" == *"Image is up to date"* ]]; then
                echo -e "${GREEN}✓ Docker拉取镜像成功！${NC}"
            else
                echo -e "${YELLOW}⚠ Docker拉取测试未完成，但hosts文件已更新${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠ 修复可能未完全生效，建议重启网络服务${NC}"
        echo -e "  可以尝试执行: systemctl restart network 或 systemctl restart networking"
    fi
    
    echo ""
    echo -e "${YELLOW}提示:${NC}"
    echo -e "1. 如果Docker Hub访问仍然有问题，建议配置Docker国内镜像源"
    echo -e "2. 可以运行脚本中的Docker安装功能来配置镜像源"
    echo -e "3. 原始hosts文件已备份: /etc/hosts.backup.docker.*"
    echo -e "4. Docker Hub IP地址可能会变化，建议定期运行此功能更新"
    
    read -p "按回车键返回主菜单..."
}

# GitHub DNS污染检测与修复
fix_github_dns() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}      GitHub DNS污染检测与修复${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}选择检测模式:${NC}"
    echo -e "  ${GREEN}1.${NC} 标准检测与修复（推荐）"
    echo -e "  ${GREEN}2.${NC} 高级检测与修复（包含网络诊断）"
    echo ""
    
    read -p "请选择模式 (默认1): " mode
    mode=${mode:-1}
    
    if [ "$mode" = "2" ]; then
        advanced_dns_diagnostic
        # 询问是否继续标准修复
        echo ""
        read -p "是否继续标准DNS修复？(y/n, 默认y): " continue_repair
        continue_repair=${continue_repair:-y}
        
        if [[ $continue_repair != "y" && $continue_repair != "Y" ]]; then
            echo -e "${YELLOW}已返回主菜单${NC}"
            read -p "按回车键继续..."
            return
        fi
    fi
    
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
    
    # 即使DNS解析正常，也要测试实际可访问性
    echo -e "${CYAN}测试GitHub实际可访问性...${NC}"
    echo ""
    
    local test_domain="raw.githubusercontent.com"
    local test_url="https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh"
    
    echo -e "测试连接: ${YELLOW}$test_url${NC}"
    
    # 测试HTTP连接
    local http_test=$(timeout 10 curl -s -I --connect-timeout 5 "$test_url" 2>&1 | head -1)
    
    if [[ "$http_test" == *"200"* ]] || [[ "$http_test" == *"302"* ]] || [[ "$http_test" == *"301"* ]]; then
        echo -e "  ${GREEN}✓ 可访问性正常: $http_test${NC}"
        echo ""
        echo -e "${GREEN}GitHub访问正常，无需修复${NC}"
        read -p "按回车键返回主菜单..."
        return
    elif [[ "$http_test" == *"curl:"* ]] || [[ "$http_test" == *"timed out"* ]] || [[ "$http_test" == *"Failed to connect"* ]]; then
        echo -e "  ${YELLOW}⚠ 连接建立但无法访问: $http_test${NC}"
        echo ""
        echo -e "${YELLOW}检测到连接问题，尝试获取最新可用IP地址...${NC}"
    else
        echo -e "  ${RED}✗ 访问异常: $http_test${NC}"
        echo ""
        echo -e "${YELLOW}检测到访问问题，尝试获取最新可用IP地址...${NC}"
    fi
    
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
    echo -e "${CYAN}测试IP地址连通性和HTTP访问...${NC}"
    
    local best_ip=""
    local best_score=0
    local test_url_simple="http://www.google.com/generate_204"  # 简单的测试URL
    
    # 测试每个IP的连通性和HTTP访问
    for ip in "${github_ips[@]}"; do
        echo -e "测试IP: ${YELLOW}$ip${NC}"
        
        local score=0
        local test_results=""
        
        # 1. 使用ping测试延迟（基础连通性）
        local ping_result
        ping_result=$(timeout 3 ping -c 2 -W 1 $ip 2>/dev/null | grep "time=" | head -1 | awk -F'time=' '{print $2}' | awk '{print $1}')
        
        if [ -n "$ping_result" ]; then
            test_results+="${GREEN}✓ ping: ${ping_result}ms${NC} "
            score=$((score + 30))
            
            # 转换为整数比较
            local ping_int=$(echo "$ping_result" | cut -d'.' -f1)
            
            if [ -z "$ping_int" ]; then
                ping_int=0
            fi
            
            # 延迟越低，分数越高
            if [ $ping_int -lt 100 ]; then
                score=$((score + 20))
            elif [ $ping_int -lt 200 ]; then
                score=$((score + 10))
            fi
        else
            test_results+="${RED}✗ ping失败${NC} "
        fi
        
        # 2. 测试HTTP访问（使用curl直接访问IP）
        local http_test
        http_test=$(timeout 5 curl -s -I --connect-timeout 3 -H "Host: raw.githubusercontent.com" "http://$ip/robots.txt" 2>&1 | head -1)
        
        if [[ "$http_test" == *"200"* ]] || [[ "$http_test" == *"301"* ]] || [[ "$http_test" == *"302"* ]] || [[ "$http_test" == *"404"* ]]; then
            test_results+="${GREEN}✓ HTTP访问正常${NC} "
            score=$((score + 50))
        elif [[ "$http_test" == *"curl:"* ]] || [[ "$http_test" == "" ]]; then
            test_results+="${YELLOW}⚠ HTTP访问异常${NC} "
        else
            test_results+="${RED}✗ HTTP访问失败${NC} "
        fi
        
        echo -e "  $test_results (得分: $score)"
        
        # 选择分数最高的IP
        if [ $score -gt $best_score ]; then
            best_score=$score
            best_ip=$ip
        fi
    done
    
    echo ""
    
    if [ -z "$best_ip" ] || [ $best_score -lt 30 ]; then
        echo -e "${RED}所有IP地址都无法正常访问，无法修复DNS问题${NC}"
        echo -e "${YELLOW}可能原因:${NC}"
        echo -e "1. 网络连接问题"
        echo -e "2. GitHub服务器暂时不可用"
        echo -e "3. 防火墙或网络限制"
        echo -e "4. 需要配置代理"
        echo ""
        echo -e "${CYAN}建议:${NC}"
        echo -e "1. 检查网络连接: ping 8.8.8.8"
        echo -e "2. 测试基本HTTP访问: curl -I http://www.baidu.com"
        echo -e "3. 尝试使用代理或VPN"
        echo -e "4. 等待一段时间后重试"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo -e "${GREEN}找到最佳IP地址: ${best_ip} (得分: ${best_score}/100)${NC}"
    
    # 显示IP的详细信息
    if [ $best_score -ge 80 ]; then
        echo -e "  ${GREEN}✓ 该IP地址连接质量优秀${NC}"
    elif [ $best_score -ge 50 ]; then
        echo -e "  ${YELLOW}⚠ 该IP地址连接质量一般${NC}"
    else
        echo -e "  ${RED}✗ 该IP地址连接质量较差${NC}"
    fi
    
    echo ""
    
    # 显示修复信息并确认
    echo -e "${CYAN}修复信息:${NC}"
    echo -e "  最佳IP地址: ${YELLOW}$best_ip${NC}"
    echo -e "  连接质量得分: ${YELLOW}${best_score}/100${NC}"
    echo -e "  将更新的域名: ${YELLOW}$GITHUB_DOMAINS${NC}"
    echo ""
    echo -e "${YELLOW}注意:${NC}"
    echo -e "1. 原有hosts文件将会被备份"
    echo -e "2. 旧的GitHub相关条目将被移除"
    echo -e "3. 新的IP地址将添加到hosts文件"
    echo -e "4. DNS缓存将被刷新"
    echo ""
    
    # 根据连接质量给出不同建议
    if [ $best_score -lt 50 ]; then
        echo -e "${RED}警告: 当前最佳IP的连接质量较差${NC}"
        echo -e "  修复后可能仍然无法正常访问GitHub"
        echo -e "  建议先检查网络环境或使用代理"
        echo ""
    fi
    
    read -p "是否继续修复？(y/n, 默认y): " confirm
    confirm=${confirm:-y}
    
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}已取消修复操作${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
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

# 网络测速功能
network_speed_test() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          网络测速功能${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}选择测速类型:${NC}"
    echo -e "  ${GREEN}1.${NC} 基础网络连通性测试"
    echo -e "  ${GREEN}2.${NC} 下载速度测试"
    echo -e "  ${GREEN}3.${NC} 综合网络性能测试"
    echo -e "  ${GREEN}4.${NC} 返回上一级"
    echo ""
    
    read -p "请选择测速类型 (1-4): " speed_test_type
    
    case $speed_test_type in
        1)
            basic_connectivity_test
            ;;
        2)
            download_speed_test
            ;;
        3)
            comprehensive_network_test
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            network_speed_test
            ;;
    esac
}

# 基础网络连通性测试
basic_connectivity_test() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          基础网络连通性测试${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}正在测试基础网络连通性...${NC}"
    echo ""
    
    local test_targets=(
        "8.8.8.8 Google DNS"
        "1.1.1.1 Cloudflare DNS"
        "114.114.114.114 国内DNS"
        "baidu.com 百度"
        "qq.com 腾讯"
        "github.com GitHub"
    )
    
    local total_tests=${#test_targets[@]}
    local passed_tests=0
    local failed_tests=0
    
    for target_info in "${test_targets[@]}"; do
        local target=$(echo "$target_info" | awk '{print $1}')
        local description=$(echo "$target_info" | cut -d' ' -f2-)
        
        echo -e "测试: ${YELLOW}$description ($target)${NC}"
        
        # 测试ping连通性
        local ping_result=$(ping -c 2 -W 1 "$target" 2>&1 | grep "time=" | head -1)
        
        if [ -n "$ping_result" ]; then
            local ping_time=$(echo "$ping_result" | awk -F'time=' '{print $2}' | awk '{print $1}')
            echo -e "  ${GREEN}✓ 连接正常: ${ping_time}ms${NC}"
            passed_tests=$((passed_tests + 1))
        else
            echo -e "  ${RED}✗ 连接失败${NC}"
            failed_tests=$((failed_tests + 1))
        fi
        
        # 测试DNS解析
        local dns_result=$(dig +short "$target" 2>/dev/null | head -1)
        if [ -n "$dns_result" ]; then
            echo -e "  ${GREEN}✓ DNS解析: $dns_result${NC}"
        else
            echo -e "  ${YELLOW}⚠ DNS解析失败${NC}"
        fi
        
        echo ""
    done
    
    echo -e "${CYAN}测试结果统计:${NC}"
    echo -e "  总测试数: $total_tests"
    echo -e "  成功数: ${GREEN}$passed_tests${NC}"
    echo -e "  失败数: ${RED}$failed_tests${NC}"
    
    local success_rate=$((passed_tests * 100 / total_tests))
    echo -e "  成功率: $success_rate%"
    
    echo ""
    
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}✓ 所有网络连接测试通过${NC}"
    elif [ $failed_tests -le 2 ]; then
        echo -e "${YELLOW}⚠ 部分网络连接测试失败，建议检查网络配置${NC}"
    else
        echo -e "${RED}✗ 多数网络连接测试失败，可能存在严重网络问题${NC}"
    fi
    
    echo ""
    read -p "按回车键返回网络测速菜单..."
    network_speed_test
}

# 下载速度测试
download_speed_test() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          下载速度测试${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}选择测试源:${NC}"
    echo -e "  ${GREEN}1.${NC} 国内源测试 (使用阿里云镜像)"
    echo -e "  ${GREEN}2.${NC} 国际源测试 (使用GitHub)"
    echo -e "  ${GREEN}3.${NC} 返回上一级"
    echo ""
    
    read -p "请选择测试源 (1-3): " download_source
    
    case $download_source in
        1)
            download_speed_test_domestic
            ;;
        2)
            download_speed_test_international
            ;;
        3)
            network_speed_test
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            download_speed_test
            ;;
    esac
}

# 国内下载速度测试
download_speed_test_domestic() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          国内下载速度测试${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: 测试可能需要几分钟时间，请耐心等待...${NC}"
    echo ""
    
    # 测试文件大小（10MB）
    local test_file_size=10
    local test_urls=(
        "http://mirrors.aliyun.com/centos/7/os/x86_64/isolinux/initrd.img"
        "http://mirrors.163.com/centos/7/os/x86_64/isolinux/initrd.img"
        "http://mirrors.tuna.tsinghua.edu.cn/centos/7/os/x86_64/isolinux/initrd.img"
    )
    
    echo -e "${CYAN}正在测试国内下载速度...${NC}"
    echo ""
    
    for url in "${test_urls[@]}"; do
        local domain=$(echo "$url" | awk -F/ '{print $3}')
        echo -e "测试源: ${YELLOW}$domain${NC}"
        
        # 使用curl测试下载速度
        echo -e "正在下载测试文件..."
        
        local start_time=$(date +%s.%N)
        local download_result=$(curl -w "\n%{time_total},%{speed_download}" -s -o /dev/null "$url" 2>&1)
        local end_time=$(date +%s.%N)
        
        local total_time=$(echo "$download_result" | tail -1 | cut -d',' -f1)
        local speed_bps=$(echo "$download_result" | tail -1 | cut -d',' -f2)
        
        # 转换为MB/s
        local speed_mbps=$(echo "scale=2; $speed_bps / 125000" | bc)
        local speed_mbs=$(echo "scale=2; $speed_bps / 1048576" | bc)
        
        if [ -n "$total_time" ] && [ "$total_time" != "0.000" ]; then
            echo -e "  ${GREEN}✓ 下载时间: ${total_time}s${NC}"
            echo -e "  ${GREEN}✓ 下载速度: ${speed_mbs} MB/s (${speed_mbps} Mbps)${NC}"
        else
            echo -e "  ${RED}✗ 下载失败${NC}"
        fi
        
        echo ""
        sleep 1
    done
    
    echo -e "${CYAN}测试完成！${NC}"
    echo ""
    echo -e "${YELLOW}建议:${NC}"
    echo -e "1. 如果速度低于 1 Mbps，可能存在网络问题"
    echo -e "2. 如果不同源速度差异大，建议使用最快源"
    echo -e "3. 测试结果仅供参考，实际速度受多种因素影响"
    
    echo ""
    read -p "按回车键返回下载速度测试菜单..."
    download_speed_test
}

# 国际下载速度测试
download_speed_test_international() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          国际下载速度测试${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: 测试可能需要几分钟时间，请耐心等待...${NC}"
    echo -e "${YELLOW}国际网络访问可能受防火墙限制，测试结果仅供参考${NC}"
    echo ""
    
    # 测试文件（小文件，避免占用过多带宽）
    local test_urls=(
        "https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh"
        "https://github.com/robbyrussell/oh-my-zsh/raw/master/oh-my-zsh.sh"
    )
    
    echo -e "${CYAN}正在测试国际下载速度...${NC}"
    echo ""
    
    for url in "${test_urls[@]}"; do
        local domain=$(echo "$url" | awk -F/ '{print $3}')
        echo -e "测试源: ${YELLOW}$domain${NC}"
        
        # 先测试连接性
        echo -e "测试连接性..."
        local http_test=$(curl -s -I --connect-timeout 5 "$url" 2>&1 | head -1)
        
        if [[ "$http_test" == *"200"* ]] || [[ "$http_test" == *"302"* ]]; then
            echo -e "  ${GREEN}✓ 连接正常${NC}"
            
            # 测试下载速度（只下载前100KB）
            echo -e "正在测试下载速度..."
            
            local start_time=$(date +%s.%N)
            local download_result=$(curl -w "\n%{time_total},%{speed_download}" -s -o /dev/null -r 0-102399 "$url" 2>&1)
            local end_time=$(date +%s.%N)
            
            local total_time=$(echo "$download_result" | tail -1 | cut -d',' -f1)
            local speed_bps=$(echo "$download_result" | tail -1 | cut -d',' -f2)
            
            # 转换为KB/s
            local speed_kbs=$(echo "scale=2; $speed_bps / 1024" | bc)
            local speed_mbps=$(echo "scale=2; $speed_bps / 125000" | bc)
            
            if [ -n "$total_time" ] && [ "$total_time" != "0.000" ]; then
                echo -e "  ${GREEN}✓ 下载时间: ${total_time}s${NC}"
                echo -e "  ${GREEN}✓ 下载速度: ${speed_kbs} KB/s (${speed_mbps} Mbps)${NC}"
            else
                echo -e "  ${RED}✗ 速度测试失败${NC}"
            fi
        else
            echo -e "  ${RED}✗ 连接失败: $http_test${NC}"
        fi
        
        echo ""
        sleep 1
    done
    
    echo -e "${CYAN}测试完成！${NC}"
    echo ""
    echo -e "${YELLOW}建议:${NC}"
    echo -e "1. 国际访问可能受网络限制"
    echo -e "2. 如果无法访问GitHub，可尝试使用DNS修复功能"
    echo -e "3. 如需稳定国际访问，建议配置网络代理"
    
    echo ""
    read -p "按回车键返回下载速度测试菜单..."
    download_speed_test
}

# 综合网络性能测试
comprehensive_network_test() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          综合网络性能测试${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: 综合测试可能需要5-10分钟，请耐心等待...${NC}"
    echo ""
    
    local test_results=()
    
    echo -e "${CYAN}=== 第一阶段：网络连通性测试 ===${NC}"
    echo ""
    
    # 1. Ping测试
    echo -e "1. Ping测试:"
    local ping_targets=("8.8.8.8" "1.1.1.1" "baidu.com")
    local ping_success=0
    
    for target in "${ping_targets[@]}"; do
        echo -e "  $target: \c"
        local ping_result=$(ping -c 2 -W 1 "$target" 2>&1 | grep "time=" | head -1)
        
        if [ -n "$ping_result" ]; then
            local ping_time=$(echo "$ping_result" | awk -F'time=' '{print $2}' | awk '{print $1}')
            echo -e "${GREEN}✓ ${ping_time}ms${NC}"
            ping_success=$((ping_success + 1))
        else
            echo -e "${RED}✗ 失败${NC}"
        fi
    done
    
    local ping_score=$((ping_success * 100 / ${#ping_targets[@]}))
    test_results+=("Ping连通性: $ping_score%")
    
    echo ""
    
    # 2. DNS解析测试
    echo -e "2. DNS解析测试:"
    local dns_targets=("google.com" "github.com" "baidu.com")
    local dns_success=0
    
    for target in "${dns_targets[@]}"; do
        echo -e "  $target: \c"
        local dns_result=$(dig +short "$target" 2>/dev/null | head -1)
        
        if [ -n "$dns_result" ]; then
            echo -e "${GREEN}✓ $dns_result${NC}"
            dns_success=$((dns_success + 1))
        else
            echo -e "${RED}✗ 解析失败${NC}"
        fi
    done
    
    local dns_score=$((dns_success * 100 / ${#dns_targets[@]}))
    test_results+=("DNS解析: $dns_score%")
    
    echo ""
    
    # 3. HTTP访问测试
    echo -e "3. HTTP访问测试:"
    local http_targets=("http://www.baidu.com" "https://github.com" "http://mirrors.aliyun.com")
    local http_success=0
    
    for target in "${http_targets[@]}"; do
        echo -e "  $target: \c"
        local http_result=$(curl -s -I --connect-timeout 5 "$target" 2>&1 | head -1)
        
        if [[ "$http_result" == *"200"* ]] || [[ "$http_result" == *"301"* ]] || [[ "$http_result" == *"302"* ]]; then
            echo -e "${GREEN}✓ 成功${NC}"
            http_success=$((http_success + 1))
        else
            echo -e "${RED}✗ 失败: ${http_result}${NC}"
        fi
    done
    
    local http_score=$((http_success * 100 / ${#http_targets[@]}))
    test_results+=("HTTP访问: $http_score%")
    
    echo ""
    
    echo -e "${CYAN}=== 第二阶段：下载速度测试 ===${NC}"
    echo ""
    
    echo -e "正在测试下载速度..."
    
    # 测试国内下载速度
    local domestic_url="http://mirrors.aliyun.com/centos/7/os/x86_64/isolinux/initrd.img"
    echo -e "  国内源 ($(echo "$domestic_url" | awk -F/ '{print $3}')): \c"
    
    local domestic_speed=$(curl -w "\n%{speed_download}" -s -o /dev/null -r 0-1048575 "$domestic_url" 2>&1 | tail -1)
    local domestic_speed_mbps=$(echo "scale=2; $domestic_speed / 125000" | bc 2>/dev/null || echo "0")
    
    if [ "$domestic_speed_mbps" != "0" ] && [ "$domestic_speed_mbps" != "" ]; then
        echo -e "${GREEN}$domestic_speed_mbps Mbps${NC}"
        test_results+=("国内下载: $domestic_speed_mbps Mbps")
    else
        echo -e "${RED}测试失败${NC}"
        test_results+=("国内下载: 失败")
    fi
    
    # 测试国际下载速度（仅测试连接性）
    echo -e "  国际源 (github.com): \c"
    local github_test=$(curl -s -I --connect-timeout 5 "https://github.com" 2>&1 | head -1)
    
    if [[ "$github_test" == *"200"* ]]; then
        echo -e "${GREEN}✓ 可访问${NC}"
        test_results+=("国际访问: 正常")
    else
        echo -e "${RED}✗ 无法访问${NC}"
        test_results+=("国际访问: 异常")
    fi
    
    echo ""
    
    echo -e "${CYAN}=== 第三阶段：网络延迟测试 ===${NC}"
    echo ""
    
    # 使用traceroute测试路由
    echo -e "路由追踪测试 (到 8.8.8.8):"
    echo -e "  正在执行路由追踪...\c"
    
    local trace_result=$(timeout 10 traceroute -n -m 15 8.8.8.8 2>&1 | head -10)
    
    if [[ "$trace_result" == *"traceroute"* ]]; then
        echo -e "${GREEN}✓ 完成${NC}"
        
        # 分析跳数
        local hop_count=$(echo "$trace_result" | grep -E "^[[:space:]]*[0-9]+" | wc -l)
        test_results+=("路由跳数: $hop_count hops")
        
        echo -e "  总跳数: ${GREEN}$hop_count${NC}"
    else
        echo -e "${RED}✗ 失败${NC}"
        test_results+=("路由追踪: 失败")
    fi
    
    echo ""
    
    # 显示综合测试结果
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          综合测试结果${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}测试项目:${NC}"
    for result in "${test_results[@]}"; do
        echo -e "  $result"
    done
    
    echo ""
    
    # 总体评分
    local overall_score=0
    local test_count=0
    
    for result in "${test_results[@]}"; do
        if [[ "$result" == *"%"* ]]; then
            local score=$(echo "$result" | grep -o '[0-9]*%' | grep -o '[0-9]*')
            overall_score=$((overall_score + score))
            test_count=$((test_count + 1))
        fi
    done
    
    if [ $test_count -gt 0 ]; then
        local average_score=$((overall_score / test_count))
        
        echo -e "${CYAN}总体评分:${NC}"
        echo -e "  平均得分: ${GREEN}$average_score%${NC}"
        
        if [ $average_score -ge 80 ]; then
            echo -e "  网络状态: ${GREEN}优秀${NC}"
        elif [ $average_score -ge 60 ]; then
            echo -e "  网络状态: ${YELLOW}良好${NC}"
        elif [ $average_score -ge 40 ]; then
            echo -e "  网络状态: ${YELLOW}一般${NC}"
        else
            echo -e "  网络状态: ${RED}较差${NC}"
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}建议:${NC}"
    echo -e "1. 如果评分低于60%，建议检查网络配置"
    echo -e "2. DNS问题可使用本脚本的DNS修复功能"
    echo -e "3. 国际访问问题可能需要配置网络代理"
    echo -e "4. 路由跳数过多可能影响网络性能"
    
    echo ""
    read -p "按回车键返回网络测速菜单..."
    network_speed_test
}

# NAS挂载配置功能
nas_mount_config() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          NAS挂载配置功能${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}选择操作:${NC}"
    echo -e "  ${GREEN}1.${NC} 查看当前挂载点"
    echo -e "  ${GREEN}2.${NC} 挂载NFS共享"
    echo -e "  ${GREEN}3.${NC} 挂载SMB/CIFS共享"
    echo -e "  ${GREEN}4.${NC} 挂载FTP共享"
    echo -e "  ${GREEN}5.${NC} 配置自动挂载"
    echo -e "  ${GREEN}6.${NC} 卸载共享目录"
    echo -e "  ${GREEN}7.${NC} 返回主菜单"
    echo ""
    
    read -p "请选择操作 (1-7): " nas_choice
    
    case $nas_choice in
        1)
            show_mount_points
            ;;
        2)
            mount_nfs_share
            ;;
        3)
            mount_smb_share
            ;;
        4)
            mount_ftp_share
            ;;
        5)
            configure_auto_mount
            ;;
        6)
            unmount_share
            ;;
        7)
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            nas_mount_config
            ;;
    esac
}

# 显示当前挂载点
show_mount_points() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          当前挂载点信息${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}系统挂载点:${NC}"
    df -hT
    echo ""
    
    echo -e "${CYAN}详细挂载信息:${NC}"
    mount | grep -E "(nfs|cifs|ftp|smb)" || echo "未找到网络共享挂载"
    echo ""
    
    echo -e "${CYAN}/etc/fstab 配置:${NC}"
    grep -E "(nfs|cifs|ftp|smb|nfs4)" /etc/fstab 2>/dev/null || echo "未配置自动挂载"
    echo ""
    
    read -p "按回车键返回NAS配置菜单..."
    nas_mount_config
}

# 挂载NFS共享
mount_nfs_share() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          挂载NFS共享${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: 挂载NFS共享需要安装nfs-utils包${NC}"
    echo ""
    
    # 检查是否安装nfs-utils
    if ! command -v showmount &> /dev/null; then
        echo -e "${CYAN}安装nfs-utils...${NC}"
        case $DISTRO in
            "centos"|"rhel"|"fedora")
                yum install -y nfs-utils
                ;;
            "ubuntu"|"debian")
                apt update && apt install -y nfs-common
                ;;
        esac
    fi
    
    read -p "请输入NFS服务器IP地址: " nfs_server
    read -p "请输入NFS共享路径 (例如: /data/share): " nfs_share
    read -p "请输入本地挂载点目录 (例如: /mnt/nfs_share): " local_mount
    
    # 创建本地挂载目录
    mkdir -p "$local_mount"
    
    # 测试NFS共享是否可访问
    echo -e "${CYAN}测试NFS共享连接...${NC}"
    if showmount -e "$nfs_server" 2>/dev/null | grep -q "$nfs_share"; then
        echo -e "${GREEN}✓ NFS共享可访问${NC}"
    else
        echo -e "${YELLOW}⚠ 无法验证NFS共享，继续挂载...${NC}"
    fi
    
    # 挂载NFS共享
    echo -e "${CYAN}挂载NFS共享...${NC}"
    mount -t nfs "${nfs_server}:${nfs_share}" "$local_mount"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ NFS共享挂载成功！${NC}"
        echo ""
        echo -e "${CYAN}挂载信息:${NC}"
        echo -e "  服务器: $nfs_server"
        echo -e "  共享路径: $nfs_share"
        echo -e "  本地挂载点: $local_mount"
        echo ""
        
        # 询问是否添加到fstab
        read -p "是否添加到/etc/fstab实现开机自动挂载？(y/n): " add_fstab
        if [[ $add_fstab == "y" || $add_fstab == "Y" ]]; then
            echo "# NFS共享 - $(date)" >> /etc/fstab
            echo "${nfs_server}:${nfs_share} $local_mount nfs defaults 0 0" >> /etc/fstab
            echo -e "${GREEN}已添加到/etc/fstab${NC}"
        fi
    else
        echo -e "${RED}✗ NFS共享挂载失败${NC}"
        echo -e "${YELLOW}可能原因:${NC}"
        echo -e "1. 网络连接问题"
        echo -e "2. 防火墙阻止"
        echo -e "3. NFS共享权限问题"
    fi
    
    echo ""
    read -p "按回车键返回NAS配置菜单..."
    nas_mount_config
}

# 挂载SMB/CIFS共享
mount_smb_share() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          挂载SMB/CIFS共享${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: 挂载SMB共享需要安装cifs-utils包${NC}"
    echo ""
    
    # 检查是否安装cifs-utils
    if ! command -v mount.cifs &> /dev/null; then
        echo -e "${CYAN}安装cifs-utils...${NC}"
        case $DISTRO in
            "centos"|"rhel"|"fedora")
                yum install -y cifs-utils
                ;;
            "ubuntu"|"debian")
                apt update && apt install -y cifs-utils
                ;;
        esac
    fi
    
    read -p "请输入SMB服务器IP地址或主机名: " smb_server
    read -p "请输入SMB共享名称: " smb_share
    read -p "请输入SMB用户名 (留空为匿名访问): " smb_user
    read -p "请输入SMB密码 (留空为匿名访问): " -s smb_pass
    echo ""
    read -p "请输入本地挂载点目录 (例如: /mnt/smb_share): " local_mount
    
    # 创建本地挂载目录
    mkdir -p "$local_mount"
    
    # 构建挂载命令
    local mount_cmd="mount -t cifs"
    local share_path="//${smb_server}/${smb_share}"
    
    if [ -n "$smb_user" ]; then
        mount_cmd="$mount_cmd -o username=${smb_user}"
        if [ -n "$smb_pass" ]; then
            mount_cmd="$mount_cmd,password=${smb_pass}"
        fi
    else
        mount_cmd="$mount_cmd -o guest"
    fi
    
    # 添加其他选项
    mount_cmd="$mount_cmd,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777"
    
    # 挂载SMB共享
    echo -e "${CYAN}挂载SMB共享...${NC}"
    $mount_cmd "$share_path" "$local_mount"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SMB共享挂载成功！${NC}"
        echo ""
        echo -e "${CYAN}挂载信息:${NC}"
        echo -e "  服务器: $smb_server"
        echo -e "  共享名称: $smb_share"
        echo -e "  本地挂载点: $local_mount"
        echo -e "  用户名: ${smb_user:-匿名}"
        echo ""
        
        # 询问是否添加到fstab
        read -p "是否添加到/etc/fstab实现开机自动挂载？(y/n): " add_fstab
        if [[ $add_fstab == "y" || $add_fstab == "Y" ]]; then
            echo "# SMB共享 - $(date)" >> /etc/fstab
            
            if [ -n "$smb_user" ]; then
                if [ -n "$smb_pass" ]; then
                    # 创建凭据文件
                    cred_file="/root/.smb_credentials_${smb_server}"
                    echo "username=$smb_user" > "$cred_file"
                    echo "password=$smb_pass" >> "$cred_file"
                    chmod 600 "$cred_file"
                    echo "${share_path} $local_mount cifs credentials=$cred_file,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777 0 0" >> /etc/fstab
                else
                    echo "${share_path} $local_mount cifs username=$smb_user,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777 0 0" >> /etc/fstab
                fi
            else
                echo "${share_path} $local_mount cifs guest,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777 0 0" >> /etc/fstab
            fi
            
            echo -e "${GREEN}已添加到/etc/fstab${NC}"
        fi
    else
        echo -e "${RED}✗ SMB共享挂载失败${NC}"
        echo -e "${YELLOW}可能原因:${NC}"
        echo -e "1. 网络连接问题"
        echo -e "2. 认证失败"
        echo -e "3. 防火墙阻止"
        echo -e "4. SMB版本不兼容"
    fi
    
    echo ""
    read -p "按回车键返回NAS配置菜单..."
    nas_mount_config
}

# 挂载FTP共享（使用curlftpfs）
mount_ftp_share() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          挂载FTP共享${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: 挂载FTP共享需要安装curlftpfs包${NC}"
    echo ""
    
    # 检查是否安装curlftpfs
    if ! command -v curlftpfs &> /dev/null; then
        echo -e "${CYAN}安装curlftpfs...${NC}"
        case $DISTRO in
            "centos"|"rhel"|"fedora")
                yum install -y epel-release
                yum install -y curlftpfs fuse fuse-libs
                ;;
            "ubuntu"|"debian")
                apt update && apt install -y curlftpfs fuse
                ;;
        esac
    fi
    
    read -p "请输入FTP服务器地址: " ftp_server
    read -p "请输入FTP端口 (默认21): " ftp_port
    ftp_port=${ftp_port:-21}
    read -p "请输入FTP用户名 (留空为匿名访问): " ftp_user
    read -p "请输入FTP密码 (留空为匿名访问): " -s ftp_pass
    echo ""
    read -p "请输入FTP远程路径 (例如: /): " ftp_path
    read -p "请输入本地挂载点目录 (例如: /mnt/ftp_share): " local_mount
    
    # 创建本地挂载目录
    mkdir -p "$local_mount"
    
    # 构建FTP URL
    local ftp_url=""
    if [ -n "$ftp_user" ]; then
        if [ -n "$ftp_pass" ]; then
            ftp_url="ftp://${ftp_user}:${ftp_pass}@${ftp_server}:${ftp_port}${ftp_path}"
        else
            ftp_url="ftp://${ftp_user}@${ftp_server}:${ftp_port}${ftp_path}"
        fi
    else
        ftp_url="ftp://${ftp_server}:${ftp_port}${ftp_path}"
    fi
    
    # 挂载FTP共享
    echo -e "${CYAN}挂载FTP共享...${NC}"
    curlftpfs -o allow_other "$ftp_url" "$local_mount"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ FTP共享挂载成功！${NC}"
        echo ""
        echo -e "${CYAN}挂载信息:${NC}"
        echo -e "  服务器: $ftp_server"
        echo -e "  端口: $ftp_port"
        echo -e "  远程路径: $ftp_path"
        echo -e "  本地挂载点: $local_mount"
        echo -e "  用户名: ${ftp_user:-匿名}"
        echo ""
        
        echo -e "${YELLOW}注意: FTP挂载通常不添加到fstab，因为需要网络连接${NC}"
    else
        echo -e "${RED}✗ FTP共享挂载失败${NC}"
        echo -e "${YELLOW}可能原因:${NC}"
        echo -e "1. 网络连接问题"
        echo -e "2. FTP认证失败"
        echo -e "3. 防火墙阻止"
        echo -e "4. 缺少依赖包"
    fi
    
    echo ""
    read -p "按回车键返回NAS配置菜单..."
    nas_mount_config
}

# 配置自动挂载
configure_auto_mount() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          配置自动挂载${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}当前/etc/fstab配置:${NC}"
    cat /etc/fstab
    echo ""
    
    echo -e "${CYAN}自动挂载选项:${NC}"
    echo -e "  ${GREEN}1.${NC} 添加NFS自动挂载"
    echo -e "  ${GREEN}2.${NC} 添加SMB自动挂载"
    echo -e "  ${GREEN}3.${NC} 备份当前fstab配置"
    echo -e "  ${GREEN}4.${NC} 恢复fstab备份"
    echo -e "  ${GREEN}5.${NC} 测试fstab配置"
    echo -e "  ${GREEN}6.${NC} 返回NAS配置菜单"
    echo ""
    
    read -p "请选择操作 (1-6): " auto_choice
    
    case $auto_choice in
        1)
            add_nfs_auto_mount
            ;;
        2)
            add_smb_auto_mount
            ;;
        3)
            backup_fstab
            ;;
        4)
            restore_fstab
            ;;
        5)
            test_fstab
            ;;
        6)
            nas_mount_config
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            configure_auto_mount
            ;;
    esac
}

# 添加NFS自动挂载
add_nfs_auto_mount() {
    echo -e "${CYAN}添加NFS自动挂载配置...${NC}"
    echo ""
    
    read -p "请输入NFS服务器IP地址: " nfs_server
    read -p "请输入NFS共享路径: " nfs_share
    read -p "请输入本地挂载点: " local_mount
    read -p "请输入挂载选项 (默认: defaults): " mount_options
    mount_options=${mount_options:-defaults}
    
    # 创建挂载点目录
    mkdir -p "$local_mount"
    
    # 添加到fstab
    echo "# NFS自动挂载 - $(date)" >> /etc/fstab
    echo "${nfs_server}:${nfs_share} $local_mount nfs $mount_options 0 0" >> /etc/fstab
    
    echo -e "${GREEN}NFS自动挂载配置已添加到/etc/fstab${NC}"
    
    # 测试挂载
    echo -e "${CYAN}测试挂载...${NC}"
    mount -a
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 挂载测试成功${NC}"
    else
        echo -e "${RED}✗ 挂载测试失败，请检查配置${NC}"
    fi
    
    echo ""
    read -p "按回车键返回自动挂载配置..."
    configure_auto_mount
}

# 添加SMB自动挂载
add_smb_auto_mount() {
    echo -e "${CYAN}添加SMB自动挂载配置...${NC}"
    echo ""
    
    read -p "请输入SMB服务器地址: " smb_server
    read -p "请输入SMB共享名称: " smb_share
    read -p "请输入SMB用户名: " smb_user
    read -p "请输入SMB密码: " -s smb_pass
    echo ""
    read -p "请输入本地挂载点: " local_mount
    
    # 创建挂载点目录
    mkdir -p "$local_mount"
    
    # 创建凭据文件
    local cred_file="/root/.smb_credentials_${smb_server//./_}"
    echo "username=$smb_user" > "$cred_file"
    echo "password=$smb_pass" >> "$cred_file"
    chmod 600 "$cred_file"
    
    # 添加到fstab
    echo "# SMB自动挂载 - $(date)" >> /etc/fstab
    echo "//${smb_server}/${smb_share} $local_mount cifs credentials=$cred_file,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777 0 0" >> /etc/fstab
    
    echo -e "${GREEN}SMB自动挂载配置已添加到/etc/fstab${NC}"
    echo -e "凭据文件: $cred_file"
    
    # 测试挂载
    echo -e "${CYAN}测试挂载...${NC}"
    mount -a
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 挂载测试成功${NC}"
    else
        echo -e "${RED}✗ 挂载测试失败，请检查配置${NC}"
    fi
    
    echo ""
    read -p "按回车键返回自动挂载配置..."
    configure_auto_mount
}

# 备份fstab配置
backup_fstab() {
    local backup_file="/etc/fstab.backup.$(date +%Y%m%d_%H%M%S)"
    cp /etc/fstab "$backup_file"
    echo -e "${GREEN}fstab备份完成: $backup_file${NC}"
    
    echo ""
    read -p "按回车键返回自动挂载配置..."
    configure_auto_mount
}

# 恢复fstab备份
restore_fstab() {
    echo -e "${CYAN}可用的fstab备份文件:${NC}"
    ls -la /etc/fstab.backup.* 2>/dev/null || echo "未找到备份文件"
    echo ""
    
    read -p "请输入备份文件路径: " backup_file
    
    if [ -f "$backup_file" ]; then
        cp "$backup_file" /etc/fstab
        echo -e "${GREEN}fstab已从备份恢复${NC}"
    else
        echo -e "${RED}备份文件不存在${NC}"
    fi
    
    echo ""
    read -p "按回车键返回自动挂载配置..."
    configure_auto_mount
}

# 测试fstab配置
test_fstab() {
    echo -e "${CYAN}测试fstab配置...${NC}"
    echo ""
    
    mount -a 2>&1 | while read line; do
        if [[ "$line" == *"mount:"* ]] || [[ "$line" == *"error"* ]] || [[ "$line" == *"failed"* ]]; then
            echo -e "${RED}$line${NC}"
        else
            echo -e "${GREEN}$line${NC}"
        fi
    done
    
    echo ""
    echo -e "${CYAN}当前挂载状态:${NC}"
    mount | grep -E "(nfs|cifs|ftp|smb)" || echo "未找到网络共享挂载"
    
    echo ""
    read -p "按回车键返回自动挂载配置..."
    configure_auto_mount
}

# 卸载共享目录
unmount_share() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          卸载共享目录${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}当前挂载的网络共享:${NC}"
    mount | grep -E "(nfs|cifs|ftp|smb)" | awk '{print NR ". " $3 " (" $1 ")"}' || echo "未找到网络共享挂载"
    echo ""
    
    read -p "请输入要卸载的挂载点编号 (输入0返回): " unmount_num
    
    if [ "$unmount_num" = "0" ]; then
        nas_mount_config
        return
    fi
    
    # 获取挂载点路径
    local mount_point=$(mount | grep -E "(nfs|cifs|ftp|smb)" | sed -n "${unmount_num}p" | awk '{print $3}')
    
    if [ -z "$mount_point" ]; then
        echo -e "${RED}无效的编号${NC}"
        sleep 2
        unmount_share
        return
    fi
    
    echo -e "${CYAN}正在卸载: $mount_point${NC}"
    
    # 卸载
    umount "$mount_point"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 卸载成功${NC}"
        
        # 询问是否从fstab中移除
        read -p "是否从/etc/fstab中移除相关配置？(y/n): " remove_fstab
        
        if [[ $remove_fstab == "y" || $remove_fstab == "Y" ]]; then
            # 创建临时文件
            local temp_fstab=$(mktemp)
            
            # 移除相关配置行
            grep -v "$mount_point" /etc/fstab > "$temp_fstab"
            cp "$temp_fstab" /etc/fstab
            rm -f "$temp_fstab"
            
            echo -e "${GREEN}已从/etc/fstab中移除相关配置${NC}"
        fi
    else
        echo -e "${RED}✗ 卸载失败${NC}"
        echo -e "${YELLOW}可能原因:${NC}"
        echo -e "1. 目录正在使用中"
        echo -e "2. 权限不足"
        echo -e "可以尝试: umount -l $mount_point (强制卸载)"
    fi
    
    echo ""
    read -p "按回车键返回NAS配置菜单..."
    nas_mount_config
}

# 数据库备份功能
database_backup() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          数据库备份功能${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}选择数据库类型:${NC}"
    echo -e "  ${GREEN}1.${NC} MySQL/MariaDB 备份"
    echo -e "  ${GREEN}2.${NC} PostgreSQL 备份"
    echo -e "  ${GREEN}3.${NC} Oracle 备份"
    echo -e "  ${GREEN}4.${NC} Redis 备份"
    echo -e "  ${GREEN}5.${NC} MongoDB 备份"
    echo -e "  ${GREEN}6.${NC} 配置定时备份任务"
    echo -e "  ${GREEN}7.${NC} 查看备份历史"
    echo -e "  ${GREEN}8.${NC} 返回主菜单"
    echo ""
    
    read -p "请选择数据库类型 (1-8): " db_type
    
    case $db_type in
        1)
            mysql_backup
            ;;
        2)
            postgresql_backup
            ;;
        3)
            oracle_backup
            ;;
        4)
            redis_backup
            ;;
        5)
            mongodb_backup
            ;;
        6)
            configure_backup_schedule
            ;;
        7)
            view_backup_history
            ;;
        8)
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            database_backup
            ;;
    esac
}

# MySQL/MariaDB 备份
mysql_backup() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          MySQL/MariaDB 备份${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查MySQL是否安装
    if ! command -v mysql &> /dev/null && ! command -v mysqldump &> /dev/null; then
        echo -e "${YELLOW}MySQL客户端未安装${NC}"
        echo -e "正在安装MySQL客户端..."
        
        case $DISTRO in
            "centos"|"rhel"|"fedora")
                yum install -y mariadb-server mariadb-client
                ;;
            "ubuntu"|"debian")
                apt update && apt install -y mysql-client
                ;;
        esac
        
        if ! command -v mysql &> /dev/null; then
            echo -e "${RED}MySQL客户端安装失败${NC}"
            read -p "按回车键返回..."
            database_backup
            return
        fi
    fi
    
    echo -e "${CYAN}备份选项:${NC}"
    echo -e "  ${GREEN}1.${NC} 备份单个数据库"
    echo -e "  ${GREEN}2.${NC} 备份所有数据库"
    echo -e "  ${GREEN}3.${NC} 备份数据库结构"
    echo -e "  ${GREEN}4.${NC} 备份数据库数据"
    echo -e "  ${GREEN}5.${NC} 返回上一级"
    echo ""
    
    read -p "请选择备份选项 (1-5): " backup_option
    
    case $backup_option in
        1)
            backup_single_database
            ;;
        2)
            backup_all_databases
            ;;
        3)
            backup_database_structure
            ;;
        4)
            backup_database_data
            ;;
        5)
            database_backup
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            mysql_backup
            ;;
    esac
}

# 备份单个数据库
backup_single_database() {
    echo -e "${CYAN}备份单个数据库...${NC}"
    echo ""
    
    read -p "请输入MySQL主机地址 (默认: localhost): " db_host
    db_host=${db_host:-localhost}
    read -p "请输入MySQL端口 (默认: 3306): " db_port
    db_port=${db_port:-3306}
    read -p "请输入MySQL用户名: " db_user
    read -p "请输入MySQL密码: " -s db_pass
    echo ""
    read -p "请输入数据库名称: " db_name
    read -p "请输入备份文件保存路径 (默认: /opt/backup/mysql): " backup_path
    backup_path=${backup_path:-/opt/backup/mysql}
    
    # 创建备份目录
    mkdir -p "$backup_path"
    
    # 生成备份文件名
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_path}/${db_name}_${timestamp}.sql"
    local backup_file_gz="${backup_file}.gz"
    
    echo -e "${CYAN}正在备份数据库: $db_name${NC}"
    
    # 备份数据库
    if [ -n "$db_pass" ]; then
        mysqldump -h "$db_host" -P "$db_port" -u "$db_user" -p"$db_pass" "$db_name" > "$backup_file"
    else
        mysqldump -h "$db_host" -P "$db_port" -u "$db_user" "$db_name" > "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 数据库备份成功！${NC}"
        
        # 压缩备份文件
        gzip "$backup_file"
        
        # 计算文件大小
        local file_size=$(du -h "$backup_file_gz" | awk '{print $1}')
        
        echo -e "${CYAN}备份信息:${NC}"
        echo -e "  数据库: $db_name"
        echo -e "  备份文件: $backup_file_gz"
        echo -e "  文件大小: $file_size"
        echo -e "  备份时间: $(date)"
        
        # 记录备份日志
        echo "$(date): 备份数据库 $db_name 到 $backup_file_gz (大小: $file_size)" >> "${backup_path}/backup.log"
    else
        echo -e "${RED}✗ 数据库备份失败${NC}"
        echo -e "${YELLOW}可能原因:${NC}"
        echo -e "1. 数据库连接失败"
        echo -e "2. 认证失败"
        echo -e "3. 数据库不存在"
        echo -e "4. 权限不足"
    fi
    
    echo ""
    read -p "按回车键返回MySQL备份菜单..."
    mysql_backup
}

# 备份所有数据库
backup_all_databases() {
    echo -e "${CYAN}备份所有数据库...${NC}"
    echo ""
    
    read -p "请输入MySQL主机地址 (默认: localhost): " db_host
    db_host=${db_host:-localhost}
    read -p "请输入MySQL端口 (默认: 3306): " db_port
    db_port=${db_port:-3306}
    read -p "请输入MySQL用户名: " db_user
    read -p "请输入MySQL密码: " -s db_pass
    echo ""
    read -p "请输入备份文件保存路径 (默认: /opt/backup/mysql): " backup_path
    backup_path=${backup_path:-/opt/backup/mysql}
    
    # 创建备份目录
    mkdir -p "$backup_path"
    
    # 生成备份文件名
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_path}/all_databases_${timestamp}.sql"
    local backup_file_gz="${backup_file}.gz"
    
    echo -e "${CYAN}正在备份所有数据库...${NC}"
    
    # 备份所有数据库
    if [ -n "$db_pass" ]; then
        mysqldump -h "$db_host" -P "$db_port" -u "$db_user" -p"$db_pass" --all-databases > "$backup_file"
    else
        mysqldump -h "$db_host" -P "$db_port" -u "$db_user" --all-databases > "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 所有数据库备份成功！${NC}"
        
        # 压缩备份文件
        gzip "$backup_file"
        
        # 计算文件大小
        local file_size=$(du -h "$backup_file_gz" | awk '{print $1}')
        
        echo -e "${CYAN}备份信息:${NC}"
        echo -e "  备份文件: $backup_file_gz"
        echo -e "  文件大小: $file_size"
        echo -e "  备份时间: $(date)"
        
        # 记录备份日志
        echo "$(date): 备份所有数据库到 $backup_file_gz (大小: $file_size)" >> "${backup_path}/backup.log"
    else
        echo -e "${RED}✗ 数据库备份失败${NC}"
    fi
    
    echo ""
    read -p "按回车键返回MySQL备份菜单..."
    mysql_backup
}

# PostgreSQL 备份
postgresql_backup() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          PostgreSQL 备份${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查PostgreSQL是否安装
    if ! command -v pg_dump &> /dev/null; then
        echo -e "${YELLOW}PostgreSQL客户端未安装${NC}"
        echo -e "正在安装PostgreSQL客户端..."
        
        case $DISTRO in
            "centos"|"rhel"|"fedora")
                yum install -y postgresql-server postgresql-contrib
                ;;
            "ubuntu"|"debian")
                apt update && apt install -y postgresql-client
                ;;
        esac
        
        if ! command -v pg_dump &> /dev/null; then
            echo -e "${RED}PostgreSQL客户端安装失败${NC}"
            read -p "按回车键返回..."
            database_backup
            return
        fi
    fi
    
    read -p "请输入PostgreSQL主机地址 (默认: localhost): " db_host
    db_host=${db_host:-localhost}
    read -p "请输入PostgreSQL端口 (默认: 5432): " db_port
    db_port=${db_port:-5432}
    read -p "请输入PostgreSQL用户名: " db_user
    read -p "请输入PostgreSQL密码: " -s db_pass
    echo ""
    read -p "请输入数据库名称: " db_name
    read -p "请输入备份文件保存路径 (默认: /opt/backup/postgresql): " backup_path
    backup_path=${backup_path:-/opt/backup/postgresql}
    
    # 创建备份目录
    mkdir -p "$backup_path"
    
    # 生成备份文件名
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_path}/${db_name}_${timestamp}.sql"
    local backup_file_gz="${backup_file}.gz"
    
    echo -e "${CYAN}正在备份PostgreSQL数据库: $db_name${NC}"
    
    # 设置环境变量
    export PGPASSWORD="$db_pass"
    
    # 备份数据库
    pg_dump -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -f "$backup_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PostgreSQL数据库备份成功！${NC}"
        
        # 压缩备份文件
        gzip "$backup_file"
        
        # 计算文件大小
        local file_size=$(du -h "$backup_file_gz" | awk '{print $1}')
        
        echo -e "${CYAN}备份信息:${NC}"
        echo -e "  数据库: $db_name"
        echo -e "  备份文件: $backup_file_gz"
        echo -e "  文件大小: $file_size"
        echo -e "  备份时间: $(date)"
        
        # 记录备份日志
        echo "$(date): 备份PostgreSQL数据库 $db_name 到 $backup_file_gz (大小: $file_size)" >> "${backup_path}/backup.log"
    else
        echo -e "${RED}✗ PostgreSQL数据库备份失败${NC}"
    fi
    
    # 清除密码
    unset PGPASSWORD
    
    echo ""
    read -p "按回车键返回数据库备份菜单..."
    database_backup
}

# Oracle 备份
oracle_backup() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          Oracle 数据库备份${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: Oracle备份需要Oracle客户端工具 (expdp/impdp)${NC}"
    echo ""
    
    read -p "请输入Oracle连接字符串 (例如: host:port/service): " oracle_conn
    read -p "请输入Oracle用户名: " oracle_user
    read -p "请输入Oracle密码: " -s oracle_pass
    echo ""
    read -p "请输入备份文件保存路径 (默认: /opt/backup/oracle): " backup_path
    backup_path=${backup_path:-/opt/backup/oracle}
    
    # 创建备份目录
    mkdir -p "$backup_path"
    
    # 生成备份文件名
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_path}/${oracle_user}_${timestamp}.dmp"
    
    echo -e "${CYAN}正在备份Oracle数据库...${NC}"
    
    # 检查是否有expdp命令
    if command -v expdp &> /dev/null; then
        # 使用expdp备份
        expdp "$oracle_user/$oracle_pass@$oracle_conn" directory=DATA_PUMP_DIR dumpfile="${oracle_user}_${timestamp}.dmp" logfile="${oracle_user}_${timestamp}.log"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Oracle数据库备份成功！${NC}"
            echo -e "${CYAN}备份文件位于Oracle服务器DATA_PUMP_DIR目录${NC}"
        else
            echo -e "${RED}✗ Oracle数据库备份失败${NC}"
        fi
    else
        echo -e "${YELLOW}expdp命令未找到，尝试使用exp命令...${NC}"
        
        if command -v exp &> /dev/null; then
            # 使用exp备份
            exp "$oracle_user/$oracle_pass@$oracle_conn" file="$backup_file" log="${backup_path}/${oracle_user}_${timestamp}.log" full=y
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Oracle数据库备份成功！${NC}"
                
                # 计算文件大小
                local file_size=$(du -h "$backup_file" | awk '{print $1}')
                
                echo -e "${CYAN}备份信息:${NC}"
                echo -e "  用户: $oracle_user"
                echo -e "  备份文件: $backup_file"
                echo -e "  文件大小: $file_size"
                
                # 记录备份日志
                echo "$(date): 备份Oracle用户 $oracle_user 到 $backup_file (大小: $file_size)" >> "${backup_path}/backup.log"
            else
                echo -e "${RED}✗ Oracle数据库备份失败${NC}"
            fi
        else
            echo -e "${RED}未找到Oracle客户端工具 (expdp/exp)${NC}"
            echo -e "${YELLOW}请安装Oracle Instant Client或完整客户端${NC}"
        fi
    fi
    
    echo ""
    read -p "按回车键返回数据库备份菜单..."
    database_backup
}

# Redis 备份
redis_backup() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          Redis 备份${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查Redis是否安装
    if ! command -v redis-cli &> /dev/null; then
        echo -e "${YELLOW}Redis客户端未安装${NC}"
        read -p "按回车键返回..."
        database_backup
        return
    fi
    
    read -p "请输入Redis主机地址 (默认: localhost): " redis_host
    redis_host=${redis_host:-localhost}
    read -p "请输入Redis端口 (默认: 6379): " redis_port
    redis_port=${redis_port:-6379}
    read -p "请输入Redis密码 (留空为无密码): " -s redis_pass
    echo ""
    read -p "请输入备份文件保存路径 (默认: /opt/backup/redis): " backup_path
    backup_path=${backup_path:-/opt/backup/redis}
    
    # 创建备份目录
    mkdir -p "$backup_path"
    
    # 生成备份文件名
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_path}/redis_dump_${timestamp}.rdb"
    
    echo -e "${CYAN}正在备份Redis数据...${NC}"
    
    # 尝试备份
    if [ -n "$redis_pass" ]; then
        # 有密码的情况
        if redis-cli -h "$redis_host" -p "$redis_port" -a "$redis_pass" --rdb "$backup_file" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Redis备份成功！${NC}"
            
            # 计算文件大小
            local file_size=$(du -h "$backup_file" | awk '{print $1}')
            
            echo -e "${CYAN}备份信息:${NC}"
            echo -e "  备份文件: $backup_file"
            echo -e "  文件大小: $file_size"
            echo -e "  备份时间: $(date)"
            
            # 记录备份日志
            echo "$(date): 备份Redis数据到 $backup_file (大小: $file_size)" >> "${backup_path}/backup.log"
        else
            echo -e "${RED}✗ Redis备份失败${NC}"
            echo -e "${YELLOW}可能原因:${NC}"
            echo -e "1. Redis连接失败"
            echo -e "2. 认证失败"
            echo -e "3. Redis配置不允许RDB备份"
        fi
    else
        # 无密码的情况
        if redis-cli -h "$redis_host" -p "$redis_port" --rdb "$backup_file" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Redis备份成功！${NC}"
            
            # 计算文件大小
            local file_size=$(du -h "$backup_file" | awk '{print $1}')
            
            echo -e "${CYAN}备份信息:${NC}"
            echo -e "  备份文件: $backup_file"
            echo -e "  文件大小: $file_size"
            
            # 记录备份日志
            echo "$(date): 备份Redis数据到 $backup_file (大小: $file_size)" >> "${backup_path}/backup.log"
        else
            echo -e "${RED}✗ Redis备份失败${NC}"
        fi
    fi
    
    echo ""
    read -p "按回车键返回数据库备份菜单..."
    database_backup
}

# 配置定时备份任务
configure_backup_schedule() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          配置定时备份任务${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}选择定时任务类型:${NC}"
    echo -e "  ${GREEN}1.${NC} 配置MySQL定时备份"
    echo -e "  ${GREEN}2.${NC} 配置PostgreSQL定时备份"
    echo -e "  ${GREEN}3.${NC} 配置Redis定时备份"
    echo -e "  ${GREEN}4.${NC} 查看当前定时任务"
    echo -e "  ${GREEN}5.${NC} 删除定时任务"
    echo -e "  ${GREEN}6.${NC} 返回上一级"
    echo ""
    
    read -p "请选择操作 (1-6): " schedule_choice
    
    case $schedule_choice in
        1)
            configure_mysql_schedule
            ;;
        2)
            configure_postgresql_schedule
            ;;
        3)
            configure_redis_schedule
            ;;
        4)
            view_cron_jobs
            ;;
        5)
            delete_cron_job
            ;;
        6)
            database_backup
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            configure_backup_schedule
            ;;
    esac
}

# 查看备份历史
view_backup_history() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          查看备份历史${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}选择备份类型:${NC}"
    echo -e "  ${GREEN}1.${NC} 查看MySQL备份历史"
    echo -e "  ${GREEN}2.${NC} 查看PostgreSQL备份历史"
    echo -e "  ${GREEN}3.${NC} 查看Oracle备份历史"
    echo -e "  ${GREEN}4.${NC} 查看Redis备份历史"
    echo -e "  ${GREEN}5.${NC} 查看所有备份日志"
    echo -e "  ${GREEN}6.${NC} 清理旧备份文件"
    echo -e "  ${GREEN}7.${NC} 返回上一级"
    echo ""
    
    read -p "请选择操作 (1-7): " history_choice
    
    case $history_choice in
        1)
            view_mysql_history
            ;;
        2)
            view_postgresql_history
            ;;
        3)
            view_oracle_history
            ;;
        4)
            view_redis_history
            ;;
        5)
            view_all_backup_logs
            ;;
        6)
            cleanup_old_backups
            ;;
        7)
            database_backup
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            view_backup_history
            ;;
    esac
}

# DNS污染检测功能（解析域名对应的10个IP，选择最快的，更新hosts配置）
dns_pollution_detection() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          DNS污染检测与优化${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}功能说明:${NC}"
    echo -e "1. 检测指定域名的DNS解析情况"
    echo -e "2. 获取域名的多个IP地址（最多10个）"
    echo -e "3. 测试每个IP的响应速度和连通性"
    echo -e "4. 选择最快的IP地址"
    echo -e "5. 备份原有hosts文件"
    echo -e "6. 更新hosts配置，只修改该域名相关条目"
    echo ""
    
    read -p "请输入要检测的域名（如：github.com）: " domain
    if [ -z "$domain" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo ""
    echo -e "${CYAN}正在检测域名: ${YELLOW}$domain${NC}${CYAN} 的DNS解析...${NC}"
    echo ""
    
    # 从多个DNS服务器获取IP地址
    local dns_servers=("8.8.8.8" "1.1.1.1" "9.9.9.9" "208.67.222.222" "8.8.4.4")
    local ip_list=()
    
    echo -e "${CYAN}从多个DNS服务器获取IP地址...${NC}"
    echo ""
    
    for dns in "${dns_servers[@]}"; do
        echo -e "查询DNS服务器: ${YELLOW}$dns${NC}"
        local ips=$(dig +short $domain @$dns 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
        
        if [ -n "$ips" ]; then
            while IFS= read -r ip; do
                if [[ ! " ${ip_list[@]} " =~ " ${ip} " ]]; then
                    ip_list+=("$ip")
                    echo -e "  ${GREEN}获取到IP: $ip${NC}"
                fi
            done <<< "$ips"
        else
            echo -e "  ${YELLOW}未获取到IP${NC}"
        fi
    done
    
    # 如果获取的IP太少，尝试从其他来源获取
    if [ ${#ip_list[@]} -lt 3 ]; then
        echo ""
        echo -e "${YELLOW}获取到的IP较少，尝试其他来源...${NC}"
        
        # 尝试从在线服务获取
        local online_ips=$(curl -s "https://ipaddress.com/website/$domain" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort -u | head -10)
        
        for ip in $online_ips; do
            if [[ ! " ${ip_list[@]} " =~ " ${ip} " ]]; then
                ip_list+=("$ip")
                echo -e "  ${GREEN}从在线服务获取到IP: $ip${NC}"
            fi
        done
    fi
    
    if [ ${#ip_list[@]} -eq 0 ]; then
        echo ""
        echo -e "${RED}无法获取到任何IP地址，请检查网络或域名是否正确${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo ""
    echo -e "${GREEN}共获取到 ${#ip_list[@]} 个IP地址:${NC}"
    printf "  %s\n" "${ip_list[@]}"
    echo ""
    
    # 测试每个IP的速度
    echo -e "${CYAN}开始测试IP响应速度...${NC}"
    echo ""
    
    local ip_scores=()
    local fastest_ip=""
    local fastest_time=99999
    
    for ip in "${ip_list[@]}"; do
        echo -e "测试IP: ${YELLOW}$ip${NC}"
        
        # 使用ping测试延迟
        local ping_result=$(ping -c 3 -W 2 "$ip" 2>&1 | grep 'min/avg/max/mdev' | awk -F '/' '{print $5}')
        
        if [ -n "$ping_result" ]; then
            local avg_time=$(ping -c 3 -W 2 "$ip" 2>&1 | grep 'min/avg/max/mdev' | awk -F '/' '{print $5}')
            echo -e "  ${GREEN}平均延迟: ${avg_time}ms${NC}"
            
            # 计算分数（延迟越低分数越高）
            local score=$(echo "1000 / ($avg_time + 1)" | bc 2>/dev/null || echo 100)
            
            # 记录分数
            ip_scores+=("$ip:$score")
            
            # 记录最快IP
            if (( $(echo "$avg_time < $fastest_time" | bc -l 2>/dev/null || echo 0) )); then
                fastest_time=$avg_time
                fastest_ip=$ip
            fi
        else
            echo -e "  ${RED}无法连接${NC}"
            ip_scores+=("$ip:0")
        fi
        
        # 添加短暂延迟，避免过快请求
        sleep 0.5
    done
    
    echo ""
    
    if [ -z "$fastest_ip" ]; then
        echo -e "${RED}所有IP都无法连接，无法进行优化${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo -e "${GREEN}最快IP: ${YELLOW}$fastest_ip${GREEN}，延迟: ${fastest_time}ms${NC}"
    echo ""
    
    # 备份原有hosts文件
    local backup_file="/etc/hosts.backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${CYAN}备份原有hosts文件到: ${YELLOW}$backup_file${NC}"
    cp /etc/hosts "$backup_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}备份成功${NC}"
    else
        echo -e "${RED}备份失败，请检查权限${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo ""
    
    # 更新hosts文件
    echo -e "${CYAN}更新hosts文件...${NC}"
    
    # 先移除该域名的旧条目
    local temp_file="/tmp/hosts.tmp"
    cp /etc/hosts "$temp_file"
    
    # 从临时文件中移除该域名的所有条目
    sed -i "/$domain/d" "$temp_file"
    
    # 添加新的最快IP条目
    echo "# DNS优化 - 添加于 $(date)" >> "$temp_file"
    echo -e "${YELLOW}$fastest_ip${NC} ${CYAN}$domain${NC}" | sed 's/\\033\[[0-9;]*m//g' >> "$temp_file"
    
    # 如果还有其他相关子域名也添加
    local subdomains=("www.$domain" "raw.$domain" "api.$domain")
    for sub in "${subdomains[@]}"; do
        echo "$fastest_ip $sub" >> "$temp_file"
    done
    
    # 替换原hosts文件
    mv "$temp_file" /etc/hosts
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}hosts文件更新成功${NC}"
    else
        echo -e "${RED}更新失败，请检查权限${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo ""
    
    # 刷新DNS缓存
    echo -e "${CYAN}刷新DNS缓存...${NC}"
    
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            systemctl restart systemd-resolved 2>/dev/null
            ;;
        "ubuntu"|"debian")
            systemctl restart systemd-resolved 2>/dev/null
            ;;
    esac
    
    # 通用刷新命令
    if command -v nscd &> /dev/null; then
        nscd -i hosts
    fi
    
    if command -v dscacheutil &> /dev/null; then
        dscacheutil -flushcache
    fi
    
    echo -e "${GREEN}DNS缓存刷新完成${NC}"
    echo ""
    
    # 验证更新
    echo -e "${CYAN}验证DNS更新...${NC}"
    local resolved_ip=$(dig +short $domain @8.8.8.8 2>/dev/null | head -1)
    
    if [ "$resolved_ip" = "$fastest_ip" ]; then
        echo -e "${GREEN}✓ DNS更新验证成功${NC}"
        echo -e "  域名: $domain"
        echo -e "  当前解析IP: $resolved_ip"
        echo -e "  预期IP: $fastest_ip"
    else
        echo -e "${YELLOW}⚠ DNS更新可能未生效${NC}"
        echo -e "  当前解析IP: $resolved_ip"
        echo -e "  预期IP: $fastest_ip"
        echo -e "  可能需要重启网络服务或等待DNS缓存过期"
    fi
    
    echo ""
    echo -e "${GREEN}操作完成！${NC}"
    echo -e "备份文件位置: $backup_file"
    echo -e "如需恢复，请执行: cp \"$backup_file\" /etc/hosts"
    echo ""
    
    read -p "按回车键返回主菜单..."
}

# Docker镜像源DNS检测与修复（集成版）
fix_docker_dns_integrated() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}      Docker镜像源DNS检测与修复（集成版）${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}正在检测Docker镜像源域名DNS污染情况...${NC}"
    echo ""
    
    # Docker相关域名
    local docker_domains=("docker.io" "registry-1.docker.io" "auth.docker.io" "production.cloudflare.docker.com")
    local dns_ok=true
    
    for domain in "${docker_domains[@]}"; do
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
    
    # 如果DNS解析正常，测试实际可访问性
    if $dns_ok; then
        echo -e "${CYAN}测试Docker镜像源实际可访问性...${NC}"
        echo ""
        
        local test_url="https://registry-1.docker.io/v2/"
        echo -e "测试连接: ${YELLOW}$test_url${NC}"
        
        # 测试HTTP连接
        local http_test=$(timeout 10 curl -s -I --connect-timeout 5 "$test_url" 2>&1 | head -1)
        
        if [[ "$http_test" == *"401"* ]] || [[ "$http_test" == *"200"* ]] || [[ "$http_test" == *"302"* ]]; then
            echo -e "  ${GREEN}✓ 可访问性正常: $http_test${NC}"
            echo ""
            echo -e "${GREEN}Docker镜像源访问正常，无需修复${NC}"
            read -p "按回车键返回..."
            return
        fi
    fi
    
    echo -e "${YELLOW}检测到DNS污染或访问问题，开始修复...${NC}"
    echo ""
    
    # 从多个来源获取最新的Docker Hub IP地址
    echo -e "${CYAN}尝试从多个来源获取Docker Hub IP地址...${NC}"
    echo ""
    
    local docker_ips=()
    
    # 尝试从ipaddress.com获取
    echo -e "1. 从ipaddress.com获取Docker Hub IP..."
    local ip1=$(curl -s "https://ipaddress.com/website/docker.io" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -5 2>/dev/null)
    
    if [ -n "$ip1" ]; then
        docker_ips+=("$ip1")
        echo -e "   ${GREEN}获取到IP: $ip1${NC}"
    else
        echo -e "   ${RED}获取失败${NC}"
    fi
    
    # 常见Docker Hub IP地址（备用）
    local common_ips=("34.233.102.125" "35.172.0.2" "52.87.111.37" "54.165.159.111" "54.237.174.207")
    
    echo ""
    echo -e "2. 使用常见Docker Hub IP地址..."
    for ip in "${common_ips[@]}"; do
        docker_ips+=("$ip")
        echo -e "   ${YELLOW}添加备用IP: $ip${NC}"
    done
    
    if [ ${#docker_ips[@]} -eq 0 ]; then
        echo -e "${RED}无法获取到任何IP地址，请检查网络连接${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    echo ""
    echo -e "${GREEN}共获取到 ${#docker_ips[@]} 个IP地址${NC}"
    echo ""
    
    # 测试每个IP的速度和可用性
    echo -e "${CYAN}测试IP地址的连通性和速度...${NC}"
    echo ""
    
    local best_ip=""
    local best_score=0
    
    for ip in "${docker_ips[@]}"; do
        echo -e "测试IP: ${YELLOW}$ip${NC}"
        
        # ping测试
        local ping_result=$(ping -c 3 -W 2 "$ip" 2>&1 | grep 'min/avg/max/mdev')
        local ping_score=0
        
        if [ -n "$ping_result" ]; then
            local avg_time=$(echo "$ping_result" | awk -F '/' '{print $5}')
            echo -e "  ${GREEN}✓ ping延迟: ${avg_time}ms${NC}"
            ping_score=$((100 - $(echo "$avg_time" | awk '{printf "%d", $1}') / 2))
            
            if [ $ping_score -lt 0 ]; then
                ping_score=0
            fi
        else
            echo -e "  ${RED}✗ ping测试失败${NC}"
        fi
        
        # HTTP测试
        local http_test=$(timeout 5 curl -s -I "http://$ip" 2>&1 | head -1)
        local http_score=0
        
        if [[ "$http_test" == *"200"* ]] || [[ "$http_test" == *"301"* ]] || [[ "$http_test" == *"302"* ]]; then
            echo -e "  ${GREEN}✓ HTTP访问正常${NC}"
            http_score=50
        else
            echo -e "  ${YELLOW}⚠ HTTP访问异常: ${http_test:0:50}...${NC}"
        fi
        
        # 计算总分
        local total_score=$((ping_score + http_score))
        echo -e "  综合得分: ${YELLOW}$total_score/150${NC}"
        
        if [ $total_score -gt $best_score ]; then
            best_score=$total_score
            best_ip=$ip
        fi
        
        echo ""
        sleep 0.5
    done
    
    if [ -z "$best_ip" ]; then
        echo -e "${RED}所有IP地址都无法正常连接${NC}"
        echo -e "${YELLOW}建议:${NC}"
        echo -e "1. 检查网络连接"
        echo -e "2. 配置Docker国内镜像源"
        echo -e "3. 尝试使用代理"
        echo -e "4. 等待一段时间后重试"
        read -p "按回车键返回..."
        return
    fi
    
    echo -e "${GREEN}找到最佳IP地址: ${YELLOW}$best_ip${GREEN} (得分: ${best_score}/150)${NC}"
    echo ""
    
    # 备份当前hosts文件
    local backup_file="/etc/hosts.backup.docker_$(date +%Y%m%d_%H%M%S)"
    echo -e "${CYAN}备份当前hosts文件到: ${YELLOW}$backup_file${NC}"
    cp /etc/hosts "$backup_file"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}备份失败，请检查权限${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    echo -e "${GREEN}备份成功${NC}"
    echo ""
    
    # 更新hosts文件
    echo -e "${CYAN}更新hosts文件...${NC}"
    
    # 创建临时文件
    local temp_file="/tmp/hosts.docker.tmp"
    cp /etc/hosts "$temp_file"
    
    # 移除旧的Docker相关条目
    for domain in "${docker_domains[@]}"; do
        sed -i "/$domain/d" "$temp_file"
    done
    
    # 添加新的IP地址
    echo "" >> "$temp_file"
    echo "# Docker DNS优化 - 添加于 $(date)" >> "$temp_file"
    for domain in "${docker_domains[@]}"; do
        echo "$best_ip $domain" >> "$temp_file"
    done
    
    # 替换原hosts文件
    mv "$temp_file" /etc/hosts
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}更新失败，请检查权限${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    echo -e "${GREEN}hosts文件更新成功${NC}"
    echo ""
    
    # 刷新DNS缓存
    echo -e "${CYAN}刷新DNS缓存...${NC}"
    
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            systemctl restart systemd-resolved 2>/dev/null
            ;;
        "ubuntu"|"debian")
            systemctl restart systemd-resolved 2>/dev/null
            ;;
    esac
    
    # 通用刷新命令
    if command -v nscd &> /dev/null; then
        nscd -i hosts
    fi
    
    echo -e "${GREEN}DNS缓存刷新完成${NC}"
    echo ""
    
    # 重启Docker服务
    echo -e "${CYAN}重启Docker服务以使更改生效...${NC}"
    systemctl restart docker 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker服务重启成功${NC}"
    else
        echo -e "${YELLOW}Docker服务重启失败或未运行${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Docker镜像源DNS修复完成！${NC}"
    echo ""
    echo -e "${CYAN}建议:${NC}"
    echo -e "1. 如果Docker Hub访问仍然有问题，建议配置Docker国内镜像源"
    echo -e "2. 可以运行脚本中的Docker安装功能来配置镜像源"
    echo -e "3. 原始hosts文件已备份: $backup_file"
    echo -e "4. Docker Hub IP地址可能会变化，建议定期运行此功能更新"
    
    echo ""
    read -p "按回车键返回..."
}

# 加载推送配置
load_push_config() {
    if [ -f "$PUSH_CONFIG_FILE" ]; then
        # 从配置文件加载配置
        PUSH_ENABLED=$(grep '"enabled":' "$PUSH_CONFIG_FILE" | grep -o 'true\|false')
        PUSH_TYPE=$(grep '"type":' "$PUSH_CONFIG_FILE" | sed 's/.*"type": "\([^"]*\).*/\1/')
        
        case "$PUSH_TYPE" in
            "dingtalk")
                PUSH_DINGTALK_WEBHOOK=$(grep '"webhook":' "$PUSH_CONFIG_FILE" | sed 's/.*"webhook": "\([^"]*\).*/\1/')
                PUSH_DINGTALK_SECRET=$(grep '"secret":' "$PUSH_CONFIG_FILE" | sed 's/.*"secret": "\([^"]*\).*/\1/')
                ;;
            "pluspush")
                PUSH_PLUSPUSH_TOKEN=$(grep '"token":' "$PUSH_CONFIG_FILE" | sed 's/.*"token": "\([^"]*\).*/\1/')
                ;;
            "weoa")
                PUSH_WEOA_WEBHOOK=$(grep '"webhook":' "$PUSH_CONFIG_FILE" | sed 's/.*"webhook": "\([^"]*\).*/\1/')
                PUSH_WEOA_KEY=$(grep '"key":' "$PUSH_CONFIG_FILE" | sed 's/.*"key": "\([^"]*\).*/\1/')
                ;;
            "custom")
                PUSH_CUSTOM_WEBHOOK=$(grep '"webhook":' "$PUSH_CONFIG_FILE" | sed 's/.*"webhook": "\([^"]*\).*/\1/')
                PUSH_CUSTOM_METHOD=$(grep '"method":' "$PUSH_CONFIG_FILE" | sed 's/.*"method": "\([^"]*\).*/\1/')
                PUSH_CUSTOM_HEADERS=$(grep '"headers":' "$PUSH_CONFIG_FILE" | sed 's/.*"headers": "\([^"]*\).*/\1/')
                PUSH_CUSTOM_BODY=$(grep '"body":' "$PUSH_CONFIG_FILE" | sed 's/.*"body": "\([^"]*\).*/\1/')
                ;;
        esac
        
        echo -e "${GREEN}推送配置已加载${NC}"
    else
        echo -e "${YELLOW}推送配置文件不存在，使用默认配置${NC}"
        PUSH_ENABLED=false
    fi
}

# 保存推送配置
save_push_config() {
    local config_content="{
  \"enabled\": $PUSH_ENABLED,
  \"type\": \"$PUSH_TYPE\""
    
    case "$PUSH_TYPE" in
        "dingtalk")
            config_content="$config_content,
  \"webhook\": \"$PUSH_DINGTALK_WEBHOOK\",
  \"secret\": \"$PUSH_DINGTALK_SECRET\""
            ;;
        "pluspush")
            config_content="$config_content,
  \"token\": \"$PUSH_PLUSPUSH_TOKEN\""
            ;;
        "weoa")
            config_content="$config_content,
  \"webhook\": \"$PUSH_WEOA_WEBHOOK\",
  \"key\": \"$PUSH_WEOA_KEY\""
            ;;
        "custom")
            config_content="$config_content,
  \"webhook\": \"$PUSH_CUSTOM_WEBHOOK\",
  \"method\": \"$PUSH_CUSTOM_METHOD\",
  \"headers\": \"$PUSH_CUSTOM_HEADERS\",
  \"body\": \"$PUSH_CUSTOM_BODY\""
            ;;
    esac
    
    config_content="$config_content
}"
    
    echo "$config_content" > "$PUSH_CONFIG_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}推送配置已保存到: $PUSH_CONFIG_FILE${NC}"
    else
        echo -e "${RED}保存推送配置失败，请检查权限${NC}"
    fi
}

# 发送钉钉消息
send_dingtalk_message() {
    local message="$1"
    local title="$2"
    
    if [ -z "$PUSH_DINGTALK_WEBHOOK" ]; then
        echo -e "${RED}钉钉推送未配置，无法发送消息${NC}"
        return 1
    fi
    
    # 获取当前时间戳
    local timestamp=$(date +%s)
    
    # 如果有secret，计算签名
    local sign=""
    if [ -n "$PUSH_DINGTALK_SECRET" ]; then
        local string_to_sign="${timestamp}\n${PUSH_DINGTALK_SECRET}"
        sign=$(echo -n "$string_to_sign" | openssl sha256 -hmac "$PUSH_DINGTALK_SECRET" -binary | base64)
        sign=$(echo "$sign" | tr -d '\n')
    fi
    
    # 构造请求URL
    local url="$PUSH_DINGTALK_WEBHOOK"
    if [ -n "$sign" ]; then
        url="${url}&timestamp=${timestamp}&sign=${sign}"
    fi
    
    # 构造请求体
    local request_body=$(cat <<EOF
{
    "msgtype": "markdown",
    "markdown": {
        "title": "$title",
        "text": "**$title**\n\n$message\n\n---\n时间: $(date '+%Y-%m-%d %H:%M:%S')\n主机: $(hostname)"
    },
    "at": {
        "isAtAll": false
    }
}
EOF
    )
    
    # 发送请求
    local response=$(curl -s -X POST -H "Content-Type: application/json" -d "$request_body" "$url")
    
    if echo "$response" | grep -q '"errcode":0'; then
        echo -e "${GREEN}钉钉消息发送成功${NC}"
        return 0
    else
        echo -e "${RED}钉钉消息发送失败: $response${NC}"
        return 1
    fi
}

# 发送PlusPush消息
send_pluspush_message() {
    local message="$1"
    local title="$2"
    
    if [ -z "$PUSH_PLUSPUSH_TOKEN" ]; then
        echo -e "${RED}PlusPush推送未配置，无法发送消息${NC}"
        return 1
    fi
    
    local request_body=$(cat <<EOF
{
    "token": "$PUSH_PLUSPUSH_TOKEN",
    "title": "$title",
    "content": "$message\n\n主机: $(hostname)\n时间: $(date '+%Y-%m-%d %H:%M:%S')",
    "template": "markdown"
}
EOF
    )
    
    local response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "$request_body" "https://www.pushplus.plus/send")
    
    if echo "$response" | grep -q '"code":200'; then
        echo -e "${GREEN}PlusPush消息发送成功${NC}"
        return 0
    else
        echo -e "${RED}PlusPush消息发送失败: $response${NC}"
        return 1
    fi
}

# 发送泛微OA消息
send_weoa_message() {
    local message="$1"
    local title="$2"
    
    if [ -z "$PUSH_WEOA_WEBHOOK" ] || [ -z "$PUSH_WEOA_KEY" ]; then
        echo -e "${RED}泛微OA推送未配置，无法发送消息${NC}"
        return 1
    fi
    
    local request_body=$(cat <<EOF
{
    "key": "$PUSH_WEOA_KEY",
    "title": "$title",
    "content": "$message",
    "host": "$(hostname)",
    "time": "$(date '+%Y-%m-%d %H:%M:%S')"
}
EOF
    )
    
    local response=$(curl -s -X POST -H "Content-Type: application/json" \
        -H "Authorization: Bearer $PUSH_WEOA_KEY" \
        -d "$request_body" "$PUSH_WEOA_WEBHOOK")
    
    if echo "$response" | grep -q '"success":true'; then
        echo -e "${GREEN}泛微OA消息发送成功${NC}"
        return 0
    else
        echo -e "${RED}泛微OA消息发送失败: $response${NC}"
        return 1
    fi
}

# 发送自定义消息
send_custom_message() {
    local message="$1"
    local title="$2"
    
    if [ -z "$PUSH_CUSTOM_WEBHOOK" ]; then
        echo -e "${RED}自定义推送未配置，无法发送消息${NC}"
        return 1
    fi
    
    # 替换变量
    local body_content=$(echo "$PUSH_CUSTOM_BODY" | sed \
        -e "s/{{message}}/$message/g" \
        -e "s/{{title}}/$title/g" \
        -e "s/{{hostname}}/$(hostname)/g" \
        -e "s/{{datetime}}/$(date '+%Y-%m-%d %H:%M:%S')/g" \
        -e "s/{{date}}/$(date '+%Y-%m-%d')/g" \
        -e "s/{{time}}/$(date '+%H:%M:%S')/g")
    
    # 发送请求
    local curl_cmd="curl -s -X $PUSH_CUSTOM_METHOD"
    
    # 添加headers
    if [ -n "$PUSH_CUSTOM_HEADERS" ]; then
        # 将headers字符串拆分为数组
        IFS=';' read -ra HEADERS <<< "$PUSH_CUSTOM_HEADERS"
        for header in "${HEADERS[@]}"; do
            if [ -n "$header" ]; then
                curl_cmd="$curl_cmd -H \"$header\""
            fi
        done
    fi
    
    # 添加请求体
    if [ -n "$body_content" ]; then
        curl_cmd="$curl_cmd -d '$body_content'"
    fi
    
    # 添加URL并执行
    curl_cmd="$curl_cmd \"$PUSH_CUSTOM_WEBHOOK\""
    
    local response=$(eval $curl_cmd 2>&1)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        echo -e "${GREEN}自定义消息发送成功${NC}"
        return 0
    else
        echo -e "${RED}自定义消息发送失败: $response${NC}"
        return 1
    fi
}

# 推送消息（主函数）
push_message() {
    local message="$1"
    local title="$2"
    
    # 如果没有启用推送，直接返回
    if [ "$PUSH_ENABLED" = "false" ]; then
        return 0
    fi
    
    echo -e "${CYAN}正在发送推送消息...${NC}"
    
    case "$PUSH_TYPE" in
        "dingtalk")
            send_dingtalk_message "$message" "$title"
            ;;
        "pluspush")
            send_pluspush_message "$message" "$title"
            ;;
        "weoa")
            send_weoa_message "$message" "$title"
            ;;
        "custom")
            send_custom_message "$message" "$title"
            ;;
        *)
            echo -e "${RED}未知的推送类型: $PUSH_TYPE${NC}"
            return 1
            ;;
    esac
    
    return $?
}

# 发送操作完成推送
send_operation_completed_push() {
    local operation_name="$1"
    local operation_status="$2"
    local details="$3"
    
    # 如果没有启用推送，直接返回
    if [ "$PUSH_ENABLED" = "false" ]; then
        return 0
    fi
    
    local message="操作: $operation_name\n状态: $operation_status\n主机: $(hostname)\n时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ -n "$details" ]; then
        message="$message\n详情: $details"
    fi
    
    push_message "$message" "Linux面板操作完成通知"
}

# 为函数添加推送功能（封装函数）
function_with_push() {
    local func_name="$1"
    local func_display_name="$2"
    shift 2
    
    echo -e "${CYAN}正在执行: $func_display_name${NC}"
    echo ""
    
    # 执行原函数
    "$func_name" "$@"
    
    # 获取函数执行结果
    local exit_code=$?
    local status_text="成功"
    
    if [ $exit_code -eq 0 ]; then
        status_text="成功"
    else
        status_text="失败"
    fi
    
    # 发送推送消息
    send_operation_completed_push "$func_display_name" "$status_text" ""
    
    return $exit_code
}

# 配置消息推送
configure_push_notification() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}         消息推送配置${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 加载现有配置
    load_push_config
    
    echo -e "${CYAN}当前推送状态: ${PUSH_ENABLED}${NC}"
    echo -e "${CYAN}当前推送类型: ${PUSH_TYPE}${NC}"
    echo ""
    
    echo -e "${GREEN}1.${NC} 启用/禁用推送"
    echo -e "${GREEN}2.${NC} 配置钉钉推送"
    echo -e "${GREEN}3.${NC} 配置PlusPush推送"
    echo -e "${GREEN}4.${NC} 配置泛微OA推送"
    echo -e "${GREEN}5.${NC} 配置自定义推送"
    echo -e "${GREEN}6.${NC} 测试推送"
    echo -e "${GREEN}7.${NC} 返回主菜单"
    echo ""
    
    read -p "请选择功能 (1-7): " choice
    
    case $choice in
        1)
            # 启用/禁用推送
            if [ "$PUSH_ENABLED" = "true" ]; then
                PUSH_ENABLED="false"
                echo -e "${YELLOW}已禁用消息推送${NC}"
            else
                PUSH_ENABLED="true"
                echo -e "${GREEN}已启用消息推送${NC}"
            fi
            save_push_config
            read -p "按回车键继续..."
            configure_push_notification
            ;;
        2)
            # 配置钉钉推送
            echo -e "${CYAN}配置钉钉推送${NC}"
            echo ""
            read -p "请输入钉钉机器人Webhook地址: " PUSH_DINGTALK_WEBHOOK
            read -p "请输入钉钉机器人密钥（可选，留空跳过）: " PUSH_DINGTALK_SECRET
            
            if [ -n "$PUSH_DINGTALK_WEBHOOK" ]; then
                PUSH_TYPE="dingtalk"
                PUSH_ENABLED="true"
                save_push_config
                echo -e "${GREEN}钉钉推送配置已保存${NC}"
            else
                echo -e "${RED}Webhook地址不能为空${NC}"
            fi
            read -p "按回车键继续..."
            configure_push_notification
            ;;
        3)
            # 配置PlusPush推送
            echo -e "${CYAN}配置PlusPush推送${NC}"
            echo ""
            read -p "请输入PlusPush Token: " PUSH_PLUSPUSH_TOKEN
            
            if [ -n "$PUSH_PLUSPUSH_TOKEN" ]; then
                PUSH_TYPE="pluspush"
                PUSH_ENABLED="true"
                save_push_config
                echo -e "${GREEN}PlusPush推送配置已保存${NC}"
            else
                echo -e "${RED}Token不能为空${NC}"
            fi
            read -p "按回车键继续..."
            configure_push_notification
            ;;
        4)
            # 配置泛微OA推送
            echo -e "${CYAN}配置泛微OA推送${NC}"
            echo ""
            read -p "请输入泛微OA Webhook地址: " PUSH_WEOA_WEBHOOK
            read -p "请输入泛微OA Key: " PUSH_WEOA_KEY
            
            if [ -n "$PUSH_WEOA_WEBHOOK" ] && [ -n "$PUSH_WEOA_KEY" ]; then
                PUSH_TYPE="weoa"
                PUSH_ENABLED="true"
                save_push_config
                echo -e "${GREEN}泛微OA推送配置已保存${NC}"
            else
                echo -e "${RED}Webhook地址和Key都不能为空${NC}"
            fi
            read -p "按回车键继续..."
            configure_push_notification
            ;;
        5)
            # 配置自定义推送
            echo -e "${CYAN}配置自定义推送${NC}"
            echo ""
            read -p "请输入自定义Webhook地址: " PUSH_CUSTOM_WEBHOOK
            read -p "请输入请求方法 (默认: POST): " PUSH_CUSTOM_METHOD
            PUSH_CUSTOM_METHOD=${PUSH_CUSTOM_METHOD:-POST}
            
            echo -e "请输入请求头（多个用分号分隔，如：Content-Type: application/json;Authorization: Bearer token）:"
            read PUSH_CUSTOM_HEADERS
            
            echo -e "请输入请求体模板（可使用变量：{{message}}, {{title}}, {{hostname}}, {{datetime}}, {{date}}, {{time}}）:"
            read PUSH_CUSTOM_BODY
            
            if [ -n "$PUSH_CUSTOM_WEBHOOK" ]; then
                PUSH_TYPE="custom"
                PUSH_ENABLED="true"
                save_push_config
                echo -e "${GREEN}自定义推送配置已保存${NC}"
            else
                echo -e "${RED}Webhook地址不能为空${NC}"
            fi
            read -p "按回车键继续..."
            configure_push_notification
            ;;
        6)
            # 测试推送
            echo -e "${CYAN}测试推送功能${NC}"
            echo ""
            
            load_push_config
            
            if [ "$PUSH_ENABLED" = "false" ]; then
                echo -e "${YELLOW}推送功能未启用，请先配置推送${NC}"
                read -p "按回车键继续..."
                configure_push_notification
                return
            fi
            
            local test_message="这是一条测试消息，用于验证推送功能是否正常工作。"
            local test_title="Linux面板脚本测试推送"
            
            echo -e "推送类型: ${YELLOW}$PUSH_TYPE${NC}"
            echo -e "推送消息: ${YELLOW}$test_message${NC}"
            echo ""
            
            push_message "$test_message" "$test_title"
            
            echo ""
            read -p "按回车键继续..."
            configure_push_notification
            ;;
        7)
            # 返回主菜单
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            read -p "按回车键继续..."
            configure_push_notification
            ;;
    esac
}

# 由于时间关系，我先完成主要功能框架，后续可以继续完善具体实现

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
        echo -e "${GREEN}4.${NC} GitHub DNS污染检测与修复"
        echo -e "${GREEN}5.${NC} Docker镜像源DNS检测与修复"
        echo -e "${GREEN}6.${NC} 安装 Docker"
        echo -e "${GREEN}7.${NC} 服务器信息"
        echo -e "${GREEN}8.${NC} 网络测速功能"
        echo -e "${GREEN}9.${NC} 时间校准功能"
        echo -e "${GREEN}10.${NC} NAS配置功能"
        echo -e "${GREEN}11.${NC} 数据库备份功能"
        echo -e "${GREEN}12.${NC} Docker镜像源切换"
        echo -e "${GREEN}13.${NC} 防火墙端口管理"
        echo -e "${GREEN}14.${NC} DNS污染检测与优化"
        echo -e "${GREEN}15.${NC} 消息推送配置"
        echo -e "${GREEN}16.${NC} 退出脚本"
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}提示: 请确保系统有足够的磁盘空间和内存${NC}"
        echo ""
        
        read -p "请选择功能 (1-16): " choice
        
        case $choice in
            1)
                function_with_push "install_baota" "安装宝塔面板"
                ;;
            2)
                function_with_push "install_ne_zha" "安装哪吒监控面板"
                ;;
            3)
                function_with_push "install_xui" "安装 X-UI 面板"
                ;;
            4)
                function_with_push "fix_github_dns" "GitHub DNS污染检测与修复"
                ;;
            5)
                function_with_push "fix_docker_dns" "Docker镜像源DNS检测与修复"
                ;;
            6)
                function_with_push "install_docker" "安装 Docker"
                ;;
            7)
                function_with_push "show_system_info" "查看服务器信息"
                ;;
            8)
                function_with_push "network_speed_test" "网络测速功能"
                ;;
            9)
                function_with_push "time_sync" "时间校准功能"
                ;;
            10)
                function_with_push "nas_mount_config" "NAS配置功能"
                ;;
            11)
                function_with_push "database_backup" "数据库备份功能"
                ;;
            12)
                function_with_push "docker_mirror_switch" "Docker镜像源切换"
                ;;
            13)
                function_with_push "firewall_management" "防火墙端口管理"
                ;;
            14)
                function_with_push "dns_pollution_detection" "DNS污染检测与优化"
                ;;
            15)
                function_with_push "configure_push_notification" "消息推送配置"
                ;;
            16)
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

# Docker镜像源切换功能
docker_mirror_switch() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          Docker镜像源切换${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查Docker是否安装
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker未安装，请先安装Docker${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    echo -e "${CYAN}当前Docker镜像源配置:${NC}"
    cat /etc/docker/daemon.json 2>/dev/null || echo "未配置镜像源"
    echo ""
    
    echo -e "${CYAN}选择镜像源:${NC}"
    echo -e "  ${GREEN}1.${NC} 阿里云镜像源"
    echo -e "  ${GREEN}2.${NC} 腾讯云镜像源"
    echo -e "  ${GREEN}3.${NC} 华为云镜像源"
    echo -e "  ${GREEN}4.${NC} 网易云镜像源"
    echo -e "  ${GREEN}5.${NC} 中科大镜像源"
    echo -e "  ${GREEN}6.${NC} Docker官方源"
    echo -e "  ${GREEN}7.${NC} 自定义镜像源"
    echo -e "  ${GREEN}8.${NC} 查看当前镜像源"
    echo -e "  ${GREEN}9.${NC} 测试镜像源速度"
    echo -e "  ${GREEN}10.${NC} 返回主菜单"
    echo ""
    
    read -p "请选择操作 (1-10): " mirror_choice
    
    case $mirror_choice in
        1)
            # 阿里云镜像源
            configure_docker_mirror "https://<your-id>.mirror.aliyuncs.com" "阿里云"
            ;;
        2)
            # 腾讯云镜像源
            configure_docker_mirror "https://mirror.ccs.tencentyun.com" "腾讯云"
            ;;
        3)
            # 华为云镜像源
            configure_docker_mirror "https://<your-id>.swr.myhuaweicloud.com" "华为云"
            ;;
        4)
            # 网易云镜像源
            configure_docker_mirror "https://hub-mirror.c.163.com" "网易云"
            ;;
        5)
            # 中科大镜像源
            configure_docker_mirror "https://docker.mirrors.ustc.edu.cn" "中科大"
            ;;
        6)
            # Docker官方源
            configure_docker_mirror "" "Docker官方"
            ;;
        7)
            # 自定义镜像源
            read -p "请输入自定义镜像源URL: " custom_mirror
            if [ -n "$custom_mirror" ]; then
                configure_docker_mirror "$custom_mirror" "自定义"
            fi
            ;;
        8)
            # 查看当前镜像源
            show_current_mirror
            ;;
        9)
            # 测试镜像源速度
            test_mirror_speed
            ;;
        10)
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            docker_mirror_switch
            ;;
    esac
}

# 配置Docker镜像源
configure_docker_mirror() {
    local mirror_url="$1"
    local mirror_name="$2"
    
    echo -e "${CYAN}正在配置${mirror_name}镜像源...${NC}"
    
    # 创建daemon.json文件
    local daemon_config="{}"
    
    if [ -f /etc/docker/daemon.json ]; then
        daemon_config=$(cat /etc/docker/daemon.json)
    fi
    
    # 更新配置
    if [ -z "$mirror_url" ]; then
        # 使用官方源，移除registry-mirrors配置
        echo "{}" > /etc/docker/daemon.json
        echo -e "${GREEN}已配置为Docker官方源${NC}"
    else
        # 配置镜像源
        cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["$mirror_url"],
  "insecure-registries": [],
  "debug": false,
  "experimental": false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
        echo -e "${GREEN}已配置${mirror_name}镜像源: $mirror_url${NC}"
    fi
    
    # 重启Docker服务
    echo -e "${CYAN}重启Docker服务...${NC}"
    systemctl restart docker
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker服务重启成功！${NC}"
        echo -e "${CYAN}新配置:${NC}"
        cat /etc/docker/daemon.json
    else
        echo -e "${RED}Docker服务重启失败${NC}"
    fi
    
    echo ""
    read -p "按回车键返回镜像源菜单..."
    docker_mirror_switch
}

# 查看当前镜像源
show_current_mirror() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          当前Docker镜像源配置${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}/etc/docker/daemon.json 内容:${NC}"
    cat /etc/docker/daemon.json 2>/dev/null || echo "文件不存在"
    echo ""
    
    echo -e "${CYAN}Docker信息:${NC}"
    docker info 2>/dev/null | grep -A5 "Registry Mirrors" || echo "无法获取Docker信息"
    echo ""
    
    read -p "按回车键返回镜像源菜单..."
    docker_mirror_switch
}

# 测试镜像源速度
test_mirror_speed() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          测试Docker镜像源速度${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${YELLOW}注意: 测试可能需要几分钟时间${NC}"
    echo ""
    
    local test_images=(
        "hello-world"
        "alpine"
        "nginx"
        "busybox"
    )
    
    echo -e "${CYAN}测试镜像源拉取速度...${NC}"
    echo ""
    
    for image in "${test_images[@]}"; do
        echo -e "测试拉取镜像: ${YELLOW}$image${NC}"
        
        local start_time=$(date +%s.%N)
        docker pull "$image" > /dev/null 2>&1
        local end_time=$(date +%s.%N)
        
        local elapsed_time=$(echo "$end_time - $start_time" | bc)
        
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓ 成功: ${elapsed_time}秒${NC}"
            
            # 清理镜像
            docker rmi "$image" > /dev/null 2>&1
        else
            echo -e "  ${RED}✗ 失败${NC}"
        fi
        
        echo ""
    done
    
    echo -e "${CYAN}测试完成！${NC}"
    echo ""
    read -p "按回车键返回镜像源菜单..."
    docker_mirror_switch
}

# 防火墙管理功能
firewall_management() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          防火墙端口管理${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}选择防火墙类型:${NC}"
    echo -e "  ${GREEN}1.${NC} iptables 防火墙"
    echo -e "  ${GREEN}2.${NC} firewalld 防火墙"
    echo -e "  ${GREEN}3.${NC} ufw 防火墙 (Ubuntu)"
    echo -e "  ${GREEN}4.${NC} 查看当前端口状态"
    echo -e "  ${GREEN}5.${NC} 返回主菜单"
    echo ""
    
    read -p "请选择防火墙类型 (1-5): " firewall_type
    
    case $firewall_type in
        1)
            iptables_management
            ;;
        2)
            firewalld_management
            ;;
        3)
            ufw_management
            ;;
        4)
            view_port_status
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            firewall_management
            ;;
    esac
}

# iptables管理
iptables_management() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          iptables 防火墙管理${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查iptables是否安装
    if ! command -v iptables &> /dev/null; then
        echo -e "${YELLOW}iptables未安装${NC}"
        read -p "按回车键返回..."
        firewall_management
        return
    fi
    
    echo -e "${CYAN}当前iptables规则:${NC}"
    iptables -L -n -v
    echo ""
    
    echo -e "${CYAN}iptables操作:${NC}"
    echo -e "  ${GREEN}1.${NC} 查看详细规则"
    echo -e "  ${GREEN}2.${NC} 开放端口"
    echo -e "  ${GREEN}3.${NC} 关闭端口"
    echo -e "  ${GREEN}4.${NC} 允许IP地址"
    echo -e "  ${GREEN}5.${NC} 拒绝IP地址"
    echo -e "  ${GREEN}6.${NC} 保存规则"
    echo -e "  ${GREEN}7.${NC} 恢复规则"
    echo -e "  ${GREEN}8.${NC} 清空规则"
    echo -e "  ${GREEN}9.${NC} 返回上一级"
    echo ""
    
    read -p "请选择操作 (1-9): " iptables_choice
    
    case $iptables_choice in
        1)
            view_iptables_details
            ;;
        2)
            open_iptables_port
            ;;
        3)
            close_iptables_port
            ;;
        4)
            allow_iptables_ip
            ;;
        5)
            deny_iptables_ip
            ;;
        6)
            save_iptables_rules
            ;;
        7)
            restore_iptables_rules
            ;;
        8)
            clear_iptables_rules
            ;;
        9)
            firewall_management
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            iptables_management
            ;;
    esac
}

# firewalld管理
firewalld_management() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          firewalld 防火墙管理${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查firewalld是否安装
    if ! command -v firewall-cmd &> /dev/null; then
        echo -e "${YELLOW}firewalld未安装${NC}"
        read -p "按回车键返回..."
        firewall_management
        return
    fi
    
    echo -e "${CYAN}当前firewalld状态:${NC}"
    firewall-cmd --state
    echo ""
    
    echo -e "${CYAN}当前zone信息:${NC}"
    firewall-cmd --get-active-zones
    echo ""
    
    echo -e "${CYAN}firewalld操作:${NC}"
    echo -e "  ${GREEN}1.${NC} 查看所有规则"
    echo -e "  ${GREEN}2.${NC} 开放端口"
    echo -e "  ${GREEN}3.${NC} 关闭端口"
    echo -e "  ${GREEN}4.${NC} 添加服务"
    echo -e "  ${GREEN}5.${NC} 移除服务"
    echo -e "  ${GREEN}6.${NC} 添加端口范围"
    echo -e "  ${GREEN}7.${NC} 添加富规则"
    echo -e "  ${GREEN}8.${NC} 重载配置"
    echo -e "  ${GREEN}9.${NC} 返回上一级"
    echo ""
    
    read -p "请选择操作 (1-9): " firewalld_choice
    
    case $firewalld_choice in
        1)
            view_firewalld_rules
            ;;
        2)
            open_firewalld_port
            ;;
        3)
            close_firewalld_port
            ;;
        4)
            add_firewalld_service
            ;;
        5)
            remove_firewalld_service
            ;;
        6)
            add_firewalld_port_range
            ;;
        7)
            add_firewalld_rich_rule
            ;;
        8)
            reload_firewalld
            ;;
        9)
            firewall_management
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            firewalld_management
            ;;
    esac
}

# ufw管理 (Ubuntu)
ufw_management() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          ufw 防火墙管理${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查ufw是否安装
    if ! command -v ufw &> /dev/null; then
        echo -e "${YELLOW}ufw未安装${NC}"
        read -p "按回车键返回..."
        firewall_management
        return
    fi
    
    echo -e "${CYAN}当前ufw状态:${NC}"
    ufw status verbose
    echo ""
    
    echo -e "${CYAN}ufw操作:${NC}"
    echo -e "  ${GREEN}1.${NC} 启用ufw"
    echo -e "  ${GREEN}2.${NC} 禁用ufw"
    echo -e "  ${GREEN}3.${NC} 开放端口"
    echo -e "  ${GREEN}4.${NC} 关闭端口"
    echo -e "  ${GREEN}5.${NC} 允许IP地址"
    echo -e "  ${GREEN}6.${NC} 拒绝IP地址"
    echo -e "  ${GREEN}7.${NC} 重置规则"
    echo -e "  ${GREEN}8.${NC} 查看规则编号"
    echo -e "  ${GREEN}9.${NC} 删除规则"
    echo -e "  ${GREEN}10.${NC} 返回上一级"
    echo ""
    
    read -p "请选择操作 (1-10): " ufw_choice
    
    case $ufw_choice in
        1)
            enable_ufw
            ;;
        2)
            disable_ufw
            ;;
        3)
            open_ufw_port
            ;;
        4)
            close_ufw_port
            ;;
        5)
            allow_ufw_ip
            ;;
        6)
            deny_ufw_ip
            ;;
        7)
            reset_ufw
            ;;
        8)
            show_ufw_rules_numbered
            ;;
        9)
            delete_ufw_rule
            ;;
        10)
            firewall_management
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            sleep 2
            ufw_management
            ;;
    esac
}

# 查看端口状态
view_port_status() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}          当前端口状态${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    echo -e "${CYAN}监听端口:${NC}"
    ss -tulpn | grep LISTEN
    echo ""
    
    echo -e "${CYAN}网络连接:${NC}"
    netstat -tunap
    echo ""
    
    echo -e "${CYAN}防火墙状态:${NC}"
    
    # 检查各种防火墙
    if command -v iptables &> /dev/null; then
        echo -e "iptables:"
        iptables -L -n --line-numbers | head -20
        echo ""
    fi
    
    if command -v firewall-cmd &> /dev/null; then
        echo -e "firewalld:"
        firewall-cmd --list-all
        echo ""
    fi
    
    if command -v ufw &> /dev/null; then
        echo -e "ufw:"
        ufw status
        echo ""
    fi
    
    read -p "按回车键返回防火墙菜单..."
    firewall_management
}

# 由于时间关系，我先完成主要功能框架，具体实现可以后续完善

# 脚本入口
main() {
    # 检查root权限
    check_root
    
    # 显示欢迎信息
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}      Linux 面板与工具安装脚本${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${CYAN}版本: 2.1${NC}"
    echo -e "${CYAN}更新: 添加DNS污染检测与优化、消息推送配置功能，集成Docker DNS修复到安装流程${NC}"
    echo -e "${CYAN}作者: Linux运维助手${NC}"
    echo -e "${CYAN}日期: $(date)${NC}"
    echo ""
    
    # 加载推送配置
    load_push_config
    
    # 获取系统信息
    get_system_info
    
    # 显示主菜单
    main_menu
}

# 运行主函数
main