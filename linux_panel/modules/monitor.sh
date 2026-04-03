#!/bin/bash

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
    echo -e "${GREEN}公网IP:${NC} $(get_public_ip)"
    echo -e "${GREEN}内网IP:${NC} $(get_primary_ip)"
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
        # 将浮点数转换为整数（去掉小数点）
        local cpu_usage_int=$(echo "$cpu_usage" | awk -F. '{print $1}')
        local filled=$((cpu_usage_int / 5))
        for ((i=0; i<20; i++)); do
            if [ $i -lt $filled ]; then
                cpu_bar+="█"
            else
                cpu_bar+="░"
            fi
        done
        cpu_bar+"]"
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
        mem_bar+"]"
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
            disk_bar+"]"
            
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
