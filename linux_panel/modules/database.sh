#!/bin/bash

# 数据库功能模块
# 包含数据库性能检测和备份功能

# 数据库配置文件
DB_CONFIG_FILE="/etc/linux_panel/database_config.json"
# 数据库备份目录
DB_BACKUP_DIR="/opt/linux_panel/backup"
# 数据库性能日志
DB_PERF_LOG="/var/log/linux_panel/database_perf.log"

# 初始化数据库配置
init_db_config() {
    ensure_directory "$(dirname "$DB_CONFIG_FILE")"
    if [ ! -f "$DB_CONFIG_FILE" ]; then
        cat > "$DB_CONFIG_FILE" << 'EOF'
{
  "databases": [],
  "backup": {
    "enabled": false,
    "schedule": "0 0 * * *",
    "retention": 7,
    "dir": "/opt/linux_panel/backup"
  }
}
EOF
        set_secure_permissions "$DB_CONFIG_FILE" 600
        log_info "初始化数据库配置文件: $DB_CONFIG_FILE"
    fi
}

# 初始化备份目录
init_backup_dir() {
    ensure_directory "$DB_BACKUP_DIR"
    set_secure_permissions "$DB_BACKUP_DIR" 700
}

# 显示数据库管理菜单
database_menu() {
    while true; do
        show_title "数据库管理"
        
        echo -e "${CYAN}当前数据库列表:${NC}"
        list_databases
        echo ""
        
        show_menu_option "1" "添加数据库"
        show_menu_option "2" "删除数据库"
        show_menu_option "3" "修改数据库"
        show_menu_option "4" "数据库性能检测"
        show_menu_option "5" "数据库备份"
        show_menu_option "6" "配置备份计划"
        show_menu_option "7" "查看备份历史"
        show_menu_option "0" "返回主菜单"
        echo ""
        show_divider
        echo ""
        
        read -p "请选择 (0-7): " db_choice
        
        case $db_choice in
            1)
                add_database
                ;;
            2)
                delete_database
                ;;
            3)
                modify_database
                ;;
            4)
                database_performance_check
                ;;
            5)
                backup_database
                ;;
            6)
                configure_backup
                ;;
            7)
                view_backup_history
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

# 列出所有数据库
list_databases() {
    if [ ! -f "$DB_CONFIG_FILE" ]; then
        echo -e "${YELLOW}数据库配置文件不存在${NC}"
        return
    fi
    
    local databases
    if command_exists python3; then
        databases=$(python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/database_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    databases = data.get('databases', [])
    if not databases:
        print("无数据库配置")
    else:
        for i, db in enumerate(databases, 1):
            name = db.get('name', '未命名')
            type = db.get('type', '未知类型')
            host = db.get('host', 'localhost')
            port = db.get('port', '默认端口')
            print(f"{i}. {name} - {type} - {host}:{port}")
else:
    print("配置文件不存在")
PY
        )
        echo "$databases"
    else:
        echo -e "${YELLOW}需要Python 3来解析配置文件${NC}"
    fi
}

# 添加数据库
add_database() {
    show_title "添加数据库"
    
    read -p "请输入数据库名称: " db_name
    read -p "请输入数据库类型 (mysql/postgresql/oracle/redis): " db_type
    read -p "请输入数据库主机 (默认localhost): " db_host
    db_host=${db_host:-localhost}
    read -p "请输入数据库端口 (默认根据类型): " db_port
    read -p "请输入数据库用户名: " db_user
    read_password "db_pass" "请输入数据库密码: "
    
    if [ -z "$db_name" ] || [ -z "$db_type" ] || [ -z "$db_user" ] || [ -z "$db_pass" ]; then
        show_error "数据库名称、类型、用户名和密码不能为空"
        pause
        return
    fi
    
    # 设置默认端口
    case $db_type in
        "mysql")
            db_port=${db_port:-3306}
            ;;
        "postgresql")
            db_port=${db_port:-5432}
            ;;
        "oracle")
            db_port=${db_port:-1521}
            ;;
        "redis")
            db_port=${db_port:-6379}
            ;;
        *)
            show_error "不支持的数据库类型"
            pause
            return
            ;;
    esac
    
    if command_exists python3; then
        DB_NAME="$db_name" DB_TYPE="$db_type" DB_HOST="$db_host" DB_PORT="$db_port" DB_USER="$db_user" DB_PASS="$db_pass" python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/database_config.json"

