# 使用するベースイメージ。Claude Codeの要件（Node.jsなど）を満たすものを選びます。
# Alpineのような軽量なものを選ぶとイメージサイズが小さくなります。
FROM node:20-slim

# コンテナ内の作業ディレクトリを設定
WORKDIR /app

# 必要なシステムパッケージをインストール
# gitはコードリポジトリと連携する際に必要になることが多いです。
RUN apt-get update && apt-get install -y \
    git docker.io procps gh \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLIをグローバルにインストール
RUN npm install -g @anthropic-ai/claude-code

# セキュリティのため、root以外のユーザーを作成し、デフォルトのユーザーとして設定します。
# これにより、コンテナ内のプロセスが不必要に高い権限を持つのを防ぎます。
RUN useradd -m claudeuser && chown -R claudeuser:claudeuser /app
USER claudeuser

# コンテナ起動時に自動で実行するコマンドを設定。
# 基本的にはシェルを起動しておき、コンテナ内で手動でclaudeコマンドを実行します。
CMD ["bash"]
RUN mkdir -p /app/ && chown -R claudeuser:claudeuser /app/
#RUN mkdir $HOME/.claude