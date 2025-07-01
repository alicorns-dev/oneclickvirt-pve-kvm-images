#!/bin/bash
#from https://github.com/oneclickvirt/pve_kvm_images
#updated for official images and PVE optimization

if ! command -v virt-customize &> /dev/null
then
    echo "virt-customize not found, installing libguestfs-tools"
    sudo apt-get update
    sudo apt-get install -y libguestfs-tools
    sudo apt-get install -y libguestfs-tools --fix-missing
fi
if ! command -v rngd &> /dev/null
then
    echo "rng-tools not found, installing rng-tools"
    sudo apt-get update
    sudo apt-get install -y rng-tools
    sudo apt-get install -y rng-tools --fix-missing
fi

export LIBGUESTFS_BACKEND=direct
export LIBGUESTFS_BACKEND_SETTINGS="passt:no"
ls -l /dev/kvm
ls -l /var/lib/libvirt/

qcow_file=$1
echo "----------------------------------------------------------"
echo "转换文件$qcow_file中......"

# 检测发行版类型
if [[ "$qcow_file" == *"ubuntu"* || "$qcow_file" == *"noble"* || "$qcow_file" == *"jammy"* ]]; then
    echo "检测到Ubuntu系统，开始配置..."
    
    # 启用SSH密码认证
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg"
    
    # 启用root登录
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/lock_passwd:[[:space:]]*true/lock_passwd: false/g' /etc/cloud/cloud.cfg"
    
    # 安装必要软件包
    sudo virt-customize -v -x -a $qcow_file --run-command "apt-get update -y"
    sudo virt-customize -v -x -a $qcow_file --run-command "DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget sudo openssh-server"
    sudo virt-customize -v -x -a $qcow_file --run-command "DEBIAN_FRONTEND=noninteractive apt-get install -y qemu-guest-agent"
    
    # 启用服务
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable ssh"
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable qemu-guest-agent"
    
elif [[ "$qcow_file" == *"debian"* ]]; then
    echo "检测到Debian系统，开始配置..."
    
    # 启用SSH密码认证
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg"
    
    # 启用root登录
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg"
    
    # 安装必要软件包
    sudo virt-customize -v -x -a $qcow_file --run-command "apt-get update -y"
    sudo virt-customize -v -x -a $qcow_file --run-command "DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget sudo openssh-server"
    sudo virt-customize -v -x -a $qcow_file --run-command "DEBIAN_FRONTEND=noninteractive apt-get install -y qemu-guest-agent"
    
    # 启用服务
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable ssh"
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable qemu-guest-agent"

elif [[ "$qcow_file" == *"almalinux"* || "$qcow_file" == *"AlmaLinux"* ]]; then
    echo "检测到AlmaLinux系统，开始配置..."
    
    # 启用SSH密码认证
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg"
    
    # 启用root登录
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/disable_root:[[:space:]]*1/disable_root: 0/g' /etc/cloud/cloud.cfg"
    
    # 禁用SELinux增强安全性问题
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"
    
    # 安装必要软件包
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf update -y"
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf install -y curl wget sudo openssh-server"
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf install -y qemu-guest-agent"
    
    # 启用服务
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable sshd"
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable qemu-guest-agent"

elif [[ "$qcow_file" == *"rocky"* || "$qcow_file" == *"Rocky"* ]]; then
    echo "检测到Rocky Linux系统，开始配置..."
    
    # 启用SSH密码认证
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg"
    
    # 启用root登录
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/disable_root:[[:space:]]*1/disable_root: 0/g' /etc/cloud/cloud.cfg"
    
    # 禁用SELinux
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"
    
    # 安装必要软件包
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf update -y"
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf install -y curl wget sudo openssh-server"
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf install -y qemu-guest-agent"
    
    # 启用服务
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable sshd"
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable qemu-guest-agent"

elif [[ "$qcow_file" == *"centos"* || "$qcow_file" == *"CentOS"* ]]; then
    echo "检测到CentOS系统，开始配置..."
    
    # 启用SSH密码认证
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg"
    
    # 启用root登录
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/disable_root:[[:space:]]*1/disable_root: 0/g' /etc/cloud/cloud.cfg"
    
    # 禁用SELinux
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"
    
    # 安装必要软件包
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf update -y"
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf install -y curl wget sudo openssh-server"
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf install -y qemu-guest-agent"
    
    # 启用服务
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable sshd"
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable qemu-guest-agent"

elif [[ "$qcow_file" == *"fedora"* || "$qcow_file" == *"Fedora"* ]]; then
    echo "检测到Fedora系统，开始配置..."
    
    # 启用SSH密码认证
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg"
    
    # 启用root登录
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg"
    
    # 禁用SELinux
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config"
    
    # 安装必要软件包
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf update -y"
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf install -y curl wget sudo openssh-server"
    sudo virt-customize -v -x -a $qcow_file --run-command "dnf install -y qemu-guest-agent"
    
    # 启用服务
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable sshd"
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable qemu-guest-agent"

elif [[ "$qcow_file" == *"alpine"* || "$qcow_file" == *"Alpine"* ]]; then
    echo "检测到Alpine Linux系统，开始配置..."
    
    # Alpine使用不同的包管理器和init系统
    sudo virt-customize -v -x -a $qcow_file --run-command "apk update"
    sudo virt-customize -v -x -a $qcow_file --run-command "apk add --no-cache openssh-server curl wget sudo"
    sudo virt-customize -v -x -a $qcow_file --run-command "apk add --no-cache qemu-guest-agent"
    
    # 配置SSH
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    
    # 启用服务 (Alpine使用OpenRC)
    sudo virt-customize -v -x -a $qcow_file --run-command "rc-update add sshd default"
    sudo virt-customize -v -x -a $qcow_file --run-command "rc-update add qemu-guest-agent default"
    
    # 配置cloud-init
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg"

