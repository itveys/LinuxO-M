#!/bin/bash

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
        echo -e "面板地址: https://$(get_primary_ip):8888"
        echo -e "默认用户名: admin"
        echo -e "获取默认密码: bt default"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    # 根据系统选择安装命令
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            echo -e "${CYAN}检测到 CentOS/RHEL/Fedora 系统，使用yum安装...${NC}"
            if ! ensure_download_tool; then
                read -p "按回车键返回主菜单..."
                return
            fi
            if download_file "https://download.bt.cn/install/install_6.0.sh" "install.sh"; then
                bash install.sh
            else
                echo -e "${RED}下载安装脚本失败，请检查网络连接${NC}"
                read -p "按回车键返回主菜单..."
                return
            fi
            ;;
        "ubuntu"|"debian")
            echo -e "${CYAN}检测到 Ubuntu/Debian 系统，使用apt安装...${NC}"
            if ! ensure_download_tool; then
                read -p "按回车键返回主菜单..."
                return
            fi
            if download_file "https://download.bt.cn/install/install-ubuntu_6.0.sh" "install.sh"; then
                bash install.sh
            else
                echo -e "${RED}下载安装脚本失败，请检查网络连接${NC}"
                read -p "按回车键返回主菜单..."
                return
            fi
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
        echo -e "面板地址: https://$(get_primary_ip):8888"
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
    if ! ensure_download_tool; then
        read -p "按回车键返回主菜单..."
        return
    fi
    download_file "https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh" "nezha.sh"
    chmod +x nezha.sh
    
    if [ ! -s "nezha.sh" ]; then
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
        echo -e "面板地址: http://$(get_primary_ip):54321"
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
    if ! ensure_download_tool; then
        read -p "按回车键返回主菜单..."
        return
    fi
    download_file "https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh" "x-ui-install.sh"
    
    if [ ! -s "x-ui-install.sh" ]; then
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
        echo -e "面板地址: http://$(get_primary_ip):54321"
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
