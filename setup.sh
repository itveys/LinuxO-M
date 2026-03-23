#!/bin/bash

# Linux面板安装脚本设置工具
# 用于在Linux环境中设置脚本权限和准备环境

echo "========================================"
echo "    Linux面板安装脚本设置工具"
echo "========================================"
echo ""

# 检查是否在Linux环境
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "警告: 此脚本主要用于Linux环境"
    echo "在Windows上，请使用WSL或直接在Linux服务器上运行"
    echo ""
fi

# 设置主脚本权限
if [ -f "linux_panel_installer.sh" ]; then
    echo "设置 linux_panel_installer.sh 执行权限..."
    chmod +x linux_panel_installer.sh
    echo "权限设置完成"
    echo ""
    
    echo "使用方法:"
    echo "1. 将脚本上传到Linux服务器"
    echo "2. 赋予执行权限: chmod +x linux_panel_installer.sh"
    echo "3. 以root用户运行: sudo ./linux_panel_installer.sh"
    echo ""
    
    echo "或者在Windows上使用WSL:"
    echo "1. 打开WSL终端"
    echo "2. 进入脚本目录"
    echo "3. 运行: sudo bash linux_panel_installer.sh"
else
    echo "错误: 未找到 linux_panel_installer.sh 文件"
    exit 1
fi

echo "========================================"
echo "脚本准备完成！"
echo "请按照README.md中的说明使用"
echo "========================================"