elif [[ "$qcow_file" == *"arch"* || "$qcow_file" == *"Arch"* ]]; then
    echo "检测到Arch Linux系统，开始配置..."
    
    # 启用SSH密码认证
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg"
    
    # 启用root登录
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg"
    
    # 安装必要软件包
    sudo virt-customize -v -x -a $qcow_file --run-command "pacman -Sy --noconfirm --needed curl wget sudo openssh"
    sudo virt-customize -v -x -a $qcow_file --run-command "pacman -Sy --noconfirm --needed qemu-guest-agent"
    
    # 启用服务
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable sshd"
    sudo virt-customize -v -x -a $qcow_file --run-command "systemctl enable qemu-guest-agent"

else
    echo "未识别的系统类型，使用通用配置..."
    
    # 通用SSH配置
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config"
    
    # 通用cloud-init配置
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg" || echo "cloud-init配置可能不存在"
    sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg" || echo "cloud-init配置可能不存在"
fi

# 通用配置 - 适用于所有系统
echo "应用通用配置..."

# 设置root密码
sudo virt-customize -v -x -a $qcow_file --run-command "echo root:oneclickvirt | chpasswd"

# 优化网络配置以支持PVE环境
echo "优化PVE网络配置..."
sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#AddressFamily any/AddressFamily any/g' /etc/ssh/sshd_config"
sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config"
sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#ListenAddress ::/ListenAddress ::/g' /etc/ssh/sshd_config"
sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config"

# 优化内核参数以支持虚拟化和可能的硬件直通
echo "优化虚拟化配置..."
sudo virt-customize -v -x -a $qcow_file --run-command "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf" || echo "sysctl配置失败"
sudo virt-customize -v -x -a $qcow_file --run-command "echo 'vm.swappiness = 10' >> /etc/sysctl.conf" || echo "sysctl配置失败"

# 禁用不必要的服务以减少资源消耗
echo "优化系统性能..."
sudo virt-customize -v -x -a $qcow_file --run-command "systemctl disable ModemManager || echo 'ModemManager不存在'"
sudo virt-customize -v -x -a $qcow_file --run-command "systemctl disable NetworkManager-wait-online || echo 'NetworkManager-wait-online不存在'"

# 创建motd信息
sudo virt-customize -v -x -a $qcow_file --run-command "echo '' > /etc/motd"
sudo virt-customize -v -x -a $qcow_file --run-command "echo 'PVE KVM Image - Optimized for Proxmox Virtual Environment' >> /etc/motd"
sudo virt-customize -v -x -a $qcow_file --run-command "echo 'Source: Official distribution images' >> /etc/motd"
sudo virt-customize -v -x -a $qcow_file --run-command "echo 'Modified from https://github.com/oneclickvirt/pve_kvm_images' >> /etc/motd"
sudo virt-customize -v -x -a $qcow_file --run-command "echo 'Related repo https://github.com/spiritLHLS/pve' >> /etc/motd"
sudo virt-customize -v -x -a $qcow_file --run-command "echo '--by https://t.me/spiritlhl' >> /etc/motd"
sudo virt-customize -v -x -a $qcow_file --run-command "echo '' >> /etc/motd"
sudo virt-customize -v -x -a $qcow_file --run-command "echo 'Default login: root / oneclickvirt' >> /etc/motd"
sudo virt-customize -v -x -a $qcow_file --run-command "echo 'Please change the password after first login!' >> /etc/motd"
sudo virt-customize -v -x -a $qcow_file --run-command "echo '' >> /etc/motd"

# 配置grub以支持串口控制台（便于PVE管理）
echo "配置串口控制台支持..."
sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"console=tty0 console=ttyS0,115200\"/g' /etc/default/grub" || echo "GRUB配置可能不存在"
sudo virt-customize -v -x -a $qcow_file --run-command "sed -i 's/GRUB_TERMINAL=console/GRUB_TERMINAL=\"console serial\"/g' /etc/default/grub" || echo "GRUB配置可能不存在"
sudo virt-customize -v -x -a $qcow_file --run-command "echo 'GRUB_SERIAL_COMMAND=\"serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1\"' >> /etc/default/grub" || echo "GRUB配置可能不存在"

# 更新grub配置
sudo virt-customize -v -x -a $qcow_file --run-command "update-grub" || sudo virt-customize -v -x -a $qcow_file --run-command "grub2-mkconfig -o /boot/grub2/grub.cfg" || echo "GRUB更新失败，可能使用不同的引导程序"

# 清理临时文件和缓存
echo "清理系统..."
sudo virt-customize -v -x -a $qcow_file --run-command "apt-get clean" || echo "apt清理失败"
sudo virt-customize -v -x -a $qcow_file --run-command "dnf clean all" || echo "dnf清理失败"
sudo virt-customize -v -x -a $qcow_file --run-command "pacman -Sc --noconfirm" || echo "pacman清理失败"
sudo virt-customize -v -x -a $qcow_file --run-command "apk cache clean" || echo "apk清理失败"
sudo virt-customize -v -x -a $qcow_file --run-command "rm -rf /tmp/* /var/tmp/*" || echo "临时文件清理失败"
sudo virt-customize -v -x -a $qcow_file --run-command "rm -rf /var/log/* /var/cache/*" || echo "日志缓存清理失败"

echo "创建备份..."
cp $qcow_file ${qcow_file}.bak

echo "复制新文件..."
cp $qcow_file ${qcow_file}.tmp

echo "覆盖原文件..."
mv ${qcow_file}.tmp $qcow_file
rm -rf *.bak

echo "$qcow_file修改完成"
echo "镜像已优化用于PVE环境，支持硬件直通和串口控制台"
