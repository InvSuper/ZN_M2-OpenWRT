#!/bin/bash

# 修改默认IP
sed -i 's/192.168.1.1/192.168.0.1/g' package/base-files/files/bin/config_generate  # 将默认IP从192.168.1.1改为192.168.0.1

# 适配兆能M2 1G内存（替换设备树内存参数）
# 查找zn_m2设备树文件
DTS_FILE=$(find openwrt/target/linux/qualcommax/dts -name "*zn*m2*" -o -name "*m2*" | grep -i zn | head -1)  # 查找ZN M2设备树文件

# 如果没找到zn_m2，尝试找mango设备树
if [ -z "$DTS_FILE" ]; then
  DTS_FILE=$(find openwrt/target/linux/qualcommax/dts -name "*mango*" | head -1)  # 找不到ZN M2时尝试找Mango设备树
fi

# 检查文件是否存在
if [ -f "$DTS_FILE" ]; then
  echo "找到设备树文件: $DTS_FILE"
  # 修改内存配置（从512MB改为1GB）
  sed -i 's/reg = <0x40000000 0x20000000>/reg = <0x40000000 0x40000000>/g' "$DTS_FILE"  # 将内存从512MB(0x20000000)改为1GB(0x40000000)
  echo "已修改内存配置为1GB"
else
  echo "警告: 未找到设备树文件"
fi

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd  # 注释掉的命令：将默认Shell改为zsh

# TTYD 免登录
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config  # 注释掉的命令：设置TTYD免登录

# 移除要替换的包
# rm -rf feeds/packages/net/mosdns  # 注释掉的命令：移除mosdns
# rm -rf feeds/packages/net/msd_lite  # 注释掉的命令：移除msd_lite
# rm -rf feeds/packages/net/smartdns  # 注释掉的命令：移除smartdns
# rm -rf feeds/luci/themes/luci-theme-argon  # 注释掉的命令：移除argon主题
# rm -rf feeds/luci/themes/luci-theme-netgear  # 注释掉的命令：移除netgear主题
# rm -rf feeds/luci/applications/luci-app-mosdns  # 注释掉的命令：移除mosdns LuCI界面
# rm -rf feeds/luci/applications/luci-app-netdata  # 注释掉的命令：移除netdata LuCI界面
# rm -rf feeds/luci/applications/luci-app-serverchan  # 注释掉的命令：移除serverchan LuCI界面

# --------------------------
# 【核心】执行 mbedtls 修复脚本，解决 memset 内联报错
# --------------------------
if [ -f "$GITHUB_WORKSPACE/scripts/fix_mbedtls.sh" ]; then
  chmod +x $GITHUB_WORKSPACE/scripts/fix_mbedtls.sh  # 给修复脚本添加执行权限
  $GITHUB_WORKSPACE/scripts/fix_mbedtls.sh  # 执行mbedtls修复脚本
else
  echo "警告: 未找到fix_mbedtls.sh脚本"
fi

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {  # 定义稀疏克隆函数
  branch="$1" repourl="$2" && shift 2  # 提取分支和仓库URL参数
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl  # 稀疏克隆仓库
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')  # 提取仓库目录名
  if [ -d "$repodir" ]; then
    cd $repodir && git sparse-checkout set $@  # 进入目录并设置稀疏检出
    if [ -d "$1" ]; then
      mv -f $@ ../package  # 将指定目录移动到package目录
    else
      echo "警告: 目录 $@ 不存在"
    fi
    cd .. && rm -rf $repodir  # 清理临时目录
  else
    echo "警告: 克隆失败，目录 $repodir 不存在"
  fi
}

# 添加额外插件
# git_sparse_clone master https://github.com/sundaqiang/openwrt-packages luci-app-wolplus  # 注释掉的命令：添加WOL+插件
# git_sparse_clone main https://github.com/nikkinikki-org/OpenWrt-nikki nikki  # 注释掉的命令：添加nikki
# git_sparse_clone main https://github.com/nikkinikki-org/OpenWrt-nikki luci-app-nikki  # 注释掉的命令：添加nikki LuCI界面
# 添加nikki
# add feed
# echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> "feeds.conf.default"  # 注释掉的命令：添加nikki源
# # update & install feeds
# ./scripts/feeds update -a  # 注释掉的命令：更新feeds
# ./scripts/feeds install -a  # 注释掉的命令：安装feeds
# # make package
# make package/luci-app-nikki/compile  # 注释掉的命令：编译nikki包

