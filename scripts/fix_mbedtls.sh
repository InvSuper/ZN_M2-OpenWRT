#!/bin/bash
# ============================================================
# fix_mbedtls.sh
# 修复 OpenWrt 编译 mbedtls 时 memset 内联失败的问题
#
# 根本原因：
#   1. 工具链将 -D_FORTIFY_SOURCE=1 硬编码注入，绕过 Kconfig
#   2. fortify/string.h 将 memset 标记为 always_inline
#   3. mbedtls CMakeLists.txt 开启 -Werror，内联警告变为错误
#
# 修复策略（双管齐下）：
#   A. 通过 CMAKE_OPTIONS 传入 -Wno-error，阻止警告升级为错误
#   B. 同时追加 -U_FORTIFY_SOURCE 放在所有参数最后，确保覆盖顺序
#
# 执行阶段：feeds install 之后、make 编译之前
# ============================================================

set -e

OPENWRT_DIR="${OPENWRT_DIR:-$(pwd)}"
MBEDTLS_MK="${OPENWRT_DIR}/package/libs/mbedtls/Makefile"
MARKER="# FIX-GCC14"

# ---------- 检查目录 ----------
if [ ! -f "${MBEDTLS_MK}" ]; then
    echo "[ERROR] 找不到文件: ${MBEDTLS_MK}"
    echo "        请在 OpenWrt 根目录下运行，或设置 OPENWRT_DIR 环境变量。"
    exit 1
fi

echo "[INFO] 目标文件: ${MBEDTLS_MK}"

# ---------- 幂等检查 ----------
if grep -q "FIX-GCC14" "${MBEDTLS_MK}"; then
    echo "[INFO] 修复已存在，跳过。"
    exit 0
fi

# ---------- 备份 ----------
cp "${MBEDTLS_MK}" "${MBEDTLS_MK}.bak"
echo "[INFO] 已备份至: ${MBEDTLS_MK}.bak"

# ---------- 打印 include 行辅助调试 ----------
echo "[DEBUG] Makefile 中 include 行如下："
grep -n "^include" "${MBEDTLS_MK}" || echo "  (未找到 include 行)"

# ---------- 核心修复内容 ----------
# CMAKE_OPTIONS: 通过 -Wno-error 阻止警告变错误（针对 -Werror）
# TARGET_CFLAGS: 末尾追加 -U_FORTIFY_SOURCE，确保在工具链注入的
#                -D_FORTIFY_SOURCE=1 之后生效（覆盖顺序靠后才有效）
FIX_CONTENT="${MARKER}: fix memset always_inline error with GCC14 + musl fortify
CMAKE_OPTIONS += -DCMAKE_C_FLAGS_INIT=\"-Wno-error\"
TARGET_CFLAGS += -Wno-error -U_FORTIFY_SOURCE"

# 优先插入到 cmake.mk include 行之前
if grep -q "include \$(INCLUDE_DIR)/cmake\.mk" "${MBEDTLS_MK}"; then
    sed -i "/include \$(INCLUDE_DIR)\/cmake\.mk/i ${FIX_CONTENT}\n" "${MBEDTLS_MK}"
    echo "[INFO] 已插入到 cmake.mk include 行之前。"
elif grep -q "include \$(INCLUDE_DIR)/package\.mk" "${MBEDTLS_MK}"; then
    sed -i "/include \$(INCLUDE_DIR)\/package\.mk/i ${FIX_CONTENT}\n" "${MBEDTLS_MK}"
    echo "[INFO] 已插入到 package.mk include 行之前。"
else
    # 兜底：追加到末尾
    printf "\n%s\n" "${FIX_CONTENT}" >> "${MBEDTLS_MK}"
    echo "[INFO] 已追加到 Makefile 末尾（兜底）。"
fi

# ---------- 验证 ----------
if grep -q "Wno-error" "${MBEDTLS_MK}"; then
    echo "[OK] 修复写入成功，内容如下："
    echo "---"
    grep -A3 "FIX-GCC14" "${MBEDTLS_MK}"
    echo "---"
else
    echo "[ERROR] 写入失败！请手动在 ${MBEDTLS_MK} 中添加以下内容："
    echo "  CMAKE_OPTIONS += -DCMAKE_C_FLAGS_INIT=\"-Wno-error\""
    echo "  TARGET_CFLAGS += -Wno-error -U_FORTIFY_SOURCE"
    exit 1
fi

echo ""
echo "============================================================"
echo " 修复完成！继续编译："
echo "   make package/libs/mbedtls/compile V=s   # 单独验证"
echo "   make -j\$(nproc)                          # 完整编译"
echo "============================================================"