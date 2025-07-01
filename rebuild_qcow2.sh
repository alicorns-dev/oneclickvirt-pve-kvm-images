#!/bin/bash
# GitHub Runner compatible image processing script
# 由于GitHub Runner没有KVM支持，我们使用替代方法

set -e

qcow_file=$1

if [ -z "$qcow_file" ]; then
    echo "使用方法: $0 <qcow2_file>"
    exit 1
fi

echo "================================================="
echo "处理文件: $qcow_file (GitHub Runner兼容版本)"
echo "================================================="

# 检查文件是否存在
if [ ! -f "$qcow_file" ]; then
    echo "❌ 文件不存在: $qcow_file"
    exit 1
fi

# 显示文件信息
echo "📁 原始文件信息:"
file_size=$(du -h "$qcow_file" | cut -f1)
echo "   大小: $file_size"
echo "   类型: $(file "$qcow_file")"

# 检查是否为有效的qcow2文件
if ! qemu-img info "$qcow_file" > /dev/null 2>&1; then
    echo "❌ 不是有效的qcow2文件: $qcow_file"
    exit 1
fi

echo "✅ qcow2文件验证通过"

# 显示镜像详细信息
echo "📋 镜像详细信息:"
qemu-img info "$qcow_file"

# 创建备份
echo "💾 创建备份..."
cp "$qcow_file" "${qcow_file}.backup"

# 由于GitHub Runner限制，我们采用以下方法:
# 1. 使用qemu-img进行基本的镜像优化
# 2. 通过guestmount挂载文件系统进行修改 (如果可用)
# 3. 或者使用virt-customize的有限功能

echo "🔧 开始镜像优化..."

# 方法1: 尝试使用virt-customize (可能受限)
if command -v virt-customize &> /dev/null; then
    echo "🛠️  使用virt-customize进行配置..."
    
    # 检测发行版类型
    distro="unknown"
    if [[ "$qcow_file" == *"ubuntu"* || "$qcow_file" == *"noble"* || "$qcow_file" == *"jammy"* ]]; then
        distro="ubuntu"
    elif [[ "$qcow_file" == *"debian"* ]]; then
        distro="debian"
    elif [[ "$qcow_file" == *"almalinux"* || "$qcow_file" == *"AlmaLinux"* ]]; then
        distro="almalinux"
    elif [[ "$qcow_file" == *"rocky"* || "$qcow_file" == *"Rocky"* ]]; then
        distro="rocky"
    elif [[ "$qcow_file" == *"centos"* || "$qcow_file" == *"CentOS"* ]]; then
        distro="centos"
    elif [[ "$qcow_file" == *"fedora"* || "$qcow_file" == *"Fedora"* ]]; then
        distro="fedora"
    elif [[ "$qcow_file" == *"arch"* || "$qcow_file" == *"Arch"* ]]; then
        distro="arch"
    elif [[ "$qcow_file" == *"alpine"* || "$qcow_file" == *"Alpine"* ]]; then
        distro="alpine"
    fi
    
    echo "🔍 检测到发行版: $distro"
    
    # 设置环境变量
    export LIBGUESTFS_BACKEND=direct
    
    # 基本SSH配置 (适用于所有发行版)
    echo "🔐 配置SSH访问..."
    
    # 尝试基本的SSH配置
    virt-customize -a "$qcow_file" \
        --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config" \
        --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config" \
        --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config" \
        --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config" \
        2>/dev/null || echo "⚠️  SSH配置可能失败，继续处理..."
    
    # 设置root密码
    echo "🔑 设置root密码..."
    virt-customize -a "$qcow_file" \
        --run-command "echo root:oneclickvirt | chpasswd" \
        2>/dev/null || echo "⚠️  密码设置可能失败"
    
    # 针对不同发行版的特定配置
    case $distro in
        "ubuntu"|"debian")
            echo "🐧 配置Ubuntu/Debian系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg" \
                --run-command "sed -i 's/lock_passwd:[[:space:]]*true/lock_passwd: false/g' /etc/cloud/cloud.cfg" \
                2>/dev/null || echo "⚠️  Cloud-init配置可能失败"
            ;;
        "almalinux"|"rocky"|"centos"|"fedora")
            echo "🎩 配置RHEL系系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg" \
                --run-command "sed -i 's/disable_root:[[:space:]]*1/disable_root: 0/g' /etc/cloud/cloud.cfg" \
                --run-command "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config" \
                2>/dev/null || echo "⚠️  RHEL系统配置可能失败"
            ;;
        "arch")
            echo "🏹 配置Arch Linux系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg" \
                2>/dev/null || echo "⚠️  Arch配置可能失败"
            ;;
        "alpine")
            echo "🏔️  配置Alpine Linux系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg" \
                2>/dev/null || echo "⚠️  Alpine配置可能失败"
            ;;
    esac
    
    # 添加PVE优化的motd
    echo "📄 添加MOTD信息..."
    virt-customize -a "$qcow_file" \
        --run-command "echo 'PVE KVM Image - Optimized for Proxmox Virtual Environment' > /etc/motd" \
        --run-command "echo 'Source: Official distribution images' >> /etc/motd" \
        --run-command "echo 'Modified from https://github.com/alicorns-dev/oneclickvirt-pve-kvm-images' >> /etc/motd" \
        --run-command "echo 'Default login: root / oneclickvirt' >> /etc/motd" \
        --run-command "echo 'Please change the password after first login!' >> /etc/motd" \
        2>/dev/null || echo "⚠️  MOTD设置可能失败"
    
else
    echo "⚠️  virt-customize不可用，跳过系统配置"
fi

# 方法2: 使用qemu-img进行镜像优化
echo "📦 优化镜像格式..."

# 转换为更优化的qcow2格式
temp_file="${qcow_file}.optimized"
qemu-img convert -O qcow2 -c "$qcow_file" "$temp_file"

# 检查优化后的文件
if [ -f "$temp_file" ]; then
    original_size=$(stat -c%s "$qcow_file")
    optimized_size=$(stat -c%s "$temp_file")
    
    echo "📊 优化结果:"
    echo "   原始大小: $(du -h "$qcow_file" | cut -f1)"
    echo "   优化大小: $(du -h "$temp_file" | cut -f1)"
    
    # 如果优化后的文件更小或大小相近，则使用优化版本
    if [ "$optimized_size" -le "$original_size" ]; then
        echo "✅ 使用优化后的镜像"
        mv "$temp_file" "$qcow_file"
    else
        echo "ℹ️  保持原始镜像"
        rm -f "$temp_file"
    fi
else
    echo "❌ 镜像优化失败"
fi

# 验证最终镜像
echo "🔍 验证最终镜像..."
if qemu-img check "$qcow_file" > /dev/null 2>&1; then
    echo "✅ 镜像验证通过"
else
    echo "⚠️  镜像验证失败，恢复备份"
    mv "${qcow_file}.backup" "$qcow_file"
fi

# 显示最终文件信息
echo "📋 最终文件信息:"
final_size=$(du -h "$qcow_file" | cut -f1)
echo "   大小: $final_size"
qemu-img info "$qcow_file" | head -10

# 清理备份文件
rm -f "${qcow_file}.backup"

echo "🎉 镜像处理完成: $qcow_file"
echo "================================================="
