# 録画用の共通関数
: "${TYPE_SPEED:=0.045}"   # 1文字あたりの入力速度（秒）
: "${PROMPT:=\$ }"

# 人が打っているように見せながらコマンドを実行する
run() {
  local cmd="$*"
  printf '%b' "$PROMPT"
  local i
  for (( i = 0; i < ${#cmd}; i++ )); do
    printf '%s' "${cmd:i:1}"
    sleep "$TYPE_SPEED"
  done
  printf '\n'
  sleep 0.5
  eval "$cmd"
  printf '\n'
}

# 画面に表示するだけのコメント（実行はしない）
say() {
  printf '\n\033[1;36m### %s\033[0m\n\n' "$*"
  sleep 1.8
}

# 見せ場で間を取る
beat() { sleep "${1:-2.5}"; }
