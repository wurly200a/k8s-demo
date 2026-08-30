#!/usr/bin/env bash
# tmux セッションの中で動く本体。record.sh から呼ばれる。
set -uo pipefail

cd "$(dirname "$0")"
source ./lib.sh

NS=k8s-demo
# 自分の環境に合わせて上書きできる:  URL=http://<ingress>/ ./record.sh
URL="${URL:-http://192.168.1.100:8080/}"
M=../manifests

clear
sleep 1

# ------------------------------------------------------------------
say "1. manifest を確認する"
# ------------------------------------------------------------------
run "sed -n '1,26p' $M/10-deployment.yaml"
beat 5
clear
run "sed -n '27,54p' $M/10-deployment.yaml"
beat 5
clear

run "cat $M/20-service.yaml"
beat 3

run "cat $M/30-ingress.yaml"
beat 3
clear

# ------------------------------------------------------------------
say "2. デプロイする"
# ------------------------------------------------------------------
run "kubectl apply -f $M/"
beat 2

run "kubectl get deploy,svc,ingress -n $NS"
beat 3

run "kubectl wait --for=condition=available deploy/demo-web -n $NS --timeout=90s"
beat 1
clear

# ------------------------------------------------------------------
say "3. 監視用のペインを開く"
# ------------------------------------------------------------------
OPS=$(tmux display-message -p '#{pane_id}')

# 上に 2/3 の領域を作り、それをさらに半分に割る
TOP=$(tmux split-window -vb -d -l 66% -P -F '#{pane_id}' -t "$OPS")
MID=$(tmux split-window -v  -d -l 50% -P -F '#{pane_id}' -t "$TOP")

tmux select-pane -t "$TOP" -T "Pod の状態"
tmux select-pane -t "$MID" -T "外部からのアクセス   curl $URL"
tmux select-pane -t "$OPS" -T "操作"

tmux send-keys -t "$TOP" "watch -n 0.3 kubectl get pods -n $NS -o wide" C-m
sleep 1
tmux send-keys -t "$MID" "while true; do curl -s --max-time 1 $URL; sleep 0.3; done" C-m
beat 4

# ------------------------------------------------------------------
say "4. Pod を削除してみる"
# ------------------------------------------------------------------
POD=$(kubectl get pods -n "$NS" -o jsonpath='{.items[0].metadata.name}')
run "kubectl delete pod $POD -n $NS"
beat 6

# ------------------------------------------------------------------
say "5. レプリカ数を変えてみる"
# ------------------------------------------------------------------
run "kubectl scale deploy demo-web -n $NS --replicas=6"
beat 6

run "kubectl scale deploy demo-web -n $NS --replicas=3"
beat 6

# ------------------------------------------------------------------
say "6. 後片付け"
# ------------------------------------------------------------------
tmux send-keys -t "$MID" C-c
sleep 0.5
tmux kill-pane -t "$MID"

run "kubectl delete -f $M/"
beat 5

tmux kill-pane -t "$TOP"
sleep 0.5
clear

run "kubectl get all -n $NS"
beat 3

say "おわり"
sleep 1
