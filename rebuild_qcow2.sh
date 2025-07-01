#!/bin/bash
# Enhanced GitHub Runner compatible image processing script
set -e

qcow_file=$1

if [ -z "$qcow_file" ]; then
    echo "使用方法: $0 <image_file>"
    exit 1
fi

echo "================================================="
echo "处理文件: $qcow_file (增强版本)"
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

# 处理压缩文件
if [[ "$qcow_file" == *.tar.xz ]]; then
    echo "🗜️  检测到tar.xz压缩文件，正在解压..."
    tar -tf "$qcow_file" | head -5
    tar -xf "$qcow_file"
    extracted_file=$(tar -tf "$qcow_file" | grep -E '\.(img|qcow2)$' | head -1)
    if [ -n "$extracted_file" ] && [ -f "$extracted_file" ]; then
        rm "$qcow_file"
        qcow_file="$extracted_file"
        echo "✅ 解压完成，新文件: $qcow_file"
    else
        echo "❌ 解压失败或未找到镜像文件"
        exit 1
    fi
elif [[ "$qcow_file" == *.xz ]]; then
    echo "🗜️  检测到xz压缩文件，正在解压..."
    xz -d "$qcow_file"
    qcow_file="${qcow_file%.xz}"
    echo "✅ 解压完成，新文件: $qcow_file"
fi

# 检查是否为有效的镜像文件
if ! qemu-img info "$qcow_file" > /dev/null 2>&1; then
    echo "❌ 不是有效的镜像文件: $qcow_file"
    exit 1
fi

echo "✅ 镜像文件验证通过"

# 显示镜像详细信息
echo "📋 镜像详细信息:"
qemu-img info "$qcow_file"

# 创建备份
echo "💾 创建备份..."
cp "$qcow_file" "${qcow_file}.backup"

# 增强的发行版检测
detect_distro() {
    local filename=$(basename "$1" | tr '[:upper:]' '[:lower:]')
    
    case "$filename" in
        *ubuntu*|*noble*|*jammy*|*focal*) echo "ubuntu" ;;
        *debian*) echo "debian" ;;
        *almalinux*|*alma*) echo "almalinux" ;;
        *rocky*) echo "rocky" ;;
        *centos*) echo "centos" ;;
        *fedora*) echo "fedora" ;;
        *arch*) echo "arch" ;;
        *alpine*) echo "alpine" ;;
        *opensuse*|*suse*) echo "opensuse" ;;
        *oracle*|*ol[0-9]*) echo "oracle" ;;
        *kali*) echo "kali" ;;
        *freebsd*) echo "freebsd" ;;
        *gentoo*) echo "gentoo" ;;
        *void*) echo "void" ;;
        *nixos*) echo "nixos" ;;
        *) echo "unknown" ;;
    esac
}

distro=$(detect_distro "$qcow_file")
echo "🔍 检测到发行版: $distro"

