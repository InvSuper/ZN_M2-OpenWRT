#!/bin/bash

# 修改默认IP（保留）
sed -i 's/192.168.100.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# ==========================================
# 【核心】先删旧源，再加新源（避免重复）
# ==========================================
# 1. 先删除 feeds.conf.default 里自带的 packages/luci 行
sed -i '/src-git packages/d' feeds.conf.default
sed -i '/src-git luci/d' feeds.conf.default

# 2. 再添加你需要的 Feeds 源（现在不会重复了）
echo "src-git packages https://github.com/immortalwrt/packages.git" >> feeds.conf.default
echo "src-git luci https://github.com/immortalwrt/luci.git" >> feeds.conf.default
echo "src-git nss_packages https://github.com/LiBwrt/nss-packages.git" >> feeds.conf.default

# 3. 更新并安装 Feeds（必须执行）
./scripts/feeds update -a
./scripts/feeds install -a
