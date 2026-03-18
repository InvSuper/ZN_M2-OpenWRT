#!/bin/bash

# 修改默认IP
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# 适配兆能M2 1G内存（替换设备树内存参数）
DTS_FILE=$(find openwrt/target/linux/qualcommax/dts -name "*zn*m2*" -o -name "*m2*" | grep -i zn | head -1)
if [ -z "$DTS_FILE" ]; then
  DTS_FILE=$(find openwrt/target/linux/qualcommax/dts -name "*mango*" | head -1)
fi
if [ -f "$DTS_FILE" ]; then
  sed -i 's/reg = <0x40000000 0x20000000>/reg = <0x40000000 0x40000000>/g' "$DTS_FILE"
fi

# 执行 mbedtls 修复脚本（如果存在）
if [ -f "$GITHUB_WORKSPACE/scripts/fix_mbedtls.sh" ]; then
  chmod +x $GITHUB_WORKSPACE/scripts/fix_mbedtls.sh
  $GITHUB_WORKSPACE/scripts/fix_mbedtls.sh
fi

# 快速添加Tailscale
git clone --depth=1 --filter=blob:none https://github.com/immortalwrt/packages.git tmp-packages
if [ -d "tmp-packages/net/tailscale" ]; then
  cp -r tmp-packages/net/tailscale package/
fi
if [ -d "tmp-packages/luci/applications/luci-app-tailscale" ]; then
  cp -r tmp-packages/luci/applications/luci-app-tailscale package/
fi
rm -rf tmp-packages

# 快速添加Turbo ACC
git clone --depth=1 --filter=blob:none -b openwrt-23.05 https://github.com/immortalwrt/immortalwrt tmp-immortalwrt
if [ -d "tmp-immortalwrt/package/turboacc" ]; then
  cp -r tmp-immortalwrt/package/turboacc package/
fi
rm -rf tmp-immortalwrt

# 快速添加Bandix
git clone --depth=1 --filter=blob:none https://github.com/liuran001/openwrt-packages tmp-bandix
if [ -d "tmp-bandix/bandix" ]; then
  cp -r tmp-bandix/bandix package/
fi
if [ -d "tmp-bandix/luci-app-bandix" ]; then
  cp -r tmp-bandix/luci-app-bandix package/
elif [ -d "tmp-bandix/luci-app-bandwidthd" ]; then
  cp -r tmp-bandix/luci-app-bandwidthd package/
fi
rm -rf tmp-bandix

# 创建OPKG配置文件
mkdir -p package/base-files/files/etc/opkg

cat > package/base-files/files/etc/opkg/opkg.conf << 'EOF'
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


