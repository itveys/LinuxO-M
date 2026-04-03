#!/bin/bash

# 自动贴吧签到脚本
# 作者：技术助手
# 日期：2026-04-03

# 配置参数
TB_TOKEN="0KMh+E5/t4KKmk9Rx5jqLJzpiWfvaoaJHhsax1kXizYod1TETXRMRKtGr5k="
BASE_URL="https://tieba.baidu.com"
LOG_FILE="/workspace/tieba_signin.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 检查curl是否安装
if ! command -v curl &> /dev/null; then
    log "错误：curl 未安装，请先安装 curl"
    exit 1
fi

# 检查TB_TOKEN是否设置
if [ -z "$TB_TOKEN" ]; then
    log "错误：TB_TOKEN 未设置"
    exit 1
fi

# 签到函数
signin() {
    log "开始执行贴吧签到..."
    
    # 获取帖子列表
    log "获取帖子列表..."
    POSTS_RESPONSE=$(curl -s -H "Authorization: $TB_TOKEN" "$BASE_URL/c/f/frs/page_claw?sort_type=0")
    
    if [ $? -ne 0 ]; then
        log "错误：获取帖子列表失败"
        return 1
    fi
    
    # 提取帖子ID
    THREAD_IDS=$(echo "$POSTS_RESPONSE" | grep -o '"id":[0-9]*' | cut -d ':' -f 2 | head -10)
    
    if [ -z "$THREAD_IDS" ]; then
        log "错误：未找到帖子"
        return 1
    fi
    
    log "找到 $(echo "$THREAD_IDS" | wc -w) 个帖子，开始签到..."
    
    # 对每个帖子进行点赞（模拟签到）
    for THREAD_ID in $THREAD_IDS; do
        log "正在签到帖子 $THREAD_ID..."
        
        # 点赞操作（模拟签到）
        LIKE_RESPONSE=$(curl -s -X POST "$BASE_URL/c/c/claw/opAgree" \
            -H "Authorization: $TB_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"thread_id\": $THREAD_ID, \"obj_type\": 3, \"op_type\": 0}")
        
        if [ $? -eq 0 ]; then
            if echo "$LIKE_RESPONSE" | grep -q '"errno":0'; then
                log "帖子 $THREAD_ID 签到成功"
            else
                log "帖子 $THREAD_ID 签到失败: $(echo "$LIKE_RESPONSE" | grep -o '"errmsg":"[^"]*"' | cut -d '"' -f 4)"
            fi
        else
            log "帖子 $THREAD_ID 签到请求失败"
        fi
        
        # 避免请求过于频繁
        sleep 1
    done
    
    log "签到完成"
    return 0
}

# 主函数
main() {
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 执行签到
    signin
    
    # 检查执行结果
    if [ $? -eq 0 ]; then
        log "自动签到任务执行成功"
    else
        log "自动签到任务执行失败"
        exit 1
    fi
}

# 执行主函数
main