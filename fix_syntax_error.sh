#!/bin/bash

# 修复脚本语法错误的脚本
echo "正在检查并修复linux_panel_installer.sh的语法错误..."

# 检查文件是否存在
if [ ! -f "linux_panel_installer.sh" ]; then
    echo "错误: linux_panel_installer.sh不存在"
    exit 1
fi

# 创建备份
cp linux_panel_installer.sh linux_panel_installer.sh.backup
echo "已创建备份: linux_panel_installer.sh.backup"

# 修复常见的语法错误
echo "修复语法错误..."

# 修复1: 缺少右方括号的错误
sed -i 's/if \[\[ $continue_repair != "y" && $continue_repair != "Y" \]; then/if [[ $continue_repair != "y" && $continue_repair != "Y" ]]; then/g' linux_panel_installer.sh

# 修复2: 其他可能的括号错误
sed -i 's/if \[\[ $confirm != "y" && $confirm != "Y" \]; then/if [[ $confirm != "y" && $confirm != "Y" ]]; then/g' linux_panel_installer.sh
sed -i 's/if \[\[ $choice != "y" && $choice != "Y" \]; then/if [[ $choice != "y" && $choice != "Y" ]]; then/g' linux_panel_installer.sh

# 修复3: 正则表达式括号错误
sed -i 's/elif \[\[ $ip_result =~ ^(127\\.|0\\.|169\\.254|10\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.|192\\.168\\.) \]; then/elif [[ $ip_result =~ ^(127\.|0\.|169\.254|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.) ]]; then/g' linux_panel_installer.sh

echo "修复完成！"

# 检查脚本语法
echo "检查修复后的脚本语法..."
if bash -n linux_panel_installer.sh; then
    echo "✓ 脚本语法检查通过！"
else
    echo "⚠ 脚本语法检查失败，请手动检查"
fi

echo "修复脚本执行完成。"