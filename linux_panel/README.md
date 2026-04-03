# Linux 面板与工具安装脚本

<div align="center">

![Version](https://img.shields.io/badge/version-2.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-CentOS%20%7C%20Ubuntu%20%7C%20Debian-orange)

**一键安装常用面板和工具的强大脚本**

[功能特性](#功能特性) • [快速开始](#快速开始) • [使用文档](#使用文档) • [常见问题](#常见问题) • [故障排除](#故障排除)

</div>

---

## 📋 功能特性

### 核心功能

| 功能 | 说明 |
|------|------|
| 🛠️ **宝塔面板** | 支持CentOS、Ubuntu、Debian系统的一键安装 |
| 📊 **哪吒监控** | 服务器监控和性能分析 |
| 🌐 **X-UI面板** | 多协议代理工具管理面板 |
| 🐳 **Docker环境** | 容器化运行环境，集成DNS检测与修复 |
| 🔧 **系统监控** | 实时CPU、内存、磁盘、网络监控 |

### 网络与安全

| 功能 | 说明 |
|------|------|
| 🌍 **GitHub DNS修复** | 检测并修复GitHub域名DNS污染 |
| 🚀 **Docker镜像源切换** | 支持国内镜像源，提高下载速度 |
| 🔒 **防火墙管理** | 支持iptables、firewalld、ufw防火墙 |
| ⚡ **DNS智能优化** | 解析域名对应的多个IP，选择最快的 |
| 📡 **网络测速** | 测试网络连通性和下载速度 |

### 数据与运维

| 功能 | 说明 |
|------|------|
| 💾 **数据库备份** | 支持MySQL、PostgreSQL、Oracle、Redis等 |
| 🗄️ **NAS配置** | 挂载NFS、SMB/CIFS、FTP共享 |
| ⏰ **时间校准** | 手动/自动同步服务器时间，设置时区 |
| 🔔 **消息推送** | 支持钉钉、PlusPush、泛微OA等 |
| 🎛️ **运维管理** | Docker、MySQL、Oracle、SQL Server服务运维 |

### Docker服务一键安装

- **ELK套件** (Elasticsearch + Logstash + Kibana) - 日志分析平台
- **MySQL** - 关系型数据库
- **Nginx** - Web服务器
- **Redis** - 内存数据库
- **WordPress** - 博客平台

---

## 🚀 快速开始

### 系统要求

- **操作系统**: CentOS 7+, Ubuntu 18.04+, Debian 9+
- **内存**: 至少1GB (推荐2GB+)
- **磁盘空间**: 至少10GB可用空间
- **网络**: 需要连接互联网以下载安装包
- **权限**: 需要root权限运行

### 安装步骤

```bash
# 1. 下载脚本
wget https://raw.githubusercontent.com/itveys/LinuxO-M/main/linux_panel/installer.sh

# 2. 赋予执行权限
chmod +x installer.sh

# 3. 以root权限运行
sudo bash installer.sh
```

### 脚本结构

```
linux_panel/
├── installer.sh        # 主脚本文件
├── modules/            # 模块化功能文件
│   ├── common.sh       # 通用工具函数
│   ├── utils.sh        # 工具函数模块
│   ├── compatibility.sh # 系统兼容性检查
│   ├── monitor.sh      # 系统监控功能
│   ├── panel.sh        # 面板安装功能
│   └── docker.sh       # Docker相关功能
└── README.md          # 项目文档
```

---

## 📖 使用文档

### 主菜单

脚本运行后会显示主菜单，包含以下选项：

```
1. 面板安装
2. 网络与DNS
3. 数据与备份
4. 服务器管理
5. 运维工具
6. Docker功能
0. 退出脚本
```

### 功能详解

#### 1. 面板安装

**子菜单：**
- **安装宝塔面板** - 自动识别系统类型并选择正确的安装脚本，安装完成后显示面板访问地址
- **安装哪吒监控面板** - 需要提前准备好面板地址和通信密钥，自动下载并运行官方安装脚本
- **安装 X-UI 面板** - 支持全新安装和更新安装，提供默认登录信息和安全提示

#### 2. 网络与DNS

**子菜单：**
- **GitHub DNS污染检测与修复** - 检测GitHub域名DNS污染情况，从多个在线服务获取最新可用IP
- **Docker镜像源DNS检测与修复** - 检测Docker镜像源域名DNS污染情况，自动获取最新可用IP
- **网络测速功能** - 基础网络连通性测试、下载速度测试、综合网络性能测试
- **时间校准功能** - 查看详细时间信息、手动设置日期和时间、自动时间同步、设置时区
- **DNS污染检测与优化** - 智能DNS解析、IP性能测试、最优IP选择、安全备份、智能更新、DNS缓存刷新

#### 3. 数据与备份

**子菜单：**
- **数据库备份功能** - 支持MySQL/MariaDB、PostgreSQL、Oracle、Redis等数据库备份，支持定时备份任务配置
- **定时任务中心** - 管理定时备份任务和其他定时操作
- **Docker镜像源切换** - 支持阿里云、腾讯云、华为云、网易云、中科大等镜像源，测试镜像源下载速度

#### 4. 服务器管理

**子菜单：**
- **查看服务器信息** - 显示详细系统信息（CPU、内存、磁盘、网络），实时监控功能
- **网络测速功能** - 测试网络连通性和下载速度
- **时间校准功能** - 手动/自动同步服务器时间，设置时区
- **防火墙端口管理** - 支持iptables、firewalld、ufw三种防火墙，查看当前端口状态和防火墙规则
- **NAS配置功能** - 查看当前挂载点信息，挂载NFS、SMB/CIFS、FTP共享，配置自动挂载和管理共享目录

#### 5. 运维工具

**子菜单：**
- **安装 Docker** - 支持CentOS/Ubuntu/Debian系统，自动配置Docker仓库，安装后测试Docker运行状态
- **运维功能** - Docker、MySQL、Oracle、SQL Server数据库服务运维管理
- **系统监控工具** - 启动htop、iotop、top等监控工具，CPU/内存/磁盘快览
- **安全检查工具** - 查看监听端口、SSH配置巡检、本机端口检测
- **软件包助手** - 安装常用工具集、卸载常用工具集、安装安全工具集
- **消息推送配置** - 支持钉钉、PlusPush、泛微OA、自定义Webhook，操作完成通知

#### 6. Docker功能

**子菜单：**
- **一键安装 ELK** - 配置完整的日志分析环境（Elasticsearch + Logstash + Kibana）
- **一键安装 MySQL** - 支持自定义密码和数据目录
- **一键安装 Nginx** - 包含配置文件管理和网站目录
- **一键安装 Redis** - 支持密码保护和数据持久化
- **一键安装 WordPress** - 包含MySQL数据库的完整WordPress环境
- **查看Docker状态** - 查看Docker版本、容器数量、镜像数量
- **管理Docker容器** - 启动/停止/重启/删除容器，查看容器日志，进入容器终端

---

## ⚠️ 注意事项

1. **备份数据**: 安装前请备份重要数据
2. **网络连接**: 安装过程需要稳定的网络连接
3. **系统资源**: 某些服务（如ELK）需要较多系统资源
4. **安全设置**: 安装完成后请修改默认密码
5. **防火墙**: 确保相关端口已开放
6. **权限要求**: 脚本需要root权限运行
7. **系统兼容性**: 部分功能可能因系统版本而异
8. **日志管理**: 脚本会生成详细的日志文件，位于 `/var/log/linux_panel/installer.log`

---

## ❓ 常见问题

### 脚本无法运行怎么办？
- 确保以root权限运行
- 检查系统是否满足要求
- 检查网络连接是否正常
- 查看日志文件获取详细错误信息

### 安装过程中断怎么办？
- 重新运行脚本，大部分安装过程会自动继续
- 检查网络连接是否稳定
- 查看日志文件了解中断原因

### Docker容器无法启动怎么办？
- 检查端口是否被占用
- 检查磁盘空间是否充足
- 检查Docker服务是否正常运行
- 查看容器日志获取详细错误信息

### 如何卸载已安装的服务？
- 使用Docker命令或相应的卸载脚本
- 对于面板类服务，参考官方文档进行卸载

### 如何查看服务的运行状态？
- 使用 `docker ps` 查看容器状态
- 使用系统服务管理命令查看服务状态
- 在脚本的服务器管理菜单中查看系统信息

### 实时监控功能如何使用？
- 在服务器信息菜单中选择"查看实时监控"
- 按Ctrl+C退出监控

### 如何配置定时备份？
- 在数据库备份功能中选择"配置定时备份任务"
- 设置备份频率和保留策略

### 如何切换Docker镜像源？
- 在数据与备份菜单中选择"Docker镜像源切换"功能
- 选择合适的镜像源并测试下载速度

### 运维功能支持哪些数据库服务？
- 支持Docker、MySQL、Oracle、SQL Server四大数据库服务的运维管理
- 包括启动/停止/重启服务、用户管理、权限管理、备份恢复等操作

### 如何访问运维功能？
- 在运维工具菜单中选择"运维功能"
- 然后选择相应的数据库服务类型进行操作

---

## 🔧 故障排除

### 网络问题
- **DNS污染**: 使用脚本的DNS修复功能
- **网络连接**: 检查网络配置和防火墙设置
- **下载失败**: 尝试切换网络环境或使用代理

### 系统问题
- **权限不足**: 确保以root权限运行脚本
- **磁盘空间不足**: 清理不必要的文件或扩展磁盘空间
- **内存不足**: 增加内存或关闭不必要的服务

### 服务问题
- **服务启动失败**: 查看服务日志获取详细错误信息
- **端口冲突**: 检查端口占用情况并修改配置
- **依赖缺失**: 运行脚本的系统兼容性检查功能

### 日志查看
- 脚本日志: `/var/log/linux_panel/installer.log`
- Docker日志: 使用 `docker logs 容器名称`
- 系统日志: `/var/log/syslog` 或 `/var/log/messages`

---

## 📝 配置文件

### 脚本配置
- **日志配置**: 日志文件位于 `/var/log/linux_panel/installer.log`
- **定时任务**: 配置文件位于 `/etc/cron.d/linux_panel_tasks`
- **消息推送**: 配置文件位于 `/etc/linux_panel_push_config.json`

### Docker配置
- **Docker配置**: `/etc/docker/daemon.json`
- **容器数据**: 默认为 `/opt/{服务名}_data`
- **容器配置**: 默认为 `/opt/{服务名}_conf`

---

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个脚本。

### 贡献步骤
1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开Pull Request

---

## 📄 许可证

MIT License

---

## 📮 联系方式

如有问题或建议，请通过[GitHub Issues](https://github.com/itveys/LinuxO-M/issues)反馈。

---

<div align="center">

**如果这个项目对你有帮助，请给个 ⭐️ Star 支持一下！**

</div>
