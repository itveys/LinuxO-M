#!/bin/bash

echo "正在修复脚本语法错误..."

# 创建备份
if [ -f "linux_panel_installer.sh" ]; then
    cp linux_panel_installer.sh linux_panel_installer.sh.backup.$(date +%Y%m%d_%H%M%S)
    echo "已创建备份: linux_panel_installer.sh.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 修复具体的语法错误
    echo "修复第1679行的语法错误..."
    
    # 检查文件是否有该错误
# 检查文件
grep -n "if \[\[.*\]; then" linux_panel_installer.sh | while read line; do
    linenum=$(echo $line | cut -d: -f1)
    echo "修复第${linenum}行的语法错误..."
    
    # 修复语法错误
sed -i "${linenum}s/if \[\[ \$continue_repair != \"y\" && \$continue_repair != \"Y\" \]; then/if [[ \$continue_repair != \"y\" && \$continue_repair != \"Y\" ]]; then/g" linux_panel_installer.sh 2>/dev/null

sed -i "${linenum}s/if \[\[ \$confirm != \"y\" && \$confirm != \"Y\" \]; then/if [[ \$confirm != \"y\" && \$confirm != \"Y\" ]]; then/g" linux_panel_installer.sh 2>/dev/null

sed -i "${linenum}s/if \[\[ \$choice != \"y\" && \$choice != \"Y\" \]; then/if [[ \$choice != \"y\" && \$choice != \"Y\" ]]; then/g" linux_panel_installer.sh 2>/dev/null

done

# 检查脚本语法
echo "检查修复后的脚本语法..."
if bash -n linux_panel_installer.sh; then
    echo "✓ 修复成功！脚本语法检查通过。"
    echo "现在可以正常运行 ./linux_panel_installer.sh"
else
    echo "⚠ 修复可能不完全，请手动检查脚本。"
    echo "错误出现在以下行："
    bash -n linux_panel_installer.sh 2>&1 | grep "line"
fi