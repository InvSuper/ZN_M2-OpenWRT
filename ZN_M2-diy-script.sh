#!/bin/bash

# 设置工作目录
OPENWRT_DIR=$(pwd)

# 修改默认IP
sed -i 's/192.168.1.1/192.168.0.1/g' "$OPENWRT_DIR"/package/base-files/files/bin/config_generate

# 适配兆能M2 1G内存（替换设备树内存参数）
DTS_FILE=$(find "$OPENWRT_DIR"/target/linux/qualcommax/dts -name "*zn*m2*" -o -name "*m2*" | grep -i zn | head -1)
if [ -z "$DTS_FILE" ]; then
  DTS_FILE=$(find "$OPENWRT_DIR"/target/linux/qualcommax/dts -name "*mango*" | head -1)
fi
if [ -f "$DTS_FILE" ]; then
  sed -i 's/reg = <0x40000000 0x20000000>/reg = <0x40000000 0x40000000>/g' "$DTS_FILE"
fi

# 执行 mbedtls 修复脚本（如果存在）
if [ -f "$GITHUB_WORKSPACE/scripts/fix_mbedtls.sh" ]; then
  chmod +x "$GITHUB_WORKSPACE/scripts/fix_mbedtls.sh"
  "$GITHUB_WORKSPACE/scripts/fix_mbedtls.sh"
fi

# 快速添加Tailscale
# 拉取Tailscale主程序
git clone --depth=1 --filter=blob:none https://github.com/GuNanOvO/openwrt-tailscale "$OPENWRT_DIR"/package/tailscale

# 拉取Tailscale Luci界面
git clone --depth=1 --filter=blob:none https://github.com/asvow/luci-app-tailscale "$OPENWRT_DIR"/package/luci-app-tailscale

# 快速添加Bandix
# 拉取Bandix主程序
git clone --depth=1 --filter=blob:none https://github.com/timsaya/openwrt-bandix "$OPENWRT_DIR"/package/bandix

# 拉取Bandix Luci界面
git clone --depth=1 --filter=blob:none https://github.com/timsaya/luci-app-bandix "$OPENWRT_DIR"/package/luci-app-bandix

# 快速添加AdGuard Home
# 拉取AdGuard Home Luci界面 (使用 rufengsuixing 版本，版本格式更兼容)
git clone --depth=1 --filter=blob:none https://github.com/rufengsuixing/luci-app-adguardhome "$OPENWRT_DIR"/package/luci-app-adguardhome

# 拉取AdGuard Home主程序
git clone --depth=1 --filter=blob:none https://github.com/AdguardTeam/AdGuardHome "$OPENWRT_DIR"/package/adguardhome

# 创建OPKG配置文件
mkdir -p "$OPENWRT_DIR"/package/base-files/files/etc/opkg

cat > "$OPENWRT_DIR"/package/base-files/files/etc/opkg/opkg.conf << 'EOF'
dest root /
dest ram /tmp
lists_dir ext /var/opkg-lists
option overlay_root /overlay
option check_signature 0

# 主要软件源 - 使用25.12版本软件源
src/gz openwrt_core https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/base
src/gz openwrt_routing https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/routing
src/gz openwrt_packages https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/packages
src/gz openwrt_luci https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/luci
src/gz openwrt_small_flash https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/small_flash
src/gz openwrt_video https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/video
EOF


