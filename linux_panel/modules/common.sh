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

# 菜单超时设置（秒）
MENU_TIMEOUT=60

# 通用工具函数
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

pause() {
    read -p "${1:-按回车键继续...}"
}

read_menu_choice() {
    local prompt="$1"
    local var_name="$2"
    local timeout="${3:-$MENU_TIMEOUT}"

    if read -t "$timeout" -p "$prompt" "$var_name"; then
        return 0
    fi

    echo -e "\n${YELLOW}操作超时，返回上一级...${NC}"
    return 1
}

# 显示标题
show_title() {
    local title="$1"
    local border="========================================"
    
    clear
    echo -e "${PURPLE}$border${NC}"
    echo -e "${PURPLE}          $title${NC}"
    echo -e "${PURPLE}$border${NC}"
    echo ""
}

# 显示子标题
show_subtitle() {
    local subtitle="$1"
    echo -e "${CYAN}=== $subtitle ===${NC}"
}

# 显示菜单选项
show_menu_option() {
    local number="$1"
    local text="$2"
    echo -e "${GREEN}$number.${NC} $text"
}

# 显示分割线
show_divider() {
    echo -e "${YELLOW}========================================${NC}"
}

# 显示加载动画
show_loading() {
    local message="$1"
    local duration="${2:-3}"
    local interval="0.2"
    local frames=('|' '/' '-' '\\')
    
    echo -n "${CYAN}$message "
    
    local end_time=$(( $(date +%s) + duration ))
    local i=0
    
    while [ $(date +%s) -lt $end_time ]; do
        echo -ne "\r${CYAN}$message ${frames[$i % ${#frames[@]}]}"
        i=$((i + 1))
        sleep $interval
    done
    
    echo -ne "\r${GREEN}$message ✓${NC}\n"
}

# 显示成功消息
show_success() {
    local message="$1"
    echo -e "${GREEN}✓ $message${NC}"
}

# 显示错误消息
show_error() {
    local message="$1"
    echo -e "${RED}✗ $message${NC}"
}

# 显示警告消息
show_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠ $message${NC}"
}

# 显示信息消息
show_info() {
    local message="$1"
    echo -e "${BLUE}ℹ $message${NC}"
}


# 错误处理函数
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    echo -e "${RED}错误: $message${NC}"
    exit $exit_code
}

warning_message() {
    local message="$1"
    echo -e "${YELLOW}警告: $message${NC}"
}

info_message() {
    local message="$1"
    echo -e "${CYAN}信息: $message${NC}"
}

success_message() {
    local message="$1"
    echo -e "${GREEN}成功: $message${NC}"
}

# 检查命令执行结果
check_command() {
    local command_result=$1
    local success_message="$2"
    local error_message="$3"
    local exit_on_error="${4:-true}"

    if [ $command_result -eq 0 ]; then
        if [ -n "$success_message" ]; then
            success_message "$success_message"
        fi
        return 0
    else
        if [ -n "$error_message" ]; then
            echo -e "${RED}错误: $error_message${NC}"
        fi
        if [ "$exit_on_error" = "true" ]; then
            exit 1
        fi
        return 1
    fi
}

# 检查目录是否存在，不存在则创建
ensure_directory() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        check_command $? "创建目录 $dir_path 成功" "创建目录 $dir_path 失败"
    fi
}

# 检查文件是否存在
check_file_exists() {
    local file_path="$1"
    local error_message="$2"
    if [ ! -f "$file_path" ]; then
        error_exit "$error_message" 1
    fi
}

# 安全地读取密码
read_password() {
    local var_name="$1"
    local prompt="${2:-请输入密码: }"
    
    if [ -t 0 ]; then
        # 在终端中运行，使用密码输入模式
        read -s -p "$prompt" $var_name
        echo ""
    else
        # 非终端环境，使用普通输入
        read -p "$prompt" $var_name
    fi
}

# 设置文件安全权限
set_secure_permissions() {
    local file_path="$1"
    local permissions="${2:-600}"
    chmod $permissions "$file_path"
    check_command $? "设置文件权限 $permissions 成功: $file_path" "设置文件权限失败: $file_path"
}

# 检查文件权限是否安全
check_secure_permissions() {
    local file_path="$1"
    local min_permissions="${2:-600}"
    
    if [ -f "$file_path" ]; then
        local current_permissions=$(stat -c "%a" "$file_path")
        if [ $current_permissions -gt $min_permissions ]; then
            warning_message "文件权限不安全: $file_path (当前权限: $current_permissions, 建议: $min_permissions)"
            return 1
        fi
    fi
    return 0
}

