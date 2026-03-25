# Linux 面板与工具安装脚本

<div align="center">

![Version](https://img.shields.io/badge/version-2.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-CentOS%20%7C%20Ubuntu%20%7C%20Debian-orange)

**一键安装常用面板和工具的强大脚本**

[功能特性](#功能特性) • [快速开始](#快速开始) • [使用文档](#使用文档) • [更新日志](#更新日志)

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

### 安装步骤

```bash
# 1. 下载脚本
wget https://raw.githubusercontent.com/itveys/LinuxO-M/main/linux_panel_installer.sh

# 2. 赋予执行权限
chmod +x linux_panel_installer.sh

# 3. 以root权限运行
sudo bash linux_panel_installer.sh
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

---

## ❓ 常见问题

<details>
<summary><b>脚本无法运行怎么办？</b></summary>

确保以root权限运行，并检查系统是否满足要求。
</details>

<details>
<summary><b>安装过程中断怎么办？</b></summary>

重新运行脚本，大部分安装过程会自动继续。
</details>

<details>
<summary><b>Docker容器无法启动怎么办？</b></summary>

检查端口是否被占用，磁盘空间是否充足。
</details>

<details>
<summary><b>如何卸载已安装的服务？</b></summary>

使用Docker命令或相应的卸载脚本。
</details>

<details>
<summary><b>如何查看服务的运行状态？</b></summary>

使用 `docker ps` 查看容器状态，或使用系统服务管理命令。
</details>

<details>
<summary><b>实时监控功能如何使用？</b></summary>

在服务器信息菜单中选择"查看实时监控"，按Ctrl+C退出。
</details>

<details>
<summary><b>如何配置定时备份？</b></summary>

在数据库备份功能中选择"配置定时备份任务"。
</details>

<details>
<summary><b>如何切换Docker镜像源？</b></summary>

在数据与备份菜单中选择"Docker镜像源切换"功能。
</details>

<details>
<summary><b>运维功能支持哪些数据库服务？</b></summary>

支持Docker、MySQL、Oracle、SQL Server四大数据库服务的运维管理，包括启动/停止/重启服务、用户管理、权限管理、备份恢复等操作。
</details>

<details>
<summary><b>如何访问运维功能？</b></summary>

在运维工具菜单中选择"运维功能"，然后选择相应的数据库服务类型进行操作。
</details>

---

## 📝 更新日志

### v2.1 (2026-03-25)
- ✨ 新增DNS污染检测与优化功能（解析域名对应的多个IP，选择最快的，更新hosts配置）
- ✨ 新增消息推送配置功能（支持钉钉、PlusPush、泛微OA等消息推送）
- ✨ 新增运维功能模块（Docker、MySQL、Oracle、SQL Server数据库服务运维管理）
- 🔧 集成Docker镜像源DNS检测与修复到Docker安装流程
- 🔧 实现操作完成自动推送消息功能
- 🔧 重构主菜单结构，采用分组管理，提高用户体验
- 🐛 增强系统兼容性和错误处理

### v2.0 (2026-03-23)
- ✨ 添加系统实时监控功能（CPU、内存、磁盘、网络动态变化）
- ✨ 新增网络测速功能（基础连通性、下载速度、综合性能测试）
- ✨ 添加服务器时间校准功能（手动设置、自动同步、时区配置）
- ✨ 添加NAS配置功能（NFS、SMB/CIFS、FTP共享挂载到特定目录）
- ✨ 添加数据库备份功能（MySQL、PostgreSQL、Oracle、Redis等）
- ✨ 添加Docker镜像源切换功能（支持阿里云、腾讯云、网易云、中科大等镜像源）
- ✨ 添加防火墙端口管理功能（支持iptables、firewalld、ufw等防火墙）
- 🔧 更新主菜单界面，支持14个功能选项
- 🔧 增强用户交互体验和错误处理

### v1.3 (2025-03-23)
- ✨ 添加Docker镜像源DNS检测与修复功能
- 🔧 支持Docker Hub域名DNS污染检测
- 🔧 自动获取最新可用Docker Hub IP地址
- 🔧 更新hosts文件并刷新DNS缓存

### v1.2 (2025-03-23)
- ✨ 添加DNS污染检测与修复功能
- 🔧 支持GitHub域名DNS污染检测
- 🔧 自动获取最新可用IP地址
- 🔧 更新hosts文件并刷新DNS缓存

### v1.1 (2025-03-23)
- ✨ 添加X-UI面板安装功能
- 🔧 更新主菜单界面
- 🔧 完善文档说明

### v1.0 (2025-03-23)
- 🎉 初始版本发布
- ✨ 包含宝塔、哪吒、Docker安装功能
- ✨ 添加Docker常用服务一键安装
- 🔧 完善系统信息显示功能

---

## 📄 许可证

MIT License

---

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个脚本。

---

## 📮 联系方式

如有问题或建议，请通过[GitHub Issues](https://github.com/itveys/LinuxO-M/issues)反馈。

---

<div align="center">

**如果这个项目对你有帮助，请给个 ⭐️ Star 支持一下！**

</div>