# Tailscale 异地组网
git clone --depth=1 https://github.com/immortalwrt/packages.git tmp-packages  # 克隆immortalwrt包仓库
if [ -d "tmp-packages/net/tailscale" ]; then
  cp -r tmp-packages/net/tailscale package/  # 复制tailscale包到本地
else
  echo "警告: tailscale目录不存在"
fi
if [ -d "tmp-packages/luci/applications/luci-app-tailscale" ]; then
  cp -r tmp-packages/luci/applications/luci-app-tailscale package/  # 复制tailscale LuCI界面到本地
else
  echo "警告: luci-app-tailscale目录不存在"
fi
rm -rf tmp-packages  # 清理临时目录

# Turbo ACC 网络加速
git_sparse_clone openwrt-23.05 https://github.com/immortalwrt/immortalwrt package/turboacc  # 稀疏克隆Turbo ACC包

# Bandix 流量监控
git clone --depth=1 https://github.com/liuran001/openwrt-packages package/openwrt-packages  # 克隆liuran001的包仓库
if [ -d "package/openwrt-packages/bandix" ]; then
  cp -r package/openwrt-packages/bandix package/  # 复制bandix包到本地
else
  echo "警告: bandix目录不存在"
fi
if [ -d "package/openwrt-packages/luci-app-bandwidthd" ]; then
  cp -r package/openwrt-packages/luci-app-bandwidthd package/  # 复制bandwidthd LuCI界面到本地
else
  echo "警告: luci-app-bandwidthd目录不存在"
fi
rm -rf package/openwrt-packages  # 清理临时目录


# 科学上网插件

# Themes


# SmartDNS
# git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns  # 注释掉的命令：克隆SmartDNS LuCI界面
# git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns  # 注释掉的命令：克隆SmartDNS

# 修改本地时间格式
# sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm  # 注释掉的命令：修改时间格式

# 修改版本为编译日期
# date_version=$(date +"%y.%m.%d")  # 注释掉的命令：获取当前日期
# orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')  # 注释掉的命令：获取原始版本号
# sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings  # 注释掉的命令：修改版本号

# 创建OPKG配置文件
mkdir -p package/base-files/files/etc/opkg  # 创建opkg配置目录

cat > package/base-files/files/etc/opkg/opkg.conf << 'EOF'  # 创建opkg.conf文件
dest root /  # 根安装目录
dest ram /tmp  # 临时安装目录
lists_dir ext /var/opkg-lists  # 包列表存储目录
option overlay_root /overlay  # overlay根目录
option check_signature 0  # 禁用签名检查

# 主要软件源 - 使用25.12版本软件源
src/gz openwrt_core https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/base  # 核心软件源
src/gz openwrt_routing https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/routing  # 路由软件源
src/gz openwrt_packages https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/packages  # 扩展软件源
src/gz openwrt_luci https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/luci  # LuCI软件源
src/gz openwrt_small_flash https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/small_flash  # 小闪存优化软件源
src/gz openwrt_video https://dl.openwrt.ai/packages-25.12/aarch64_cortex-a53/video  # 视频软件源
EOF

# 创建customfeeds.conf文件
cat > package/base-files/files/etc/opkg/customfeeds.conf << 'EOF'  # 创建customfeeds.conf文件
# add your custom package feeds here
#
# src/gz example_feed_name http://www.example.com/path/to/files
EOF

# 更新和安装feeds
if [ -f "openwrt/scripts/feeds" ]; then
  cd openwrt && ./scripts/feeds update -a  # 更新所有feeds
  ./scripts/feeds install -a  # 安装所有feeds
  cd ..
else
  echo "警告: 未找到scripts/feeds脚本"
fi
