#!/bin/bash
# Monitor script for news screen logs
echo "=== NEWS SCREEN LOG MONITOR ==="
echo "Monitoring flutter_logs_news_debug.txt for [NEWS], [RSS], and [CACHE] logs..."
echo "Press Ctrl+C to stop"
echo ""

tail -f flutter_logs_news_debug.txt 2>/dev/null | grep --line-buffered -E "\[(NEWS|RSS|CACHE)\]" || echo "Waiting for logs..."

