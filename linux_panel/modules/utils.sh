#!/bin/bash

# 通用工具函数模块
# 包含各种重复使用的工具函数

# 读取用户输入并设置默认值
read_with_default() {
    local var_name="$1"
    local prompt="$2"
    local default="$3"
    
    read -p "$prompt (默认: $default): " input
    input=${input:-$default}
    eval "$var_name='$input'"
}

# 执行系统特定的包管理命令
exec_package_command() {
    local action="$1"  # install, remove, update
    local packages="$2"
    local extra_args="${3:-}"
    
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            case $action in
                "install")
                    yum install -y $extra_args $packages
                    ;;
                "remove")
                    yum remove -y $extra_args $packages
                    ;;
                "update")
                    yum update -y $extra_args $packages
                    ;;
                "update_all")
                    yum update -y
                    ;;
            esac
            ;;
        "ubuntu"|"debian")
            case $action in
                "install")
                    apt update && apt install -y $extra_args $packages
                    ;;
                "remove")
                    apt remove -y $extra_args $packages
                    ;;
                "update")
                    apt update && apt install -y --only-upgrade $extra_args $packages
                    ;;
                "update_all")
                    apt update && apt upgrade -y
                    ;;
            esac
            ;;
        *)
            log_error "不支持的系统: $DISTRO"
            return 1
            ;;
    esac
    
    return $?
}

# 检查服务状态
check_service_status() {
    local service_name="$1"
    
    if command_exists systemctl; then
        systemctl status "$service_name" >/dev/null 2>&1
        return $?
    elif command_exists service; then
        service "$service_name" status >/dev/null 2>&1
        return $?
    else
        log_error "无法检查服务状态: 未找到 systemctl 或 service 命令"
        return 1
    fi
}

# 启动服务
start_service() {
    local service_name="$1"
    
    if command_exists systemctl; then
        systemctl start "$service_name"
    elif command_exists service; then
        service "$service_name" start
    else
        log_error "无法启动服务: 未找到 systemctl 或 service 命令"
        return 1
    fi
    
    return $?
}

# 停止服务
stop_service() {
    local service_name="$1"
    
    if command_exists systemctl; then
        systemctl stop "$service_name"
    elif command_exists service; then
        service "$service_name" stop
    else
        log_error "无法停止服务: 未找到 systemctl 或 service 命令"
        return 1
    fi
    
    return $?
}

# 重启服务
restart_service() {
    local service_name="$1"
    
    if command_exists systemctl; then
        systemctl restart "$service_name"
    elif command_exists service; then
        service "$service_name" restart
    else
        log_error "无法重启服务: 未找到 systemctl 或 service 命令"
        return 1
    fi
    
    return $?
}

# 启用服务自启动
enable_service() {
    local service_name="$1"
    
    if command_exists systemctl; then
        systemctl enable "$service_name"
    elif command_exists chkconfig; then
        chkconfig "$service_name" on
    else
        log_error "无法启用服务自启动: 未找到 systemctl 或 chkconfig 命令"
        return 1
    fi
    
    return $?
}

# 禁用服务自启动
disable_service() {
    local service_name="$1"
    
    if command_exists systemctl; then
        systemctl disable "$service_name"
    elif command_exists chkconfig; then
        chkconfig "$service_name" off
    else
        log_error "无法禁用服务自启动: 未找到 systemctl 或 chkconfig 命令"
        return 1
    fi
    
    return $?
}

# 检查端口是否被占用
check_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    if command_exists netstat; then
        netstat -tuln | grep "$protocol" | grep ":$port " >/dev/null 2>&1
        return $?
    elif command_exists ss; then
        ss -tuln | grep "$protocol" | grep ":$port " >/dev/null 2>&1
        return $?
    else
        log_error "无法检查端口: 未找到 netstat 或 ss 命令"
        return 1
    fi
}

# 生成随机字符串
generate_random_string() {
    local length="${1:-16}"
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result=""
    
    for ((i=0; i<length; i++)); do
        result+="${chars:RANDOM%${#chars}:1}"
    done
    
    echo "$result"
}

# 检查系统内存
check_memory() {
    local min_memory_mb="$1"
    local total_memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_memory_mb=$((total_memory_kb / 1024))
    
    if [ $total_memory_mb -lt $min_memory_mb ]; then
        log_warn "系统内存不足: $total_memory_mb MB, 建议至少: $min_memory_mb MB"
        return 1
    fi
    
    return 0
}

# 检查系统磁盘空间
check_disk_space() {
    local min_space_gb="$1"
    local mount_point="${2:-/}"
    local available_space_kb=$(df -k "$mount_point" | tail -1 | awk '{print $4}')
    local available_space_gb=$((available_space_kb / 1024 / 1024))
    
    if [ $available_space_gb -lt $min_space_gb ]; then
        log_warn "磁盘空间不足: $available_space_gb GB, 建议至少: $min_space_gb GB"
        return 1
    fi
    
    return 0
}

# 格式化文件大小
format_file_size() {
    local size_bytes="$1"
    
    if [ $size_bytes -lt 1024 ]; then
        echo "${size_bytes} B"
    elif [ $size_bytes -lt 1048576 ]; then
        echo "$((size_bytes / 1024)) KB"
    elif [ $size_bytes -lt 1073741824 ]; then
        echo "$((size_bytes / 1048576)) MB"
    else
        echo "$((size_bytes / 1073741824)) GB"
    fi
}

# 显示进度条
display_progress() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    local progress=$((current * 100 / total))
    local filled=$((progress * width / 100))
    local empty=$((width - filled))
    
    local bar="[""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    bar+"]"
    
    echo -ne "\r${bar} ${progress}% (${current}/${total})"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}
