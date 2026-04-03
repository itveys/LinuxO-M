#!/bin/bash

# 项目守护功能模块
# 包含项目状态检测、HTTP/HTTPS链接健康检测和钉钉推送功能

# 项目配置文件
PROJECT_CONFIG_FILE="/etc/linux_panel/project_config.json"
# 项目状态文件
PROJECT_STATUS_FILE="/var/log/linux_panel/project_status.json"
# 守护日志文件
DAEMON_LOG_FILE="/var/log/linux_panel/daemon.log"

# 初始化项目配置
init_project_config() {
    ensure_directory "$(dirname "$PROJECT_CONFIG_FILE")"
    if [ ! -f "$PROJECT_CONFIG_FILE" ]; then
        cat > "$PROJECT_CONFIG_FILE" << 'EOF'
{
  "projects": [],
  "check_interval": 60,
  "dingtalk": {
    "enabled": false,
    "webhook": "",
    "secret": ""
  }
}
EOF
        set_secure_permissions "$PROJECT_CONFIG_FILE" 600
        log_info "初始化项目配置文件: $PROJECT_CONFIG_FILE"
    fi
}

# 初始化项目状态文件
init_project_status() {
    ensure_directory "$(dirname "$PROJECT_STATUS_FILE")"
    if [ ! -f "$PROJECT_STATUS_FILE" ]; then
        cat > "$PROJECT_STATUS_FILE" << 'EOF'
{
  "status": {}
}
EOF
        set_secure_permissions "$PROJECT_STATUS_FILE" 600
        log_info "初始化项目状态文件: $PROJECT_STATUS_FILE"
    fi
}

# 显示项目守护菜单
project_daemon_menu() {
    while true; do
        show_title "项目守护功能"
        
        echo -e "${CYAN}当前项目列表:${NC}"
        list_projects
        echo ""
        
        show_menu_option "1" "添加项目"
        show_menu_option "2" "删除项目"
        show_menu_option "3" "修改项目"
        show_menu_option "4" "查看项目状态"
        show_menu_option "5" "配置钉钉推送"
        show_menu_option "6" "启动守护服务"
        show_menu_option "7" "停止守护服务"
        show_menu_option "0" "返回主菜单"
        echo ""
        show_divider
        echo ""
        
        read -p "请选择 (0-7): " daemon_choice
        
        case $daemon_choice in
            1)
                add_project
                ;;
            2)
                delete_project
                ;;
            3)
                modify_project
                ;;
            4)
                view_project_status
                ;;
            5)
                configure_dingtalk
                ;;
            6)
                start_daemon_service
                ;;
            7)
                stop_daemon_service
                ;;
            0)
                return
                ;;
            *)
                show_error "无效的选择，请重新输入"
                sleep 2
                ;;
        esac
    done
}

# 列出所有项目
list_projects() {
    if [ ! -f "$PROJECT_CONFIG_FILE" ]; then
        echo -e "${YELLOW}项目配置文件不存在${NC}"
        return
    fi
    
    local projects
    if command_exists python3; then
        projects=$(python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/project_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    projects = data.get('projects', [])
    if not projects:
        print("无项目配置")
    else:
        for i, project in enumerate(projects, 1):
            name = project.get('name', '未命名')
            url = project.get('url', '无URL')
            status = project.get('status', 'unknown')
            print(f"{i}. {name} - {url} - 状态: {status}")
else:
    print("配置文件不存在")
PY
        )
        echo "$projects"
    else:
        echo -e "${YELLOW}需要Python 3来解析配置文件${NC}"
    fi
}