# 使用virt-customize进行配置
if command -v virt-customize &> /dev/null; then
    echo "🛠️  使用virt-customize进行配置..."
    
    # 设置环境变量
    export LIBGUESTFS_BACKEND=direct
    
    # 基本SSH配置 (适用于大多数Linux发行版)
    if [ "$distro" != "freebsd" ]; then
        echo "🔐 配置SSH访问..."
        virt-customize -a "$qcow_file" \
            --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
            --run-command "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
            --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
            --run-command "sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
            --run-command "sed -i 's/#PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
            --run-command "sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
            2>/dev/null || echo "⚠️  SSH配置可能失败，继续处理..."
        
        # 设置root密码
        echo "🔑 设置root密码..."
        virt-customize -a "$qcow_file" \
            --run-command "echo root:oneclickvirt | chpasswd" \
            2>/dev/null || echo "⚠️  密码设置可能失败"
    fi
    
    # 针对不同发行版的特定配置
    case $distro in
        "ubuntu"|"debian")
            echo "🐧 配置Ubuntu/Debian系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/lock_passwd:[[:space:]]*true/lock_passwd: false/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "apt-get update && apt-get install -y qemu-guest-agent 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  Ubuntu/Debian配置可能失败"
            ;;
        "almalinux"|"rocky"|"centos"|"fedora"|"oracle")
            echo "🎩 配置RHEL系系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/disable_root:[[:space:]]*1/disable_root: 0/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config 2>/dev/null || true" \
                --run-command "dnf install -y qemu-guest-agent 2>/dev/null || yum install -y qemu-guest-agent 2>/dev/null || true" \
                --run-command "systemctl enable qemu-guest-agent 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  RHEL系统配置可能失败"
            ;;
        "arch")
            echo "🏹 配置Arch Linux系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "pacman -Sy --noconfirm qemu-guest-agent 2>/dev/null || true" \
                --run-command "systemctl enable qemu-guest-agent 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  Arch配置可能失败"
            ;;
        "alpine")
            echo "🏔️  配置Alpine Linux系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "apk add --no-cache qemu-guest-agent 2>/dev/null || true" \
                --run-command "rc-update add qemu-guest-agent default 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  Alpine配置可能失败"
            ;;
        "opensuse")
            echo "🦎 配置openSUSE系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "zypper install -y qemu-guest-agent 2>/dev/null || true" \
                --run-command "systemctl enable qemu-guest-agent 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  openSUSE配置可能失败"
            ;;
        "kali")
            echo "🐉 配置Kali Linux系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "apt-get update && apt-get install -y qemu-guest-agent 2>/dev/null || true" \
                --run-command "systemctl enable qemu-guest-agent 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  Kali配置可能失败"
            ;;
        "freebsd")
            echo "😈 配置FreeBSD系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i '' 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
                --run-command "sed -i '' 's/#PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
                --run-command "echo root:oneclickvirt | chpasswd 2>/dev/null || true" \
                --run-command "pkg install -y qemu-guest-agent 2>/dev/null || true" \
                --run-command "sysrc qemu_guest_agent_enable=YES 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  FreeBSD配置可能失败"
            ;;
        "void")
            echo "🕳️  配置Void Linux系统..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/ssh_pwauth:[[:space:]]*false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "sed -i 's/disable_root:[[:space:]]*true/disable_root: false/g' /etc/cloud/cloud.cfg 2>/dev/null || true" \
                --run-command "xbps-install -Sy qemu-guest-agent 2>/dev/null || true" \
                --run-command "ln -s /etc/sv/qemu-guest-agent /var/service/ 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  Void配置可能失败"
            ;;
        "nixos")
            echo "❄️  配置NixOS系统..."
            # NixOS需要特殊处理，通过配置文件
            virt-customize -a "$qcow_file" \
                --run-command "mkdir -p /etc/nixos 2>/dev/null || true" \
                --write "/etc/nixos/pve-config.nix:{ config, pkgs, ... }: {
  services.qemuGuest.enable = true;
  services.openssh = {
    enable = true;
    permitRootLogin = \"yes\";
    passwordAuthentication = true;
  };
  users.users.root.password = \"oneclickvirt\";
}" \
                2>/dev/null || echo "⚠️  NixOS配置可能失败"
            ;;
        "gentoo")
            echo "🐧 配置Gentoo系统..."
            # Gentoo通常是stage3，需要特殊处理
            echo "⚠️  Gentoo需要手动配置，跳过自动配置"
            ;;
        *)
            echo "❓ 未知发行版，使用通用配置..."
            virt-customize -a "$qcow_file" \
                --run-command "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
                --run-command "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config 2>/dev/null || true" \
                --run-command "echo root:oneclickvirt | chpasswd 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  通用配置可能失败"
            ;;
    esac
    
    # 添加通用的MOTD信息
    echo "📄 添加MOTD信息..."
    motd_content="PVE KVM Image - Optimized for Proxmox Virtual Environment
Source: Official $distro distribution images
Modified from https://github.com/alicorns-dev/oneclickvirt-pve-kvm-images
Default login: root / oneclickvirt
Please change the password after first login!