# 清理临时文件
cleanup_temp_files() {
    local temp_files=($@)
    for file in "${temp_files[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
        fi
    done
}

# 日志相关配置
LOG_DIR="/var/log/linux_panel"
LOG_FILE="$LOG_DIR/installer.log"
LOG_LEVEL="info"  # debug, info, warn, error

# 初始化日志目录
init_log_dir() {
    ensure_directory "$LOG_DIR"
    touch "$LOG_FILE"
    set_secure_permissions "$LOG_FILE" 640
}

# 记录日志
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "%Y-%m-%d %H:%M:%S")
    
    # 检查日志级别
    case $LOG_LEVEL in
        "debug")
            if [[ "$level" =~ ^(debug|info|warn|error)$ ]]; then
                echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
            fi
            ;;
        "info")
            if [[ "$level" =~ ^(info|warn|error)$ ]]; then
                echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
            fi
            ;;
        "warn")
            if [[ "$level" =~ ^(warn|error)$ ]]; then
                echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
            fi
            ;;
        "error")
            if [[ "$level" == "error" ]]; then
                echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
            fi
            ;;
    esac
    
    # 同时输出到终端
    case $level in
        "debug")
            echo -e "${BLUE}[$timestamp] [$level] $message${NC}"
            ;;
        "info")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}"
            ;;
        "warn")
            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}"
            ;;
        "error")
            echo -e "${RED}[$timestamp] [$level] $message${NC}"
            ;;
    esac
}

# 不同级别的日志函数
log_debug() {
    log_message "debug" "$1"
}

log_info() {
    log_message "info" "$1"
}

log_warn() {
    log_message "warn" "$1"
}

log_error() {
    log_message "error" "$1"
}

# 日志轮转
rotate_logs() {
    local max_size=10485760  # 10MB
    local max_files=5
    
    if [ -f "$LOG_FILE" ]; then
        local file_size=$(stat -c "%s" "$LOG_FILE")
        if [ $file_size -ge $max_size ]; then
            # 轮转日志文件
            for ((i=$max_files-1; i>0; i--)); do
                if [ -f "$LOG_FILE.$i" ]; then
                    mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
                fi
            done
            mv "$LOG_FILE" "$LOG_FILE.1"
            touch "$LOG_FILE"
            set_secure_permissions "$LOG_FILE" 640
            log_info "日志文件已轮转"
        fi
    fi
}

# 查看日志
view_logs() {
    local lines="${1:-50}"
    if [ -f "$LOG_FILE" ]; then
        tail -n $lines "$LOG_FILE"
    else
        echo "日志文件不存在: $LOG_FILE"
    fi
}




get_primary_ip() {
    local ip
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "$ip" ]; then
        echo "$ip"
        return
    fi
    ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
    if [ -n "$ip" ]; then
        echo "$ip"
        return
    fi
    ip=$(ip -4 addr show scope global 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
    echo "${ip:-无法获取}"
}

get_public_ip() {
    local urls=(
        "https://api.ipify.org"
        "https://ifconfig.me/ip"
        "https://ipv4.icanhazip.com"
    )
    local url
    for url in "${urls[@]}"; do
        if command_exists curl; then
            local ip
            ip=$(curl -fsSL --connect-timeout 5 "$url" 2>/dev/null | tr -d '\r')
            if [ -n "$ip" ]; then
                echo "$ip"
                return
            fi
        elif command_exists wget; then
            local ip
            ip=$(wget -qO- "$url" 2>/dev/null | tr -d '\r')
            if [ -n "$ip" ]; then
                echo "$ip"
                return
            fi
        fi
    done
    echo "无法获取"
}

download_file() {
    local url="$1"
    local dest="$2"

    if command_exists curl; then
        curl -fsSL --retry 3 --connect-timeout 10 "$url" -o "$dest"
        local result=$?
        check_command $result "下载文件成功: $url" "下载文件失败: $url" false
        return $result
    fi
    if command_exists wget; then
        wget -qO "$dest" "$url"
        local result=$?
        check_command $result "下载文件成功: $url" "下载文件失败: $url" false
        return $result
    fi

    echo -e "${RED}错误: 缺少下载工具: curl 或 wget${NC}"
    return 1
}

ensure_download_tool() {
    if command_exists curl || command_exists wget; then
        return 0
    fi

    echo -e "${YELLOW}未检测到 curl/wget，尝试安装...${NC}"
    case $DISTRO in
        "centos"|"rhel"|"fedora")
            yum install -y curl wget
            ;;
        "ubuntu"|"debian")
            apt update && apt install -y curl wget
            ;;
        *)
            echo -e "${RED}无法自动安装下载工具，请手动安装 curl 或 wget${NC}"
            return 1
            ;;
    esac

    if command_exists curl || command_exists wget; then
        return 0
    fi

    echo -e "${RED}下载工具安装失败，请检查网络或包管理器${NC}"
    return 1
}

