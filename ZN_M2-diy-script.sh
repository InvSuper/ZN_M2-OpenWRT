#!/bin/bash

# --------------------------
# 1. 修改默认IP（保留）
# --------------------------
sed -i 's/192.168.100.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# --------------------------
# 2. 【核心】直接覆盖 feeds.conf.default
# --------------------------
cat > feeds.conf.default <<'EOF'
src-git packages https://github.com/immortalwrt/packages.git
src-git luci https://github.com/immortalwrt/luci.git
src-git nss_packages https://github.com/LiBwrt/nss-packages.git
EOF
# 👆 【修复】单独一行，只写 EOF，后面不加任何注释/空格！

# --------------------------
# 3. 更新并安装 Feeds
# --------------------------
./scripts/feeds update -a
./scripts/feeds install -a