Detected Distribution: $distro
Processing Date: $(date)
"
    
    virt-customize -a "$qcow_file" \
        --write "/etc/motd:$motd_content" \
        2>/dev/null || echo "⚠️  MOTD设置可能失败"
    
    # 启用qemu-guest-agent服务 (如果系统支持systemd)
    if [ "$distro" != "freebsd" ] && [ "$distro" != "alpine" ] && [ "$distro" != "void" ]; then
        echo "🔌 启用qemu-guest-agent服务..."
        virt-customize -a "$qcow_file" \
            --run-command "systemctl enable qemu-guest-agent 2>/dev/null || true" \
            2>/dev/null || echo "⚠️  服务启用可能失败"
    fi
    
    # 清理系统缓存
    echo "🧹 清理系统缓存..."
    case $distro in
        "ubuntu"|"debian"|"kali")
            virt-customize -a "$qcow_file" \
                --run-command "apt-get clean 2>/dev/null || true" \
                --run-command "rm -rf /var/lib/apt/lists/* 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  Debian系清理失败"
            ;;
        "almalinux"|"rocky"|"centos"|"fedora"|"oracle")
            virt-customize -a "$qcow_file" \
                --run-command "dnf clean all 2>/dev/null || yum clean all 2>/dev/null || true" \
                --run-command "rm -rf /var/cache/dnf/* /var/cache/yum/* 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  RHEL系清理失败"
            ;;
        "arch")
            virt-customize -a "$qcow_file" \
                --run-command "pacman -Scc --noconfirm 2>/dev/null || true" \
                --run-command "rm -rf /var/cache/pacman/pkg/* 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  Arch清理失败"
            ;;
        "alpine")
            virt-customize -a "$qcow_file" \
                --run-command "apk cache clean 2>/dev/null || true" \
                --run-command "rm -rf /var/cache/apk/* 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  Alpine清理失败"
            ;;
        "opensuse")
            virt-customize -a "$qcow_file" \
                --run-command "zypper clean -a 2>/dev/null || true" \
                --run-command "rm -rf /var/cache/zypp/* 2>/dev/null || true" \
                2>/dev/null || echo "⚠️  openSUSE清理失败"
            ;;
    esac
    
    # 清理通用临时文件
    virt-customize -a "$qcow_file" \
        --run-command "rm -rf /tmp/* /var/tmp/* 2>/dev/null || true" \
        --run-command "rm -rf /var/log/*.log /var/log/*/*.log 2>/dev/null || true" \
        --run-command "history -c 2>/dev/null || true" \
        2>/dev/null || echo "⚠️  通用清理可能失败"
    
else
    echo "⚠️  virt-customize不可用，跳过系统配置"
fi

# 使用qemu-img进行镜像优化
echo "📦 优化镜像格式..."

# 转换为更优化的qcow2格式
temp_file="${qcow_file}.optimized"

# 根据文件大小选择压缩级别
file_size_mb=$(du -m "$qcow_file" | cut -f1)
if [ "$file_size_mb" -gt 2048 ]; then
    # 大文件使用较低压缩级别以节省时间
    qemu-img convert -O qcow2 -c -o compression_type=zlib,cluster_size=64k "$qcow_file" "$temp_file"
else
    # 小文件使用更高压缩
    qemu-img convert -O qcow2 -c -o compression_type=zlib,cluster_size=64k,preallocation=metadata "$qcow_file" "$temp_file"
fi

# 检查优化后的文件
if [ -f "$temp_file" ]; then
    original_size=$(stat -c%s "$qcow_file")
    optimized_size=$(stat -c%s "$temp_file")
    
    echo "📊 优化结果:"
    echo "   原始大小: $(du -h "$qcow_file" | cut -f1)"
    echo "   优化大小: $(du -h "$temp_file" | cut -f1)"
    
    # 计算压缩比
    if [ "$original_size" -gt 0 ]; then
        compression_ratio=$(echo "scale=1; $optimized_size * 100 / $original_size" | bc 2>/dev/null || echo "N/A")
        echo "   压缩比: $compression_ratio%"
    fi
    
    # 使用优化后的文件
    echo "✅ 使用优化后的镜像"
    mv "$temp_file" "$qcow_file"
else
    echo "❌ 镜像优化失败"
fi

# 验证最终镜像
echo "🔍 验证最终镜像..."
if qemu-img check "$qcow_file" > /dev/null 2>&1; then
    echo "✅ 镜像验证通过"
else
    echo "⚠️  镜像验证失败，恢复备份"
    if [ -f "${qcow_file}.backup" ]; then
        mv "${qcow_file}.backup" "$qcow_file"
    fi
fi

# 显示最终文件信息
echo "📋 最终文件信息:"
final_size=$(du -h "$qcow_file" | cut -f1)
echo "   大小: $final_size"
echo "   发行版: $distro"

# 显示qemu-img详细信息
echo "📸 镜像详细信息:"
qemu-img info "$qcow_file" | head -15

# 检查文件大小是否符合要求 (最大3GB)
max_size=3221225472  # 3GB in bytes
actual_size=$(stat -c%s "$qcow_file")
if [ "$actual_size" -gt "$max_size" ]; then
    echo "⚠️  文件大小超过3GB限制 ($(du -h "$qcow_file" | cut -f1))，可能影响上传"
else
    echo "✅ 文件大小符合要求"
fi

# 清理备份文件
rm -f "${qcow_file}.backup"

echo "🎉 镜像处理完成: $qcow_file"
echo "🏷️  发行版: $distro"
echo "📏 最终大小: $final_size"
echo "================================================="
