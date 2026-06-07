# DD ROS - MikroTik RouterOS CHR 自动化部署脚本

[English](#english) | [中文](#chinese)

---

<a name="chinese"></a>
## 🇨🇳 中文文档

### 📖 简介

DD ROS 是一个自动化部署脚本，用于在 VPS 上安装 MikroTik RouterOS CHR（Cloud Hosted Router）。该脚本会自动检测系统环境、下载 RouterOS 镜像、配置网络参数，并通过 DD 方式将系统替换为 RouterOS。

### ✨ 特性

- 🚀 **全自动部署** - 一键安装 RouterOS CHR
- 🔧 **智能配置** - 自动检测并配置网络参数（IP、网关、MAC地址等）
- 🌐 **多发行版支持** - 支持 Ubuntu、Debian、CentOS、Oracle Linux、Amazon Linux、Fedora、Rocky Linux
- 🔐 **灵活的参数配置** - 通过命令行参数自定义密码和许可证信息
- 🖼️ **自定义镜像来源** - 支持指定本地 RouterOS 镜像文件或直接使用镜像 URL
- 📡 **UEFI 支持** - 自动检测并支持 UEFI 启动模式
- 🌍 **IPv4/IPv6 双栈支持** - 自动配置 IPv4 和 IPv6 网络

### 📋 系统要求

- Linux 系统（Ubuntu/Debian/CentOS/Fedora/Rocky Linux 等）
- Root 权限
- 互联网连接
- 至少 1GB 可用磁盘空间

### 🚀 使用方法

#### 基本用法

```bash
# 下载脚本
wget https://raw.githubusercontent.com/cjdxb/dd_ros/main/dd_ros.sh

# 添加执行权限
chmod +x dd_ros.sh

# 使用默认配置运行
./dd_ros.sh

# 或使用自定义密码
./dd_ros.sh -p your_password
```

#### 命令行参数

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--password` | `-p` | ROS 管理员密码 | `qaz123..` |
| `--ros-account` | `-a` | ROS 许可证账号 | `123` |
| `--ros-password` | `-r` | ROS 许可证密码 | `123` |
| `--version` | `-v` | ROS 版本号 | 最新稳定版 |
| `--image` | `-i` | 本地镜像文件路径或镜像 URL | 自动下载官方镜像 |
| `--help` | `-h` | 显示帮助信息 | - |

#### 使用示例

```bash
# 使用默认配置
./dd_ros.sh

# 设置管理员密码
./dd_ros.sh -p MySecurePass123

# 指定 ROS 版本
./dd_ros.sh -v 7.16.2

# 使用本地镜像文件（支持 .img 或 .img.zip）
./dd_ros.sh -i /root/chr-7.16.2.img.zip

# 直接使用镜像 URL
./dd_ros.sh -i https://download.mikrotik.com/routeros/7.16.2/chr-7.16.2.img.zip

# 使用无法从文件名识别版本的自定义镜像时，可同时指定版本
./dd_ros.sh -i /root/routeros.img -v 7.16.2

# 设置所有参数
./dd_ros.sh -p MyAdminPass -a my_license_account -r my_license_password -v 7.15.3 -i /root/chr-7.15.3.img.zip

# 查看帮助
./dd_ros.sh -h
```

### 🔐 登录信息

安装完成后，脚本会输出登录信息：

```
---
Installation completed!
Username: admin
Password: [你设置的密码]
---
```

### 📝 工作流程

1. **环境检测** - 检测 Linux 发行版并安装必要工具
2. **网络信息采集** - 自动获取网络接口、IP 地址、MAC 地址、网关等信息
3. **镜像准备** - 下载官方 RouterOS CHR 镜像，或使用用户指定的本地镜像/URL
4. **镜像处理** - 提取并配置镜像文件
5. **UEFI 处理**（如适用）- 转换为 Hybrid MBR 格式
6. **自动配置** - 生成 autorun.scr 配置脚本
7. **系统替换** - 通过 DD 方式写入磁盘
8. **自动重启** - 重启进入 RouterOS 系统

### ⚙️ 自动配置项

脚本会自动配置以下内容：

- ✅ 禁用不安全的服务（telnet、ftp、www、api 等）
- ✅ 设置管理员密码
- ✅ 配置 SSH 和 WinBox 端口
- ✅ 配置 DNS 服务器
- ✅ 配置网络接口 IP 地址
- ✅ 配置默认网关（IPv4/IPv6）
- ✅ 配置 RouterOS 许可证（如提供）

### ⚠️ 注意事项

1. **数据备份** - 脚本会完全替换系统，请提前备份重要数据
2. **网络连接** - 确保 VPS 有稳定的网络连接
3. **Root 权限** - 必须使用 root 用户或 sudo 运行
4. **不可逆操作** - DD 操作无法撤销，请谨慎使用
5. **KVM 虚拟化** - 建议使用 KVM 虚拟化的 VPS，某些虚拟化技术可能不兼容

### 🔧 故障排除

- **安装工具失败** - 检查网络连接和软件源配置
- **镜像下载失败** - 尝试手动下载镜像或更换网络
- **本地镜像无法读取** - 检查镜像路径是否正确，并确认当前用户有读取权限
- **启动失败** - 检查 VPS 是否支持 UEFI 或传统 BIOS 启动
- **网络无法访问** - 确认网络参数配置正确，检查防火墙设置

### 📦 支持的 Linux 发行版

- Ubuntu
- Debian
- CentOS Linux
- Oracle Linux
- Amazon Linux
- Fedora
- Rocky Linux

### 📄 许可证

本项目采用开源许可证，欢迎贡献和改进。

---

<a name="english"></a>
## 🇬🇧 English Documentation

### 📖 Introduction

DD ROS is an automated deployment script for installing MikroTik RouterOS CHR (Cloud Hosted Router) on VPS servers. The script automatically detects the system environment, downloads the RouterOS image, configures network parameters, and replaces the system with RouterOS using DD method.

### ✨ Features

- 🚀 **Fully Automated** - One-click RouterOS CHR installation
- 🔧 **Smart Configuration** - Auto-detects and configures network parameters (IP, gateway, MAC address, etc.)
- 🌐 **Multi-Distribution Support** - Supports Ubuntu, Debian, CentOS, Oracle Linux, Amazon Linux, Fedora, Rocky Linux
- 🔐 **Flexible Parameters** - Customize passwords and license information via command-line arguments
- 🖼️ **Custom Image Source** - Supports a local RouterOS image file or a direct image URL
- 📡 **UEFI Support** - Automatically detects and supports UEFI boot mode
- 🌍 **IPv4/IPv6 Dual Stack** - Automatically configures IPv4 and IPv6 networking

### 📋 System Requirements

- Linux system (Ubuntu/Debian/CentOS/Fedora/Rocky Linux, etc.)
- Root privileges
- Internet connection
- At least 1GB free disk space

### 🚀 Usage

#### Basic Usage

```bash
# Download the script
wget https://raw.githubusercontent.com/cjdxb/dd_ros/main/dd_ros.sh

# Add execute permission
chmod +x dd_ros.sh

# Run with default configuration
./dd_ros.sh

# Or run with custom password
./dd_ros.sh -p your_password
```

#### Command Line Arguments

| Option | Short | Description | Default |
|--------|-------|-------------|--------|
| `--password` | `-p` | ROS admin password | `qaz123..` |
| `--ros-account` | `-a` | ROS license account | `123` |
| `--ros-password` | `-r` | ROS license password | `123` |
| `--version` | `-v` | ROS version | latest stable |
| `--image` | `-i` | Local image file path or image URL | auto-download official image |
| `--help` | `-h` | Show help message | - |

#### Examples

```bash
# Use default configuration
./dd_ros.sh

# Set admin password
./dd_ros.sh -p MySecurePass123

# Specify ROS version
./dd_ros.sh -v 7.16.2

# Use a local image file (.img and .img.zip are supported)
./dd_ros.sh -i /root/chr-7.16.2.img.zip

# Use a direct image URL
./dd_ros.sh -i https://download.mikrotik.com/routeros/7.16.2/chr-7.16.2.img.zip

# Specify the version when it cannot be detected from a custom image name
./dd_ros.sh -i /root/routeros.img -v 7.16.2

# Set all parameters
./dd_ros.sh -p MyAdminPass -a my_license_account -r my_license_password -v 7.15.3 -i /root/chr-7.15.3.img.zip

# Show help
./dd_ros.sh -h
```

### 🔐 Login Information

After installation completes, the script will output login credentials:

```
---
Installation completed!
Username: admin
Password: [your_password]
---
```

### 📝 Workflow

1. **Environment Detection** - Detects Linux distribution and installs necessary tools
2. **Network Information Collection** - Automatically retrieves network interfaces, IP addresses, MAC addresses, gateways, etc.
3. **Image Preparation** - Downloads the official RouterOS CHR image, or uses a user-provided local image/URL
4. **Image Processing** - Extracts and configures the image file
5. **UEFI Processing** (if applicable) - Converts to Hybrid MBR format
6. **Auto Configuration** - Generates autorun.scr configuration script
7. **System Replacement** - Writes to disk using DD method
8. **Auto Reboot** - Reboots into RouterOS system

### ⚙️ Auto-Configured Items

The script automatically configures:

- ✅ Disables insecure services (telnet, ftp, www, api, etc.)
- ✅ Sets admin password
- ✅ Configures SSH and WinBox ports
- ✅ Configures DNS servers
- ✅ Configures network interface IP addresses
- ✅ Configures default gateway (IPv4/IPv6)
- ✅ Configures RouterOS license (if provided)

### ⚠️ Important Notes

1. **Backup Data** - The script completely replaces the system; backup important data first
2. **Network Connection** - Ensure the VPS has a stable internet connection
3. **Root Privileges** - Must run as root user or with sudo
4. **Irreversible Operation** - DD operation cannot be undone; use with caution
5. **KVM Virtualization** - Recommended to use KVM-virtualized VPS; some virtualization technologies may be incompatible

### 🔧 Troubleshooting

- **Tool Installation Failed** - Check network connection and repository configuration
- **Image Download Failed** - Try manual download or switch network
- **Local Image Not Readable** - Check the image path and make sure the current user has read permission
- **Boot Failed** - Check if VPS supports UEFI or legacy BIOS boot
- **Network Inaccessible** - Verify network parameters are correct, check firewall settings

### 📦 Supported Linux Distributions

- Ubuntu
- Debian
- CentOS Linux
- Oracle Linux
- Amazon Linux
- Fedora
- Rocky Linux

### 📄 License

This project is open source. Contributions and improvements are welcome.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

## ⭐ Star History

If you find this project helpful, please consider giving it a star!

## 📧 Contact

For questions or support, please open an issue on GitHub.