# 读取现有配置
if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
else:
    data = {"databases": [], "backup": {"enabled": false, "schedule": "0 0 * * *", "retention": 7, "dir": "/opt/linux_panel/backup"}}

# 添加新数据库
new_db = {
    "name": os.environ.get("DB_NAME"),
    "type": os.environ.get("DB_TYPE"),
    "host": os.environ.get("DB_HOST"),
    "port": os.environ.get("DB_PORT"),
    "user": os.environ.get("DB_USER"),
    "pass": os.environ.get("DB_PASS")
}

data["databases"].append(new_db)

# 保存配置
with open(config_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("数据库添加成功")
PY
        show_success "数据库添加成功"
    else:
        show_error "需要Python 3来修改配置文件"
    fi
    
    pause
}

# 删除数据库
delete_database() {
    show_title "删除数据库"
    
    list_databases
    echo ""
    read -p "请输入要删除的数据库编号: " db_index
    
    if command_exists python3; then
        DB_INDEX="$db_index" python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/database_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    databases = data.get('databases', [])
    index = int(os.environ.get("DB_INDEX", 0)) - 1
    
    if 0 <= index < len(databases):
        deleted_db = databases.pop(index)
        print(f"删除数据库: {deleted_db.get('name')}")
        
        # 保存配置
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print("数据库删除成功")
    else:
        print("无效的数据库编号")
else:
    print("配置文件不存在")
PY
    else:
        show_error "需要Python 3来修改配置文件"
    fi
    
    pause
}

# 修改数据库
modify_database() {
    show_title "修改数据库"
    
    list_databases
    echo ""
    read -p "请输入要修改的数据库编号: " db_index
    
    if command_exists python3; then
        DB_INDEX="$db_index" python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/database_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    databases = data.get('databases', [])
    index = int(os.environ.get("DB_INDEX", 0)) - 1
    
    if 0 <= index < len(databases):
        db = databases[index]
        print(f"当前数据库: {db.get('name')}")
        print(f"当前类型: {db.get('type')}")
        print(f"当前主机: {db.get('host')}")
        print(f"当前端口: {db.get('port')}")
        print(f"当前用户名: {db.get('user')}")
        
        # 读取新值
        new_name = input("请输入新的数据库名称 (回车保持不变): ")
        new_type = input("请输入新的数据库类型 (回车保持不变): ")
        new_host = input("请输入新的数据库主机 (回车保持不变): ")
        new_port = input("请输入新的数据库端口 (回车保持不变): ")
        new_user = input("请输入新的数据库用户名 (回车保持不变): ")
        new_pass = input("请输入新的数据库密码 (回车保持不变): ")
        
        # 更新数据库信息
        if new_name:
            db['name'] = new_name
        if new_type:
            db['type'] = new_type
        if new_host:
            db['host'] = new_host
        if new_port:
            db['port'] = new_port
        if new_user:
            db['user'] = new_user
        if new_pass:
            db['pass'] = new_pass
        
        # 保存配置
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print("数据库修改成功")
    else:
        print("无效的数据库编号")
else:
    print("配置文件不存在")
PY
    else:
        show_error "需要Python 3来修改配置文件"
    fi
    
    pause
}

