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
#   B. TARGET_CFLAGS 末尾追加 -U_FORTIFY_SOURCE，覆盖工具链注入
#
# 执行阶段：feeds install 之后、make 编译之前
# ============================================================

set -e

OPENWRT_DIR="${OPENWRT_DIR:-$(pwd)}"
MBEDTLS_MK="${OPENWRT_DIR}/package/libs/mbedtls/Makefile"

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

# ---------- 使用 awk 在 cmake.mk 行之前插入修复内容 ----------
# awk 不受引号和特殊字符影响，比 sed 更安全
awk '
/include \$\(INCLUDE_DIR\)\/cmake\.mk/ {
    print "# FIX-GCC14: fix memset always_inline error with GCC14 + musl fortify"
    print "CMAKE_OPTIONS += -DCMAKE_C_FLAGS_INIT=\"-Wno-error\""
    print "TARGET_CFLAGS += -Wno-error -U_FORTIFY_SOURCE"
    print ""
}
{ print }
' "${MBEDTLS_MK}.bak" > "${MBEDTLS_MK}"

# ---------- 验证 ----------
if grep -q "FIX-GCC14" "${MBEDTLS_MK}"; then
    echo "[OK] 修复写入成功，插入内容如下："
    echo "---"
    grep -A3 "FIX-GCC14" "${MBEDTLS_MK}"
    echo "---"
else
    echo "[ERROR] awk 插入失败，尝试直接追加到文件末尾..."
    cat >> "${MBEDTLS_MK}" << 'EOF'

# FIX-GCC14: fix memset always_inline error with GCC14 + musl fortify
CMAKE_OPTIONS += -DCMAKE_C_FLAGS_INIT="-Wno-error"
TARGET_CFLAGS += -Wno-error -U_FORTIFY_SOURCE
EOF
    if grep -q "FIX-GCC14" "${MBEDTLS_MK}"; then
        echo "[OK] 已追加到文件末尾。"
    else
        echo "[ERROR] 所有写入方式均失败，请手动修改 ${MBEDTLS_MK}"
        exit 1
    fi
fi

echo ""
echo "============================================================"
echo " 修复完成！继续编译："
echo "   make package/libs/mbedtls/compile V=s   # 单独验证"
echo "   make -j\$(nproc)                          # 完整编译"
echo "============================================================"