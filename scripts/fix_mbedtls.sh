#!/bin/bash
# ============================================================
# fix_mbedtls.sh
# 修复 OpenWrt 编译 mbedtls 时 memset 内联失败的问题
#
# 执行阶段：feeds 更新完成后、执行 make 编译之前
#
# 典型 CI 流程位置：
#   1. git clone openwrt
#   2. ./scripts/feeds update -a
#   3. ./scripts/feeds install -a
#   4. *** 在此处执行本脚本 ***
#   5. make defconfig
#   6. make -j$(nproc)
# ============================================================

set -e

# ---------- 配置项（按实际路径修改） ----------
OPENWRT_DIR="${OPENWRT_DIR:-$(pwd)}"
MBEDTLS_MK="${OPENWRT_DIR}/package/libs/mbedtls/Makefile"
PATCH_MARKER="# FIX: disable _FORTIFY_SOURCE to avoid memset inline error with GCC14"

# ---------- 检查目录 ----------
if [ ! -f "${MBEDTLS_MK}" ]; then
    echo "[ERROR] 找不到文件: ${MBEDTLS_MK}"
    echo "        请在 OpenWrt 根目录下运行本脚本，或设置 OPENWRT_DIR 环境变量。"
    exit 1
fi

# ---------- 幂等检查：避免重复写入 ----------
if grep -q "${PATCH_MARKER}" "${MBEDTLS_MK}"; then
    echo "[INFO] 修复已存在，跳过写入。"
    exit 0
fi

echo "[INFO] 正在修改: ${MBEDTLS_MK}"

# ---------- 备份原始文件 ----------
cp "${MBEDTLS_MK}" "${MBEDTLS_MK}.bak"
echo "[INFO] 原始文件已备份至: ${MBEDTLS_MK}.bak"

# ---------- 写入修复：在 include $(INCLUDE_DIR)/package.mk 之前插入 ----------
# TARGET_CFLAGS 会被 OpenWrt 构建系统传入最终编译命令
sed -i "/^include \$(INCLUDE_DIR)\/package\.mk/i \\
${PATCH_MARKER}\\
TARGET_CFLAGS += -U_FORTIFY_SOURCE\\
" "${MBEDTLS_MK}"

# ---------- 验证写入结果 ----------
if grep -q "U_FORTIFY_SOURCE" "${MBEDTLS_MK}"; then
    echo "[OK] 修复成功写入。"
else
    echo "[ERROR] 写入失败，请手动在 ${MBEDTLS_MK} 中添加："
    echo "        TARGET_CFLAGS += -U_FORTIFY_SOURCE"
    exit 1
fi

echo ""
echo "============================================================"
echo " 修复完成！接下来按正常流程继续编译："
echo "   make defconfig"
echo "   make package/libs/mbedtls/compile V=s   # 单独验证"
echo "   make -j\$(nproc)                          # 完整编译"
echo "============================================================"