# 数据库性能检测
database_performance_check() {
    show_title "数据库性能检测"
    
    list_databases
    echo ""
    read -p "请输入要检测的数据库编号: " db_index
    
    if command_exists python3; then
        DB_INDEX="$db_index" python3 - << 'PY'
import json
import os
import subprocess

config_file = "/etc/linux_panel/database_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    databases = data.get('databases', [])
    index = int(os.environ.get("DB_INDEX", 0)) - 1
    
    if 0 <= index < len(databases):
        db = databases[index]
        name = db.get('name')
        type = db.get('type')
        host = db.get('host')
        port = db.get('port')
        user = db.get('user')
        password = db.get('pass')
        
        print(f"开始检测数据库: {name}")
        print(f"类型: {type}")
        print(f"主机: {host}:{port}")
        print()
        
        # 根据数据库类型执行不同的检测
        if type == 'mysql':
            # 连接测试
            print('1. 连接测试...')
            cmd = f"mysql -h {host} -P {port} -u {user} -p{password} -e 'SELECT 1;' 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print('   ✓ 连接成功')
            else:
                print(f"   ✗ 连接失败: {result.stderr}")
            
            # 状态检测
            print('2. 状态检测...')
            cmd = f"mysql -h {host} -P {port} -u {user} -p{password} -e 'SHOW GLOBAL STATUS;' 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print('   ✓ 状态获取成功')
                # 提取关键指标
                uptime = subprocess.run(f"mysql -h {host} -P {port} -u {user} -p{password} -e 'SHOW GLOBAL STATUS LIKE \"Uptime\";' 2>&1", shell=True, capture_output=True, text=True).stdout
                connections = subprocess.run(f"mysql -h {host} -P {port} -u {user} -p{password} -e 'SHOW GLOBAL STATUS LIKE \"Connections\";' 2>&1", shell=True, capture_output=True, text=True).stdout
                slow_queries = subprocess.run(f"mysql -h {host} -P {port} -u {user} -p{password} -e 'SHOW GLOBAL STATUS LIKE \"Slow_queries\";' 2>&1", shell=True, capture_output=True, text=True).stdout
                print(f"   运行时间: {uptime.strip()}")
                print(f"   连接数: {connections.strip()}")
                print(f"   慢查询: {slow_queries.strip()}")
            else:
                print(f"   ✗ 状态获取失败: {result.stderr}")
            
            # 性能指标
            print('3. 性能指标...')
            cmd = f"mysql -h {host} -P {port} -u {user} -p{password} -e 'SHOW VARIABLES LIKE \"%buffer%\";' 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print('   ✓ 性能指标获取成功')
                print(result.stdout)
            else:
                print(f"   ✗ 性能指标获取失败: {result.stderr}")
            
        elif type == 'postgresql':
            # 连接测试
            print('1. 连接测试...')
            cmd = f"PGPASSWORD={password} psql -h {host} -p {port} -U {user} -c 'SELECT 1;' 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print('   ✓ 连接成功')
            else:
                print(f"   ✗ 连接失败: {result.stderr}")
            
            # 状态检测
            print('2. 状态检测...')
            cmd = f"PGPASSWORD={password} psql -h {host} -p {port} -U {user} -c 'SELECT * FROM pg_stat_database;' 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print('   ✓ 状态获取成功')
                print(result.stdout)
            else:
                print(f"   ✗ 状态获取失败: {result.stderr}")
            
        elif type == 'redis':
            # 连接测试
            print('1. 连接测试...')
            if password:
                cmd = f"redis-cli -h {host} -p {port} -a {password} ping 2>&1"
            else:
                cmd = f"redis-cli -h {host} -p {port} ping 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0 and 'PONG' in result.stdout:
                print('   ✓ 连接成功')
            else:
                print(f"   ✗ 连接失败: {result.stderr}")
            
            # 状态检测
            print('2. 状态检测...')
            if password:
                cmd = f"redis-cli -h {host} -p {port} -a {password} info 2>&1"
            else:
                cmd = f"redis-cli -h {host} -p {port} info 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print('   ✓ 状态获取成功')
                # 提取关键指标
                uptime = subprocess.run(cmd + " | grep uptime_in_seconds", shell=True, capture_output=True, text=True).stdout
                connected_clients = subprocess.run(cmd + " | grep connected_clients", shell=True, capture_output=True, text=True).stdout
                used_memory = subprocess.run(cmd + " | grep used_memory_human", shell=True, capture_output=True, text=True).stdout
                print(f"   运行时间: {uptime.strip()}")
                print(f"   连接客户端: {connected_clients.strip()}")
                print(f"   使用内存: {used_memory.strip()}")
            else:
                print(f"   ✗ 状态获取失败: {result.stderr}")
        else:
            print(f"不支持的数据库类型: {type}")
    else:
        print("无效的数据库编号")
else:
    print("配置文件不存在")
PY
    else:
        show_error "需要Python 3来执行数据库检测"
    fi
    
    pause
}

