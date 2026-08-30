# 00 Intro — Deployment / Service / Ingress をさわる

Kubernetes の最初の一歩として、「宣言した状態にクラスタが勝手に寄せてくれる」という一点を目で見て確かめるデモです。

![デモ](movies/demo.gif)

スライド: [`slides/kubernetes-intro.pptx`](slides/kubernetes-intro.pptx)

## このデモで見せること

| | 何をする | 何が見える |
|---|---|---|
| 自己修復 | Pod を 1 つ `delete` する | 消した瞬間に新しい Pod が立ち上がり、3 個に戻る |
| スケール | `replicas` を 3 → 6 → 3 に変える | 増減に追従して Pod が増え、減る |
| 負荷分散 | 上の間ずっと `curl` を回し続ける | 応答の Pod 名が入れ替わり、増減中も応答が途切れない |

Pod ごとに違う応答を返すのがポイントです。initContainer が `served by <Pod名> on <ノード名>` と書いた `index.html` を用意し、nginx がそれを返すようにしてあります（詳しくは[マニフェストの説明](#マニフェストの説明)）。これで「Service が複数の Pod に振り分けている」ことが、出力の変化として見えます。

## 前提

- `kubectl` がクラスタに通っていること
- クラスタに ingress-nginx が入っていること
- Ingress に到達できる URL がわかっていること（このデモでは `http://192.168.1.100:8080/`）

Ingress にはホスト名を指定していないので、ingress-nginx に届きさえすればどのアドレスでも応答します。自分の環境の URL は次のように調べられます。

```bash
kubectl get svc -n ingress-nginx
```

## 手を動かす

```bash
cd 00Intro

# 1. デプロイする
kubectl apply -f manifests/
kubectl wait --for=condition=available deploy/demo-web -n k8s-demo --timeout=90s
kubectl get deploy,svc,ingress -n k8s-demo
```

ここで端末をもう 2 つ開き、状態を眺めながら操作すると変化がよく見えます。

```bash
# 端末 A: Pod の状態を見張る
watch -n 0.3 kubectl get pods -n k8s-demo -o wide

# 端末 B: 外から叩き続ける（URL は自分の環境のものに）
while true; do curl -s --max-time 1 http://192.168.1.100:8080/; sleep 0.3; done
```

```bash
# 2. Pod を 1 つ消してみる → 勝手に戻る
kubectl delete pod -n k8s-demo "$(kubectl get pods -n k8s-demo -o jsonpath='{.items[0].metadata.name}')"

# 3. レプリカ数を変えてみる → 追従する
kubectl scale deploy demo-web -n k8s-demo --replicas=6
kubectl scale deploy demo-web -n k8s-demo --replicas=3

# 4. 後片付け
kubectl delete -f manifests/
```

Namespace ごと消えるので、クラスタには何も残りません。

## マニフェストの説明

`manifests/` の 4 ファイルは、番号順に `apply` されることを想定しています。

### `00-namespace.yaml`

デモ用の Namespace `k8s-demo` を作るだけです。以降のリソースはすべてこの中に作られるので、後片付けが確実になります。

### `10-deployment.yaml`

このデモの中心です。`replicas: 3` の nginx を立てますが、単に nginx を立てるだけだと 3 つの Pod がまったく同じ応答を返してしまい、Service が振り分けている様子が見えません。そこで initContainer を使っています。

```yaml
initContainers:
  - name: init-index
    image: busybox:1.36
    command:
      - sh
      - -c
      - echo "served by ${POD_NAME} on ${NODE_NAME}" > /html/index.html
```

`POD_NAME` と `NODE_NAME` は Downward API で環境変数として渡しています。Pod は自分の名前や載っているノード名をあらかじめ知ることはできませんが、`fieldRef` を使うとクラスタが実際に決めた値を受け取れます。

```yaml
env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
```

initContainer が書いた `index.html` は `emptyDir` のボリュームに置かれ、同じ Pod の nginx コンテナが `/usr/share/nginx/html` として（読み取り専用で）マウントします。initContainer は本体コンテナより先に実行され、完了するまで nginx は起動しません。つまり「中身を用意してから本番のコンテナを動かす」という初期化の型がそのまま使えています。

残り 2 つの設定も、デモの見え方のためにあります。

- `readinessProbe` — 応答できるようになった Pod だけを Service の振り分け先に加えます。これがないと、起動途中の Pod にも `curl` が飛んで失敗が混じります。
- `terminationGracePeriodSeconds: 3` — 削除時に Pod がすぐ消えるようにして、テンポを保っています（本番向けの値ではありません）。

### `20-service.yaml`

`app: demo-web` というラベルの付いた Pod をまとめ、1 つの宛先にする ClusterIP Service です。Pod は消えたり増えたりして IP も変わりますが、Service は「ラベルが一致する Pod」を常に追いかけるので、宛先としては安定し続けます。Pod を消しても `curl` が止まらないのは、この仕組みのおかげです。

`targetPort: http` のように、ポート番号ではなく Deployment 側で付けた名前で参照している点にも注目してください。

### `30-ingress.yaml`

クラスタの外から Service に届かせるための Ingress です。`ingressClassName: nginx` で ingress-nginx に処理させ、`/` 以下すべてを `demo-web` Service に転送します。ホスト名の条件を書いていないため、ingress-nginx に届いたリクエストはすべてここに流れます（デモ用の割り切りです）。

## デモを録画し直す

`scripts/` に、上の一連の流れを自動で実演して録画するスクリプトを置いています。tmux でペインを分割し、操作・Pod 一覧・`curl` の 3 面を同時に見せながら進みます。

```bash
cd scripts

# 自分の環境の URL を指定して録画（省略時は http://192.168.1.100:8080/）
URL=http://<ingress の URL>/ ./record.sh ../movies/demo.cast
```

必要なのは `asciinema` と `tmux` です。録画中は実際にクラスタへ `apply` するので、動くクラスタが要ります。

```bash
# 再生
asciinema play ../movies/demo.cast
asciinema play -s 0.5 ../movies/demo.cast   # 半分の速度で

# GIF / MP4 に変換
agg ../movies/demo.cast ../movies/demo.gif
ffmpeg -i ../movies/demo.gif -movflags +faststart -pix_fmt yuv420p \
  -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" ../movies/demo.mp4
```

| ファイル | 役割 |
|---|---|
| `record.sh` | asciinema と tmux を起動する入口。ここを実行する |
| `driver.sh` | tmux の中で動く本体。デモの流れそのもの |
| `lib.sh` | 人が打っているように見せる `run` などの小道具 |
| `tmux.conf` | 録画専用の tmux 設定（普段の設定と混ざらないよう別ソケットで使う） |