# 添加项目
add_project() {
    show_title "添加项目"
    
    read -p "请输入项目名称: " project_name
    read -p "请输入项目URL (http/https): " project_url
    read -p "请输入检查间隔 (秒，默认60): " check_interval
    check_interval=${check_interval:-60}
    
    if [ -z "$project_name" ] || [ -z "$project_url" ]; then
        show_error "项目名称和URL不能为空"
        pause
        return
    fi
    
    if command_exists python3; then
        PROJECT_NAME="$project_name" PROJECT_URL="$project_url" CHECK_INTERVAL="$check_interval" python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/project_config.json"

# 读取现有配置
if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
else:
    data = {"projects": [], "check_interval": 60}

# 添加新项目
new_project = {
    "name": os.environ.get("PROJECT_NAME"),
    "url": os.environ.get("PROJECT_URL"),
    "check_interval": int(os.environ.get("CHECK_INTERVAL", 60)),
    "status": "unknown"
}

data["projects"].append(new_project)

# 保存配置
with open(config_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("项目添加成功")
PY
        show_success "项目添加成功"
    else:
        show_error "需要Python 3来修改配置文件"
    fi
    
    pause
}

# 删除项目
delete_project() {
    show_title "删除项目"
    
    list_projects
    echo ""
    read -p "请输入要删除的项目编号: " project_index
    
    if command_exists python3; then
        PROJECT_INDEX="$project_index" python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/project_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    projects = data.get('projects', [])
    index = int(os.environ.get("PROJECT_INDEX", 0)) - 1
    
    if 0 <= index < len(projects):
        deleted_project = projects.pop(index)
        print(f"删除项目: {deleted_project.get('name')}")
        
        # 保存配置
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print("项目删除成功")
    else:
        print("无效的项目编号")
else:
    print("配置文件不存在")
PY
    else:
        show_error "需要Python 3来修改配置文件"
    fi
    
    pause
}

# 修改项目
modify_project() {
    show_title "修改项目"
    
    list_projects
    echo ""
    read -p "请输入要修改的项目编号: " project_index
    
    if command_exists python3; then
        PROJECT_INDEX="$project_index" python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/project_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    projects = data.get('projects', [])
    index = int(os.environ.get("PROJECT_INDEX", 0)) - 1
    
    if 0 <= index < len(projects):
        project = projects[index]
        print(f"当前项目: {project.get('name')}")
        print(f"当前URL: {project.get('url')}")
        print(f"当前检查间隔: {project.get('check_interval')}秒")
        
        # 读取新值
        new_name = input("请输入新的项目名称 (回车保持不变): ")
        new_url = input("请输入新的项目URL (回车保持不变): ")
        new_interval = input("请输入新的检查间隔 (回车保持不变): ")
        
        # 更新项目信息
        if new_name:
            project['name'] = new_name
        if new_url:
            project['url'] = new_url
        if new_interval:
            project['check_interval'] = int(new_interval)
        
        # 保存配置
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print("项目修改成功")
    else:
        print("无效的项目编号")
else:
    print("配置文件不存在")
PY
    else:
        show_error "需要Python 3来修改配置文件"
    fi
    
    pause
}

# 查看项目状态
view_project_status() {
    show_title "项目状态"
    
    if [ ! -f "$PROJECT_STATUS_FILE" ]; then
        show_error "项目状态文件不存在"
        pause
        return
    fi
    
    if command_exists python3; then
        python3 - << 'PY'
import json
import os

status_file = "/var/log/linux_panel/project_status.json"

if os.path.exists(status_file):
    with open(status_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    status = data.get('status', {})
    if not status:
        print("无项目状态信息")
    else:
        for project_name, project_status in status.items():
            print(f"项目: {project_name}")
            print(f"  状态: {project_status.get('status', 'unknown')}")
            print(f"  响应时间: {project_status.get('response_time', 'N/A')}ms")
            print(f"  最后检查: {project_status.get('last_check', 'N/A')}")
            print(f"  错误信息: {project_status.get('error', '无')}")
            print()
else:
    print("状态文件不存在")
PY
    else:
        show_error "需要Python 3来解析状态文件"
    fi
    
    pause
}

# 配置钉钉推送
configure_dingtalk() {
    show_title "配置钉钉推送"
    
    read -p "是否启用钉钉推送? (y/n): " enable_dingtalk
    
    if [[ $enable_dingtalk =~ ^[Yy]$ ]]; then
        read -p "请输入钉钉机器人Webhook: " webhook
        read -p "请输入钉钉机器人密钥 (可选): " secret
        
        if command_exists python3; then
            WEBHOOK="$webhook" SECRET="$secret" python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/project_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
else:
    data = {"projects": [], "check_interval": 60}

# 更新钉钉配置
data["dingtalk"] = {
    "enabled": True,
    "webhook": os.environ.get("WEBHOOK"),
    "secret": os.environ.get("SECRET")
}

# 保存配置
with open(config_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("钉钉推送配置成功")
PY
            show_success "钉钉推送配置成功"
        else:
            show_error "需要Python 3来修改配置文件"
    else:
        if command_exists python3; then
            python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/project_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
else:
    data = {"projects": [], "check_interval": 60}

# 禁用钉钉配置
data["dingtalk"] = {
    "enabled": False,
    "webhook": "",
    "secret": ""
}

# 保存配置
with open(config_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("钉钉推送已禁用")
PY
            show_success "钉钉推送已禁用"
        else:
            show_error "需要Python 3来修改配置文件"
    fi
    
    pause
}

# 发送钉钉消息
send_dingtalk_message() {
    local message="$1"
    local title="$2"
    
    if command_exists python3; then
        MESSAGE="$message" TITLE="$title" python3 - << 'PY'
import json
import os
import time
import hmac
import hashlib
import base64
import urllib.parse
import requests

config_file = "/etc/linux_panel/project_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    dingtalk = data.get('dingtalk', {})
    enabled = dingtalk.get('enabled', False)
    webhook = dingtalk.get('webhook', '')
    secret = dingtalk.get('secret', '')
    
    if enabled and webhook:
        # 生成签名
        timestamp = str(round(time.time() * 1000))
        secret_enc = secret.encode('utf-8')
        string_to_sign = '{}\n{}'.format(timestamp, secret)
        string_to_sign_enc = string_to_sign.encode('utf-8')
        hmac_code = hmac.new(secret_enc, string_to_sign_enc, digestmod=hashlib.sha256).digest()
        sign = urllib.parse.quote_plus(base64.b64encode(hmac_code))
        
        # 构建URL
        url = f"{webhook}&timestamp={timestamp}&sign={sign}"
        
        # 构建消息
        msg = {
            "msgtype": "markdown",
            "markdown": {
                "title": os.environ.get("TITLE", "项目状态通知"),
                "text": os.environ.get("MESSAGE", "")
            }
        }
        
        # 发送请求
        try:
            response = requests.post(url, json=msg, timeout=10)
            if response.status_code == 200:
                print("钉钉消息发送成功")
            else:
                print(f"钉钉消息发送失败: {response.text}")
        except Exception as e:
            print(f"发送钉钉消息时出错: {e}")
    else:
        print("钉钉推送未启用或配置不完整")
else:
    print("配置文件不存在")
PY
    else:
        show_error "需要Python 3来发送钉钉消息"
}

# 检查项目状态
check_project_status() {
    local project_name="$1"
    local project_url="$2"
    
    local start_time=$(date +%s%3N)
    local status="unknown"
    local response_time="N/A"
    local error=""
    
    # 检查URL
    if command_exists curl; then
        local result=$(curl -fsSL --connect-timeout 10 -w "%{http_code}" "$project_url" -o /dev/null 2>&1)
        local http_code=${result: -3}
        local curl_error=${result%???}
        
        if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ]; then
            status="healthy"
        else
            status="unhealthy"
            error="HTTP状态码: $http_code"
            if [ -n "$curl_error" ]; then
                error="$error, 错误: $curl_error"
            fi
        fi
    elif command_exists wget; then
        local result=$(wget -q --timeout=10 --spider "$project_url" 2>&1)
        if [ $? -eq 0 ]; then
            status="healthy"
        else
            status="unhealthy"
            error="$result"
        fi
    else
        status="unknown"
        error="缺少curl或wget工具"
    fi
    
    # 计算响应时间
    local end_time=$(date +%s%3N)
    response_time=$((end_time - start_time))
    
    # 更新状态文件
    if command_exists python3; then
        PROJECT_NAME="$project_name" STATUS="$status" RESPONSE_TIME="$response_time" ERROR="$error" python3 - << 'PY'
import json
import os
from datetime import datetime

status_file = "/var/log/linux_panel/project_status.json"

# 读取现有状态
if os.path.exists(status_file):
    with open(status_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
else:
    data = {"status": {}}

# 更新项目状态
project_name = os.environ.get("PROJECT_NAME")
data["status"][project_name] = {
    "status": os.environ.get("STATUS"),
    "response_time": os.environ.get("RESPONSE_TIME"),
    "last_check": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    "error": os.environ.get("ERROR")
}

# 保存状态
with open(status_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
PY
    fi
    
    # 检查是否需要发送通知
    if [ "$status" = "unhealthy" ]; then
        local message="## 项目异常通知\n\n- **项目名称**: $project_name\n- **项目URL**: $project_url\n- **状态**: 异常\n- **响应时间**: ${response_time}ms\n- **错误信息**: $error\n- **检查时间**: $(date '+%Y-%m-%d %H:%M:%S')"
        send_dingtalk_message "$message" "项目异常通知"
    fi
    
    echo "$status"
}

# 守护服务主循环
daemon_main() {
    init_project_config
    init_project_status
    
    log_info "项目守护服务启动"
    
    while true; do
        if [ -f "$PROJECT_CONFIG_FILE" ]; then
            if command_exists python3; then
                python3 - << 'PY'
import json
import os
import subprocess

config_file = "/etc/linux_panel/project_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    projects = data.get('projects', [])
    for project in projects:
        name = project.get('name')
        url = project.get('url')
        if name and url:
            # 调用检查函数
            subprocess.run(['bash', '-c', f'source /workspace/linux_panel/modules/daemon.sh && check_project_status "{name}" "{url}"'], 
                         capture_output=True, text=True)
PY
            
            # 检查间隔
            sleep 60
        else
            sleep 60
        fi
    else
        sleep 60
    fi
    done
}

# 启动守护服务
start_daemon_service() {
    show_title "启动守护服务"
    
    # 检查是否已在运行
    if pgrep -f "daemon_main" >/dev/null; then
        show_warning "守护服务已经在运行"
        pause
        return
    fi
    
    # 启动守护服务
    nohup bash -c "source /workspace/linux_panel/modules/daemon.sh && daemon_main" > "$DAEMON_LOG_FILE" 2>&1 &
    
    show_loading "启动守护服务"
    sleep 2
    
    if pgrep -f "daemon_main" >/dev/null; then
        show_success "守护服务启动成功"
        show_info "守护日志: $DAEMON_LOG_FILE"
    else
        show_error "守护服务启动失败"
    fi
    
    pause
}

# 停止守护服务
stop_daemon_service() {
    show_title "停止守护服务"
    
    # 查找并终止守护进程
    local pid=$(pgrep -f "daemon_main")
    if [ -n "$pid" ]; then
        kill $pid
        show_loading "停止守护服务"
        sleep 2
        
        if ! pgrep -f "daemon_main" >/dev/null; then
            show_success "守护服务停止成功"
        else
            show_error "守护服务停止失败"
        fi
    else
        show_warning "守护服务未在运行"
    fi
    
    pause
}