# 数据库备份
backup_database() {
    show_title "数据库备份"
    
    list_databases
    echo ""
    read -p "请输入要备份的数据库编号: " db_index
    
    init_backup_dir
    
    if command_exists python3; then
        DB_INDEX="$db_index" DB_BACKUP_DIR="$DB_BACKUP_DIR" python3 - << 'PY'
import json
import os
import subprocess
import datetime

config_file = "/etc/linux_panel/database_config.json"
backup_dir = os.environ.get("DB_BACKUP_DIR")

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    databases = data.get('databases', [])
    index = int(os.environ.get("DB_INDEX", 0)) - 1
    
    if 0 <= index < len(databases):
        db = databases[index]
        name = db.get('name')
        type = db.get('type')
        host = db.get('host')
        port = db.get('port')
        user = db.get('user')
        password = db.get('pass')
        
        # 创建备份目录
        backup_subdir = os.path.join(backup_dir, type, name)
        os.makedirs(backup_subdir, exist_ok=True)
        
        # 生成备份文件名
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = os.path.join(backup_subdir, f"{name}_{timestamp}.bak")
        
        print(f"开始备份数据库: {name}")
        print(f"备份文件: {backup_file}")
        print()
        
        # 根据数据库类型执行不同的备份
        if type == 'mysql':
            # MySQL备份
            cmd = f"mysqldump -h {host} -P {port} -u {user} -p{password} --all-databases > {backup_file} 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print('✓ MySQL备份成功')
                # 压缩备份文件
                gzip_cmd = f"gzip {backup_file} 2>&1"
                subprocess.run(gzip_cmd, shell=True)
                print('✓ 备份文件已压缩')
            else:
                print(f"✗ MySQL备份失败: {result.stderr}")
            
        elif type == 'postgresql':
            # PostgreSQL备份
            cmd = f"PGPASSWORD={password} pg_dumpall -h {host} -p {port} -U {user} > {backup_file} 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print('✓ PostgreSQL备份成功')
                # 压缩备份文件
                gzip_cmd = f"gzip {backup_file} 2>&1"
                subprocess.run(gzip_cmd, shell=True)
                print('✓ 备份文件已压缩')
            else:
                print(f"✗ PostgreSQL备份失败: {result.stderr}")
            
        elif type == 'redis':
            # Redis备份
            if password:
                cmd = f"redis-cli -h {host} -p {port} -a {password} save 2>&1"
            else:
                cmd = f"redis-cli -h {host} -p {port} save 2>&1"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                # 复制RDB文件
                # 注意：需要知道Redis的持久化目录
                print('✓ Redis备份命令执行成功')
                print('提示: Redis已执行SAVE命令，RDB文件已更新')
            else:
                print(f"✗ Redis备份失败: {result.stderr}")
        else:
            print(f"不支持的数据库类型: {type}")
    else:
        print("无效的数据库编号")
else:
    print("配置文件不存在")
PY
    else:
        show_error "需要Python 3来执行数据库备份"
    fi
    
    pause
}

