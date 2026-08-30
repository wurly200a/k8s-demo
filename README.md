# k8s-demo

Kubernetes 勉強会で使うデモ素材集です。スライドと、ターミナルで実際に動かすデモ一式を、回ごとのディレクトリにまとめています。

![00Intro のデモ](00Intro/movies/demo.gif)

Pod を 1 つ消しても勝手に元の数に戻り、レプリカを増やせば `curl` の応答を返す Pod が増える —— という様子を、実際のクラスタで撮ったものです（[00Intro](00Intro/)）。

## 収録デモ

| # | ディレクトリ | 内容 | スライド | 記事 |
|---|---|---|---|---|
| 00 | [00Intro](00Intro/) | Deployment / Service / Ingress を `apply` して、自己修復とスケールを見る | [pptx](00Intro/slides/kubernetes-intro.pptx) | （準備中） |

各回のディレクトリに、その回のスライド・マニフェスト・実行手順が揃っています。手を動かす場合は各ディレクトリの README を見てください。

## 動作環境

- Kubernetes クラスタ（`kubectl` が通る状態）
- [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) — デモは Ingress 経由で HTTP アクセスします
- デモの録画をやり直す場合のみ: `tmux` / [asciinema](https://asciinema.org/) / [agg](https://github.com/asciinema/agg) / `ffmpeg`

クラスタ側に特別な設定は要りません。マニフェストは `k8s-demo` という専用の Namespace に閉じており、後片付けもコマンド 1 つで済みます。

## ディレクトリ構成

```
00Intro/
├── slides/      スライド (pptx)
├── manifests/   デモで apply する YAML
├── scripts/     デモを自動再生・録画するスクリプト
└── movies/      録画済みのデモ (cast / gif / mp4)
```

以降の回も同じ構成で追加していきます。
