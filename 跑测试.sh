#!/usr/bin/env bash
# qi-graph 测试运行器 —— 编译并跑 测试/*_测.qi，任一套件失败即整体失败。
#
# 用法：./跑测试.sh              （用 ../target/release/qi）
#      QI_BIN=/path/to/qi ./跑测试.sh
#
# 注意 macOS 自带 bash 3.2：shell 变量名一律 ASCII，别用数组高级特性。
set -uo pipefail
cd "$(dirname "$0")"

ROOT="$(cd .. && pwd)"
QI_BIN="${QI_BIN:-$ROOT/target/release/qi}"
# 归档跟编译器要配套：链着旧运行时会出「符号不存在」这种看不懂的错
export QI_RUNTIME_LIB="${QI_RUNTIME_LIB:-$ROOT/qi-runtime/target/release/libqi_runtime.a}"

[ -x "$QI_BIN" ] || { echo "找不到 qi 二进制：$QI_BIN" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"; rm -f /tmp/qigraph-测-*.kv' EXIT

total=0
fail=0
for f in 测试/*_测.qi; do
    [ -e "$f" ] || continue
    name="$(basename "$f" .qi)"
    total=$((total + 1))
    echo "▶ $name"
    if ! "$QI_BIN" compile "$f" -o "$TMP/suite" >/dev/null 2>"$TMP/err"; then
        echo "  ✗ 编译失败"; sed 's/^/    /' "$TMP/err"; fail=$((fail + 1)); continue
    fi
    if "$TMP/suite"; then echo "  ✓ 通过"; else echo "  ✗ 失败"; fail=$((fail + 1)); fi
    echo ""
done

# 示例也要能编过 —— README 里写着的东西不能是编不过的
for f in 示例/*.qi 命令行/*.qi; do
    [ -e "$f" ] || continue
    total=$((total + 1))
    if "$QI_BIN" compile "$f" -o "$TMP/prog" >/dev/null 2>"$TMP/err"; then
        echo "✓ 编译 $f"
    else
        echo "✗ 编译 $f"; sed 's/^/    /' "$TMP/err"; fail=$((fail + 1))
    fi
done

echo "════════════════════════════"
echo "qi-graph: $((total - fail))/$total 通过"
[ "$fail" -gt 0 ] && exit 1
exit 0
