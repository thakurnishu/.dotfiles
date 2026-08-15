#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Get session-wide token usage from context_window
TOKENS_IN=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
TOKENS_OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
TOTAL_TOKENS=$((TOKENS_IN + TOKENS_OUT))

# Format tokens with K suffix (show decimal for precision)
format_tokens() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    # Show decimal: 98.6K
    awk "BEGIN {printf \"%.1fK\", $n / 1000}"
  else
    echo "$n"
  fi
}

TOKENS_IN_FMT=$(format_tokens $TOKENS_IN)
TOKENS_OUT_FMT=$(format_tokens $TOKENS_OUT)
TOTAL_FMT=$(format_tokens $TOTAL_TOKENS)

# Context window progress bar
BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

# Format a reset time (epoch or ISO) as a compact countdown (e.g. 2h13m, 3d4h, 45m)
NOW=$(date +%s)
countdown() {
  local target=$1
  case "$target" in
    # Non-numeric means an ISO timestamp. macOS `date` has no -d: it fails
    # with "illegal option -- d". gdate is GNU date from coreutils (declared
    # in modules/darwin/packages.nix); fall back to BSD syntax if absent so
    # the status line degrades instead of breaking.
    ''|*[!0-9]*)
      if command -v gdate >/dev/null 2>&1; then
        target=$(gdate -d "$target" +%s 2>/dev/null) || return
      else
        _t=${target%%.*}; _t=${_t%Z}
        target=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$_t" +%s 2>/dev/null) || return
      fi
      ;;
  esac
  [ -n "$target" ] || return
  local secs=$((target - NOW))
  [ "$secs" -le 0 ] && { echo "now"; return; }
  local d=$((secs / 86400))
  local h=$(((secs % 86400) / 3600))
  local m=$(((secs % 3600) / 60))
  if [ "$d" -gt 0 ]; then echo "${d}d${h}h"
  elif [ "$h" -gt 0 ]; then echo "${h}h${m}m"
  else echo "${m}m"; fi
}

# Plan usage limits (Pro/Max only; appear after first API response, each may be absent)
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

LIMITS=""
if [ -n "$FIVE_H" ]; then
  LIMITS="Session $(printf '%.0f' "$FIVE_H")%"
  LEFT=$(countdown "$FIVE_H_RESET")
  [ -n "$LEFT" ] && LIMITS="$LIMITS ·$LEFT"
fi
if [ -n "$WEEK" ]; then
  LIMITS="${LIMITS:+$LIMITS · }Week $(printf '%.0f' "$WEEK")%"
  LEFT=$(countdown "$WEEK_RESET")
  [ -n "$LEFT" ] && LIMITS="$LIMITS ·$LEFT"
fi

LINE="[$MODEL] $BAR $PCT% | In:$TOKENS_IN_FMT Out:$TOKENS_OUT_FMT Total:$TOTAL_FMT"
[ -n "$LIMITS" ] && LINE="$LINE | $LIMITS"
echo "$LINE"
