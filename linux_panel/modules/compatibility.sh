#!/bin/bash

# 系统兼容性检查模块
# 包含各种系统兼容性检查功能

# 检查系统版本兼容性
check_system_compatibility() {
    log_info "检查系统兼容性..."
    
    # 检查系统类型
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log_warn "警告: 此脚本主要设计用于Linux系统，在其他系统上可能无法正常工作"
    fi
    
    # 检查系统架构
    check_architecture
    
    # 检查内核版本
    check_kernel_version
    
    # 检查必要工具
    check_required_tools
    
    # 检查网络连接
    check_network_connection
    
    # 检查系统资源
    check_system_resources
    
    log_info "系统兼容性检查完成"
}

# 检查系统架构
check_architecture() {
    local arch=$(uname -m)
    log_info "系统架构: $arch"
    
    case $arch in
        "x86_64"|"amd64")
            log_info "支持的架构: $arch"
            ;;
        "aarch64"|"arm64")
            log_info "支持的架构: $arch"
            ;;
        "i386"|"i686")
            log_warn "警告: 32位架构可能存在兼容性问题"
            ;;
        *)
            log_warn "警告: 未知架构: $arch，可能存在兼容性问题"
            ;;
    esac
}

# 检查内核版本
check_kernel_version() {
    local kernel_version=$(uname -r)
    local major_version=$(echo $kernel_version | cut -d. -f1)
    local minor_version=$(echo $kernel_version | cut -d. -f2)
    
    log_info "内核版本: $kernel_version"
    
    if [ $major_version -lt 3 ]; then
        log_error "错误: 内核版本过低，建议至少 3.10 或更高"
        exit 1
    elif [ $major_version -eq 3 ] && [ $minor_version -lt 10 ]; then
        log_warn "警告: 内核版本较低，可能存在兼容性问题"
    else
        log_info "内核版本满足要求"
    fi
}

# 检查必要工具
check_required_tools() {
    log_info "检查必要工具..."
    
    local required_tools=(
        "bash"
        "awk"
        "sed"
        "grep"
        "cut"
        "date"
        "hostname"
        "ip"
    )
    
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+="$tool"
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        log_info "正在尝试安装缺少的工具..."
        
        case $DISTRO in
            "centos"|"rhel"|"fedora")
                exec_package_command "install" "${missing_tools[*]}"
                ;;
            "ubuntu"|"debian")
                exec_package_command "install" "${missing_tools[*]}"
                ;;
            *)
                log_error "无法自动安装工具，请手动安装缺少的工具"
                exit 1
                ;;
        esac
    else
        log_info "所有必要工具都已安装"
    fi
}

# 检查网络连接
check_network_connection() {
    log_info "检查网络连接..."
    
    local test_urls=(
        "https://www.baidu.com"
        "https://www.google.com"
        "https://github.com"
    )
    
    local connected=false
    
    for url in "${test_urls[@]}"; do
        if curl -fsSL --connect-timeout 5 "$url" >/dev/null 2>&1; then
            log_info "网络连接正常: $url"
            connected=true
            break
        fi
    done
    
    if [ "$connected" = false ]; then
        log_warn "警告: 无法连接到网络，某些功能可能无法正常工作"
    else
        log_info "网络连接正常"
    fi
}

# 检查系统资源
check_system_resources() {
    log_info "检查系统资源..."
    
    # 检查内存
    check_memory 1024  # 至少1GB内存
    
    # 检查磁盘空间
    check_disk_space 10  # 至少10GB磁盘空间
    
    # 检查CPU核心数
    local cpu_cores=$(grep -c 'processor' /proc/cpuinfo)
    if [ $cpu_cores -lt 1 ]; then
        log_error "错误: 无法检测到CPU核心"
        exit 1
    elif [ $cpu_cores -lt 2 ]; then
        log_warn "警告: CPU核心数较少，可能影响性能"
    else
        log_info "CPU核心数: $cpu_cores"
    fi
}

# 检查系统发行版特定的兼容性
check_distro_compatibility() {
    log_info "检查发行版兼容性..."
    
    case $DISTRO in
        "centos")
            local version=$(cat /etc/centos-release | grep -oP '\d+' | head -1)
            if [ $version -lt 7 ]; then
                log_error "错误: CentOS 版本过低，建议至少 CentOS 7"
                exit 1
            else
                log_info "CentOS $version 兼容性良好"
            fi
            ;;
        "ubuntu")
            local version=$(lsb_release -r | awk '{print $2}')
            local major_version=$(echo $version | cut -d. -f1)
            if [ $major_version -lt 18 ]; then
                log_error "错误: Ubuntu 版本过低，建议至少 Ubuntu 18.04"
                exit 1
            else
                log_info "Ubuntu $version 兼容性良好"
            fi
            ;;
        "debian")
            local version=$(cat /etc/debian_version | cut -d. -f1)
            if [ $version -lt 9 ]; then
                log_error "错误: Debian 版本过低，建议至少 Debian 9"
                exit 1
            else
                log_info "Debian $version 兼容性良好"
            fi
            ;;
        "rhel"|"fedora")
            log_info "RHEL/Fedora 兼容性良好"
            ;;
        *)
            log_warn "警告: 未知发行版，可能存在兼容性问题"
            ;;
    esac
}

# 检查文件系统类型
check_filesystem() {
    log_info "检查文件系统..."
    
    local root_fs=$(df -T / | tail -1 | awk '{print $2}')
    log_info "根文件系统: $root_fs"
    
    case $root_fs in
        "ext4"|"xfs"|"btrfs")
            log_info "文件系统兼容性良好"
            ;;
        *)
            log_warn "警告: 可能存在文件系统兼容性问题"
            ;;
    esac
}

# 检查SELinux状态
check_selinux() {
    if command_exists sestatus; then
        local selinux_status=$(sestatus | grep 'SELinux status:' | awk '{print $3}')
        log_info "SELinux 状态: $selinux_status"
        
        if [ "$selinux_status" = "enabled" ]; then
            log_warn "警告: SELinux 已启用，可能会影响某些功能"
        fi
    fi
}

# 检查防火墙状态
check_firewall() {
    log_info "检查防火墙状态..."
    
    if command_exists firewall-cmd; then
        local firewall_status=$(firewall-cmd --state 2>/dev/null || echo "inactive")
        log_info "Firewalld 状态: $firewall_status"
    elif command_exists ufw; then
        local firewall_status=$(ufw status | grep 'Status:' | awk '{print $2}')
        log_info "UFW 状态: $firewall_status"
    elif command_exists iptables; then
        local firewall_status=$(iptables -L | grep -c 'Chain')
        if [ $firewall_status -gt 0 ]; then
            log_info "iptables 已配置"
        else
            log_info "iptables 未配置"
        fi
    else
        log_info "未检测到防火墙工具"
    fi
}