get_docker_compose_cmd() {
    if command_exists docker-compose; then
        echo "docker-compose"
        return
    fi
    if command_exists docker && docker compose version >/dev/null 2>&1; then
        echo "docker compose"
        return
    fi
    echo "docker-compose"
}

docker_compose() {
    if command_exists docker-compose; then
        docker-compose "$@"
        return $?
    fi
    if command_exists docker && docker compose version >/dev/null 2>&1; then
        docker compose "$@"
        return $?
    fi
    echo -e "${RED}Docker Compose 未安装或不可用${NC}"
    return 1
}

backup_file_if_exists() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local backup_path="${file_path}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file_path" "$backup_path"
        echo -e "${YELLOW}已备份: $backup_path${NC}"
    fi
}

update_docker_daemon_json() {
    local mirror_url="$1"
    local config_file="/etc/docker/daemon.json"

    mkdir -p /etc/docker
    backup_file_if_exists "$config_file"

    if command_exists python3; then
        MIRROR_URL="$mirror_url" python3 - << 'PY'
import json
import os
import sys

config_file = "/etc/docker/daemon.json"
mirror_url = os.environ.get("MIRROR_URL", "")

data = {}
if os.path.exists(config_file):
    try:
        with open(config_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        data = {}

if mirror_url:
    data["registry-mirrors"] = [mirror_url]
else:
    data.pop("registry-mirrors", None)

with open(config_file, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
PY
        return $?
    fi

    if [ -z "$mirror_url" ]; then
        cat > "$config_file" << 'EOF'
{}
EOF
        return 0
    fi

    cat > "$config_file" << EOF
{
  "registry-mirrors": ["$mirror_url"]
}
EOF
    return 0
}

init_cron_env() {
    mkdir -p "$CRON_TASK_DIR" "$CRON_LOG_DIR"
    touch "$CRON_TASK_REGISTRY"
    chmod 600 "$CRON_TASK_REGISTRY"
    if [ ! -f "$CRON_TASK_FILE" ]; then
        cat > "$CRON_TASK_FILE" << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF
    fi
}

render_cron_file() {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF

    while IFS='|' read -r task_id task_desc task_schedule task_cmd task_status; do
        [ -z "$task_id" ] && continue
        if [ "$task_status" = "disabled" ]; then
            echo "# $task_schedule root $task_cmd >> $CRON_LOG_DIR/$task_id.log 2>&1" >> "$temp_file"
        else
            echo "$task_schedule root $task_cmd >> $CRON_LOG_DIR/$task_id.log 2>&1" >> "$temp_file"
        fi
    done < "$CRON_TASK_REGISTRY"

    cp "$temp_file" "$CRON_TASK_FILE"
    rm -f "$temp_file"
}

add_task_registry() {
    local task_id="$1"
    local task_desc="$2"
    local task_schedule="$3"
    local task_cmd="$4"
    local task_status="$5"

    echo "$task_id|$task_desc|$task_schedule|$task_cmd|$task_status" >> "$CRON_TASK_REGISTRY"
}

update_task_status() {
    local task_id="$1"
    local new_status="$2"
    local temp_file
    temp_file=$(mktemp)

    while IFS='|' read -r id desc schedule cmd status; do
        [ -z "$id" ] && continue
        if [ "$id" = "$task_id" ]; then
            echo "$id|$desc|$schedule|$cmd|$new_status" >> "$temp_file"
        else
            echo "$id|$desc|$schedule|$cmd|$status" >> "$temp_file"
        fi
    done < "$CRON_TASK_REGISTRY"

    cp "$temp_file" "$CRON_TASK_REGISTRY"
    rm -f "$temp_file"
}

remove_task_registry() {
    local task_id="$1"
    local temp_file
    temp_file=$(mktemp)

    while IFS='|' read -r id desc schedule cmd status; do
        [ -z "$id" ] && continue
        if [ "$id" != "$task_id" ]; then
            echo "$id|$desc|$schedule|$cmd|$status" >> "$temp_file"
        fi
    done < "$CRON_TASK_REGISTRY"

    cp "$temp_file" "$CRON_TASK_REGISTRY"
    rm -f "$temp_file"
}

validate_cron_expr() {
    local expr="$1"
    if [[ "$expr" =~ ^([^[:space:]]+[[:space:]]+){4}[^[:space:]]+$ ]]; then
        return 0
    fi
    return 1
}

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
