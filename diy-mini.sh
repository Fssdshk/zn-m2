#!/bin/bash
# ZN-M2 极简固件 DIY 脚本
# 目标: 最小改动, 保持 apk 源可用, 不引入第三方插件
set -e

echo "===== ZN-M2 ultra-minimal DIY start ====="

# 1. 修改默认 IP 为 192.168.1.1 (刷机后 uci-defaults 会再改为 192.168.3.168)
#    保留 192.168.1.1 作为救砖后可访问的地址, 避免刷完失联
# sed -i 's/192.168.1.1/192.168.3.168/g' package/base-files/files/bin/config_generate

# 2. 移除内置的第三方主题/插件源码, 避免 feeds install 时误拉
rm -rf feeds/luci/themes/luci-theme-argon 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-argon-config 2>/dev/null || true
rm -rf package/luci-theme-argon 2>/dev/null || true

# 3. 确保默认主题是 bootstrap (极简, 体积小)
[ -f feeds/luci/themes/luci-theme-bootstrap/Makefile ] && \
  sed -i 's/luci-theme-bootstrap/luci-theme-bootstrap/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# 4. 修复 NSS 内核 6.12 新增选项导致 syncconfig 交互卡死
#    ALLOC_SKB_PAGE_FRAG_DISABLE 是内核新增符号, 上游 target config 未同步,
#    syncconfig 会当 NEW 选项弹提问, CI 无 stdin 导致 EOF -> Error 1.
#    显式写入默认值 n, 消除交互提问 (保持默认行为: 启用页片段分配).
for cf in target/linux/qualcommax/config-6.12 target/linux/qualcommax/ipq60xx/config-6.12; do
  [ -f "$cf" ] || continue
  if ! grep -q 'CONFIG_ALLOC_SKB_PAGE_FRAG_DISABLE' "$cf"; then
    echo 'CONFIG_ALLOC_SKB_PAGE_FRAG_DISABLE=n' >> "$cf"
    echo "[fix] appended ALLOC_SKB_PAGE_FRAG_DISABLE=n to $cf"
  fi
done

# 5. 更新 feeds (workflow 里已执行, 这里保证索引最新)
./scripts/feeds update -a
./scripts/feeds install -a

echo "===== ZN-M2 ultra-minimal DIY done ====="
