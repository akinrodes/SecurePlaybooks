#!/bin/bash
# dream-sequence.sh — Weekly Dream Sequence trigger for the Second Brain
#
# This script appends a trigger marker to the wiki log so that the next time
# you open Claude Code in this workspace, it sees a pending Dream Sequence
# and runs it automatically (reading CLAUDE.md and executing the full lint pass).
#
# HOW IT WORKS:
# 1. This script runs on a cron schedule (weekly by default).
# 2. It appends a PENDING marker to wiki/log.md.
# 3. The next time you start a Claude Code session, you (or the agent) see the
#    marker and run: "dream sequence" to trigger the full lint + ingest pass.
#
# TO CHANGE CADENCE: run `crontab -e` and edit the schedule line.
#   Weekly (default):  0 9 * * 1   (every Monday at 9am)
#   Daily:             0 9 * * *   (every day at 9am)
#   Monthly:           0 9 1 * *   (1st of each month)
#
# TO DISABLE: run `crontab -e` and delete or comment out the line.

BRAIN_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$BRAIN_DIR/wiki/log.md"
DATE=$(date +%Y-%m-%d)

echo "" >> "$LOG_FILE"
echo "## [$DATE] dream - ⏰ SCHEDULED Dream Sequence PENDING — open Claude Code and say \"dream sequence\"" >> "$LOG_FILE"

echo "Dream Sequence marker written to $LOG_FILE"
echo "Open your Second Brain in Claude Code and say 'dream sequence' to run the full lint pass."
