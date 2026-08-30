#!/usr/bin/env bash
# これを実行すると、一連のデモが自動で流れて demo.cast に記録される
set -euo pipefail

cd "$(dirname "$0")"
OUT="${1:-demo.cast}"

# URL=http://<ingress>/ ./record.sh で、デモ中の curl 先を差し替えられる
if [ -n "${URL:-}" ]; then export URL; fi

command -v asciinema >/dev/null || { echo "asciinema が見つかりません"; exit 1; }
command -v tmux      >/dev/null || { echo "tmux が見つかりません"; exit 1; }

rm -f "$OUT"

# -L demo : 普段使っている tmux サーバとは別のソケットを使う（設定が混ざらない）
asciinema rec \
  --cols 160 --rows 48 \
  --title "Kubernetes デモ" \
  -c "tmux -L demo -f ./tmux.conf new-session -s demo 'bash ./driver.sh'" \
  "$OUT"

echo
echo "記録しました: $OUT"
echo "  Install : sudo apt install asciinema"
echo "            cargo install --git https://github.com/asciinema/agg"
echo "  再生   : asciinema play $OUT"
echo "  低速   : asciinema play -s 0.5 $OUT"
echo "  GIF化  : agg $OUT demo.gif"
echo "  GIF化(低速)  : agg --speed 0.5 $OUT demo.gif"
echo '  MP4化  : ffmpeg -i demo.gif -movflags +faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" demo.mp4'
