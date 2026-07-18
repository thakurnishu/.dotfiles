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

# Plan usage limits (Pro/Max only; appear after first API response, each may be absent)
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

LIMITS=""
[ -n "$FIVE_H" ] && LIMITS="Session $(printf '%.0f' "$FIVE_H")%"
[ -n "$WEEK" ] && LIMITS="${LIMITS:+$LIMITS · }Week $(printf '%.0f' "$WEEK")%"

LINE="[$MODEL] $BAR $PCT% | In:$TOKENS_IN_FMT Out:$TOKENS_OUT_FMT Total:$TOTAL_FMT"
[ -n "$LIMITS" ] && LINE="$LINE | $LIMITS"
echo "$LINE"
