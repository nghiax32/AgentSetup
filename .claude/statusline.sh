#!/usr/bin/env bash
# Status line: model with its effort level, current 5-hour session usage and
# weekly usage of the Claude.ai plan, read from the `effort` and `rate_limits`
# fields Claude Code passes on stdin.
# Example output: Opus 5.5 (medium) · Session 42% (resets in 1h23m, 15:10) · Week 18% (resets in 3d4h, Mon 09:00)

input="$(cat)"

model="$(jq -r '.model.display_name // empty' <<<"$input" 2>/dev/null)"
effort="$(jq -r '.effort.level // empty' <<<"$input" 2>/dev/null)"   # absent if the model has no effort setting

# Time left until a reset, e.g. 3d4h, 1h23m, 23m.
fmt_left() {
  local secs="$1" d h m
  d=$((secs / 86400)); h=$((secs % 86400 / 3600)); m=$((secs % 3600 / 60))
  if [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"
  else printf '%dm' "$((m > 0 ? m : 1))"
  fi
}

# resets_at may be an epoch number or an ISO-8601 string.
# Prints the countdown and the local reset time, e.g. "in 1h23m, 15:10".
fmt_reset() {
  local value="$1" format="$2" epoch
  [ -z "$value" ] && return
  if [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    epoch="${value%.*}"
    [ "$epoch" -gt 100000000000 ] && epoch=$((epoch / 1000))   # milliseconds
  else
    epoch="$(date -d "$value" +%s 2>/dev/null)" || return
  fi
  local left=$((epoch - $(date +%s))) clock
  clock="$(date -d "@$epoch" +"$format" 2>/dev/null)"
  if [ "$left" -le 0 ]; then printf 'now, %s' "$clock"
  else printf 'in %s, %s' "$(fmt_left "$left")" "$clock"
  fi
}

window() {
  local label="$1" key="$2" format="$3" pct reset
  pct="$(jq -r ".rate_limits.$key.used_percentage // empty" <<<"$input" 2>/dev/null)"
  [ -z "$pct" ] && return
  reset="$(fmt_reset "$(jq -r ".rate_limits.$key.resets_at // empty" <<<"$input" 2>/dev/null)" "$format")"
  printf '%s %.0f%%' "$label" "$pct"
  [ -n "$reset" ] && printf ' (resets %s)' "$reset"
}

parts=()
[ -n "$model" ] && parts+=("$model${effort:+ ($effort)}")
session="$(window Session five_hour '%H:%M')"
week="$(window Week seven_day '%a %H:%M')"
[ -n "$session" ] && parts+=("$session")
[ -n "$week" ] && parts+=("$week")
[ -z "$session$week" ] && parts+=("Usage: n/a")

out=""
for p in "${parts[@]}"; do
  out="${out:+$out · }$p"
done
printf '%s' "$out"
