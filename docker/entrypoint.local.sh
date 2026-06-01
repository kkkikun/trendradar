#!/bin/bash
set -e

# 检查配置文件
if [ ! -f "/app/config/config.yaml" ] || [ ! -f "/app/config/frequency_words.txt" ]; then
    echo "❌ 配置文件缺失"
    exit 1
fi

case "${RUN_MODE:-cron}" in
"once")
    echo "🔄 单次执行"
    exec python -m trendradar
    ;;
"cron")
    # 立即执行一次（如果配置了）
    if [ "${IMMEDIATE_RUN:-false}" = "true" ]; then
        echo "▶️ 立即执行一次"
        python -m trendradar
    fi

    # 启动 Web 服务器
    echo "🌐 启动 Web 服务器..."
    python manage.py start_webserver &

    # 使用 Python 调度器替代 supercronic
    echo "⏰ 启动定时任务调度器..."
    CRON_EXPR="${CRON_SCHEDULE:-*/30 * * * *}"
    echo "📅 调度表达式: $CRON_EXPR"

    # 简单的 cron 调度器
    while true; do
        # 解析 cron 表达式（简化版：只支持 */N 格式）
        if [[ "$CRON_EXPR" =~ ^\*/([0-9]+)\ \*\ \*\ \*\ \*$ ]]; then
            interval=${BASH_REMATCH[1]}
            sleep $((interval * 60))
        else
            # 默认每30分钟执行一次
            sleep 1800
        fi

        echo "🔄 执行定时任务..."
        python -m trendradar || true
    done
    ;;
*)
    exec "$@"
    ;;
esac
