#!/bin/bash

# 修改默认IP（保留你原文件的配置：192.168.0.1）
sed -i 's/192.168.100.1/192.168.0.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 移除要替换的包（仅保留smartdns/wechatpush相关移除，避免冲突）
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-serverchan
# 新增bandix旧包清理（避免冲突）
rm -rf feeds/luci/applications/luci-app-bandix

# Git稀疏克隆，只克隆指定目录到本地（保留你原文件的函数，无修改）
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# ===================== 新增你要求的6个插件（核心修改，bandix已修正） =====================
# 1. SmartDNS
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# 2. AdGuard Home
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome

# 3. Tailscale
git clone --depth=1 https://github.com/immortalwrt/luci-app-tailscale package/luci-app-tailscale

# 4. Turbo ACC 网络加速
git clone --depth=1 https://github.com/chenmozhijin/turboacc package/turboacc

# 5. Bandix 流量监控（包名修正为bandix）
git clone --depth=1 https://github.com/brvphoenix/luci-app-bandix package/luci-app-bandix

# 6. WeChatPush 微信推送（替换原serverchan）
git clone --depth=1 -b openwrt-18.06 https://github.com/tty228/luci-app-wechatpush package/luci-app-wechatpush

# 以下为你原文件保留的注释/默认配置（无修改）
# 添加额外插件
# git_sparse_clone master https://github.com/sundaqiang/openwrt-packages luci-app-wolplus
# git_sparse_clone main https://github.com/nikkinikki-org/OpenWrt-nikki nikki
# git_sparse_clone main https://github.com/nikkinikki-org/OpenWrt-nikki luci-app-nikki
# 添加nikki
# add feed
# echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> "feeds.conf.default"
# # update & install feeds
# ./scripts/feeds update -a
# ./scripts/feeds install -a
# # make package
# make package/luci-app-nikki/compile

# 科学上网插件（注释保留，无内容）

# Themes（注释保留，无内容）

# 修改本地时间格式
# sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本为编译日期
# date_version=$(date +"%y.%m.%d")
# orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
# sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings

# 原文件收尾逻辑（保留）
./scripts/feeds update -a
./scripts/feeds install -a