# 配置备份计划
configure_backup() {
    show_title "配置备份计划"
    
    read -p "是否启用自动备份? (y/n): " enable_backup
    
    if [[ $enable_backup =~ ^[Yy]$ ]]; then
        read -p "请输入备份计划 (cron格式，默认 0 0 * * *): " backup_schedule
        backup_schedule=${backup_schedule:-"0 0 * * *"}
        read -p "请输入备份保留天数 (默认 7): " backup_retention
        backup_retention=${backup_retention:-7}
        read -p "请输入备份目录 (默认 /opt/linux_panel/backup): " backup_dir
        backup_dir=${backup_dir:-"/opt/linux_panel/backup"}
        
        if command_exists python3; then
            ENABLE_BACKUP="$enable_backup" BACKUP_SCHEDULE="$backup_schedule" BACKUP_RETENTION="$backup_retention" BACKUP_DIR="$backup_dir" python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/database_config.json"

# 读取现有配置
if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
else:
    data = {"databases": [], "backup": {"enabled": false, "schedule": "0 0 * * *", "retention": 7, "dir": "/opt/linux_panel/backup"}}

# 更新备份配置
data["backup"] = {
    "enabled": True,
    "schedule": os.environ.get("BACKUP_SCHEDULE"),
    "retention": int(os.environ.get("BACKUP_RETENTION")),
    "dir": os.environ.get("BACKUP_DIR")
}

# 保存配置
with open(config_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("备份计划配置成功")

# 更新crontab
cron_job = f"{os.environ.get('BACKUP_SCHEDULE')} root bash -c 'source /workspace/linux_panel/modules/database.sh && auto_backup_databases' >> /var/log/linux_panel/backup.log 2>&1"

# 移除旧的备份任务
os.system("crontab -l | grep -v 'auto_backup_databases' | crontab -")
# 添加新的备份任务
os.system(f"echo '{cron_job}' | crontab -")

print("Crontab已更新")
PY
            show_success "备份计划配置成功"
        else:
            show_error "需要Python 3来修改配置文件"
    else:
        if command_exists python3; then
            python3 - << 'PY'
import json
import os

config_file = "/etc/linux_panel/database_config.json"

# 读取现有配置
if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
else:
    data = {"databases": [], "backup": {"enabled": false, "schedule": "0 0 * * *", "retention": 7, "dir": "/opt/linux_panel/backup"}}

# 禁用备份
with open(config_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("备份计划已禁用")

# 移除备份任务
os.system("crontab -l | grep -v 'auto_backup_databases' | crontab -")

print("Crontab已更新")
PY
            show_success "备份计划已禁用"
        else:
            show_error "需要Python 3来修改配置文件"
    fi
    
    pause
}

# 自动备份数据库
auto_backup_databases() {
    if [ -f "$DB_CONFIG_FILE" ]; then
        if command_exists python3; then
            python3 - << 'PY'
import json
import os
import subprocess
import datetime

config_file = "/etc/linux_panel/database_config.json"

if os.path.exists(config_file):
    with open(config_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    backup_config = data.get('backup', {})
    enabled = backup_config.get('enabled', False)
    backup_dir = backup_config.get('dir', '/opt/linux_panel/backup')
    retention = backup_config.get('retention', 7)
    
    if enabled:
        databases = data.get('databases', [])
        for db in databases:
            name = db.get('name')
            type = db.get('type')
            host = db.get('host')
            port = db.get('port')
            user = db.get('user')
            password = db.get('pass')
            
            # 创建备份目录
            backup_subdir = os.path.join(backup_dir, type, name)
            os.makedirs(backup_subdir, exist_ok=True)
            
            # 生成备份文件名
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_file = os.path.join(backup_subdir, f"{name}_{timestamp}.bak")
            
            print(f"备份数据库: {name}")
            
            # 根据数据库类型执行不同的备份
            if type == 'mysql':
                cmd = f"mysqldump -h {host} -P {port} -u {user} -p{password} --all-databases > {backup_file} 2>&1"
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    print(f"✓ {name} 备份成功")
                    # 压缩备份文件
                    subprocess.run(f"gzip {backup_file}", shell=True)
                else:
                    print(f"✗ {name} 备份失败: {result.stderr}")
            elif type == 'postgresql':
                cmd = f"PGPASSWORD={password} pg_dumpall -h {host} -p {port} -U {user} > {backup_file} 2>&1"
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    print(f"✓ {name} 备份成功")
                    # 压缩备份文件
                    subprocess.run(f"gzip {backup_file}", shell=True)
                else:
                    print(f"✗ {name} 备份失败: {result.stderr}")
            elif type == 'redis':
                if password:
                    cmd = f"redis-cli -h {host} -p {port} -a {password} save 2>&1"
                else:
                    cmd = f"redis-cli -h {host} -p {port} save 2>&1"
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    print(f"✓ {name} 备份命令执行成功")
                else:
                    print(f"✗ {name} 备份失败: {result.stderr}")
        
        # 清理过期备份
        print("清理过期备份...")
        cutoff_date = datetime.datetime.now() - datetime.timedelta(days=retention)
        for root, dirs, files in os.walk(backup_dir):
            for file in files:
                file_path = os.path.join(root, file)
                file_mtime = datetime.datetime.fromtimestamp(os.path.getmtime(file_path))
                if file_mtime < cutoff_date:
                    os.remove(file_path)
                    print(f"删除过期备份: {file_path}")
PY
        fi
    fi
}

# 查看备份历史
view_backup_history() {
    show_title "备份历史"
    
    if [ -d "$DB_BACKUP_DIR" ]; then
        echo -e "${CYAN}备份目录: $DB_BACKUP_DIR${NC}"
        echo ""
        
        # 查找备份文件
        backup_files=$(find "$DB_BACKUP_DIR" -name "*.bak*" | sort -r)
        
        if [ -z "$backup_files" ]; then
            show_warning "没有找到备份文件"
        else
            echo -e "${GREEN}备份文件列表:${NC}"
            echo ""
            while IFS= read -r file; do
                file_size=$(du -h "$file" | awk '{print $1}')
                file_mtime=$(date -r "$file" '+%Y-%m-%d %H:%M:%S')
                echo -e "${BLUE}$file${NC}"
                echo -e "  大小: $file_size"
                echo -e "  修改时间: $file_mtime"
                echo ""
            done <<< "$backup_files"
        fi
    else
        show_error "备份目录不存在: $DB_BACKUP_DIR"
    fi
    
    pause
}
