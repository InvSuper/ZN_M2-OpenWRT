#!/bin/bash

# 修改默认IP（保留）
sed -i 's/192.168.100.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# ==========================================
# 【核心】添加 LiBwrt 官方 Feeds 源
# ==========================================
echo "src-git packages https://github.com/immortalwrt/packages.git" >> feeds.conf.default
echo "src-git luci https://github.com/immortalwrt/luci.git" >> feeds.conf.default
echo "src-git nss_packages https://github.com/LiBwrt/nss-packages.git" >> feeds.conf.default

# 更新并安装 Feeds（必须执行，让系统识别新的插件源）
./scripts/feeds update -a
./scripts/feeds install -a
