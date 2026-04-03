#!/bin/bash

# Linux面板安装脚本主文件
# 整合所有模块化功能

# 定义全局变量
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

# 定时任务配置
CRON_TASK_FILE="/etc/cron.d/linux_panel_tasks"
CRON_TASK_REGISTRY="/etc/linux_panel_tasks.list"
CRON_TASK_DIR="/opt/linux_panel_tasks"
CRON_LOG_DIR="/var/log/linux_panel_tasks"

# 导入模块
source "$(dirname "$0")/modules/common.sh"
source "$(dirname "$0")/modules/utils.sh"
source "$(dirname "$0")/modules/compatibility.sh"
source "$(dirname "$0")/modules/monitor.sh"
source "$(dirname "$0")/modules/panel.sh"
source "$(dirname "$0")/modules/docker.sh"

# 主菜单
main_menu() {
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}       Linux 面板与工具安装脚本${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo ""
        echo -e "${CYAN}系统信息:${NC}"
        echo -e "主机名: $(hostname)"
        echo -e "操作系统: $OS_INFO"
        echo -e "公网IP: $(get_public_ip)"
        echo -e "内网IP: $(get_primary_ip)"
        echo ""
        echo -e "${GREEN}1.${NC} 面板安装"
        echo -e "${GREEN}2.${NC} 网络与DNS"
        echo -e "${GREEN}3.${NC} 数据与备份"
        echo -e "${GREEN}4.${NC} 服务器管理"
        echo -e "${GREEN}5.${NC} 运维工具"
        echo -e "${GREEN}6.${NC} Docker功能"
        echo -e "${GREEN}0.${NC} 退出脚本"
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo ""
        
        read -p "请选择功能 (0-6): " main_choice
        
        case $main_choice in
            1)
                panel_menu
                ;;
            2)
                network_menu
                ;;
            3)
                data_menu
                ;;
            4)
                server_menu
                ;;
            5)
                tools_menu
                ;;
            6)
                install_docker
                ;;
            0)
                echo -e "${GREEN}脚本执行完成，感谢使用！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 面板安装菜单
panel_menu() {
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}          面板安装菜单${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo ""
        echo -e "${GREEN}1.${NC} 安装宝塔面板"
        echo -e "${GREEN}2.${NC} 安装哪吒监控面板"
        echo -e "${GREEN}3.${NC} 安装 X-UI 面板"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo ""
        
        read -p "请选择 (0-3): " panel_choice
        
        case $panel_choice in
            1)
                install_baota
                ;;
            2)
                install_ne_zha
                ;;
            3)
                install_xui
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 网络与DNS菜单
network_menu() {
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}        网络与DNS菜单${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo ""
        echo -e "${GREEN}1.${NC} GitHub DNS污染检测与修复"
        echo -e "${GREEN}2.${NC} Docker镜像源DNS检测与修复"
        echo -e "${GREEN}3.${NC} 网络测速功能"
        echo -e "${GREEN}4.${NC} 时间校准功能"
        echo -e "${GREEN}5.${NC} DNS污染检测与优化"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo ""
        
        read -p "请选择 (0-5): " network_choice
        
        case $network_choice in
            1)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            2)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            3)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            4)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            5)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 数据与备份菜单
data_menu() {
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}        数据与备份菜单${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo ""
        echo -e "${GREEN}1.${NC} 数据库备份功能"
        echo -e "${GREEN}2.${NC} 定时任务中心"
        echo -e "${GREEN}3.${NC} Docker镜像源切换"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo ""
        
        read -p "请选择 (0-3): " data_choice
        
        case $data_choice in
            1)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            2)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            3)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 服务器管理菜单
server_menu() {
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}        服务器管理菜单${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo ""
        echo -e "${GREEN}1.${NC} 查看服务器信息"
        echo -e "${GREEN}2.${NC} 网络测速功能"
        echo -e "${GREEN}3.${NC} 时间校准功能"
        echo -e "${GREEN}4.${NC} 防火墙端口管理"
        echo -e "${GREEN}5.${NC} NAS配置功能"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo ""
        
        read -p "请选择 (0-5): " server_choice
        
        case $server_choice in
            1)
                show_system_info
                ;;
            2)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            3)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            4)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            5)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 运维工具菜单
tools_menu() {
    while true; do
        clear
        echo -e "${PURPLE}========================================${NC}"
        echo -e "${PURPLE}          运维工具菜单${NC}"
        echo -e "${PURPLE}========================================${NC}"
        echo ""
        echo -e "${GREEN}1.${NC} 安装 Docker"
        echo -e "${GREEN}2.${NC} 运维功能"
        echo -e "${GREEN}3.${NC} 系统监控工具"
        echo -e "${GREEN}4.${NC} 安全检查工具"
        echo -e "${GREEN}5.${NC} 软件包助手"
        echo -e "${GREEN}6.${NC} 消息推送配置"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo ""
        
        read -p "请选择 (0-6): " tools_choice
        
        case $tools_choice in
            1)
                install_docker
                ;;
            2)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            3)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            4)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            5)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            6)
                echo -e "${YELLOW}功能开发中...${NC}"
                sleep 2
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 主函数
main() {
    # 检查root权限
    check_root
    
    # 初始化日志系统
    init_log_dir
    rotate_logs
    log_info "开始执行Linux面板安装脚本"
    
    # 检查系统兼容性
    log_info "检查系统兼容性"
    check_system_compatibility
    
    # 检查发行版特定兼容性
    check_distro_compatibility
    
    # 检查文件系统
    check_filesystem
    
    # 检查SELinux状态
    check_selinux
    
    # 检查防火墙状态
    check_firewall
    
    # 获取系统信息
    log_info "获取系统信息"
    get_system_info
    
    # 初始化定时任务环境
    log_info "初始化定时任务环境"
    init_cron_env
    
    # 显示主菜单
    log_info "显示主菜单"
    main_menu
    
    log_info "脚本执行完成"
}

# 执行主函数
main
