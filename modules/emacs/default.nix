{ config, pkgs, lib, ... }:

{
  # Emacsパッケージの設定
  programs.emacs = {
    enable = true;
    package = pkgs.emacs30-pgtk;  # Wayland対応の最新Emacs (セキュリティ修正済み)

    # 追加パッケージ
    extraPackages = epkgs: with epkgs; [
      # === Core ===
      use-package           # パッケージ管理
      diminish             # モードライン整理
      which-key            # キーバインドヘルプ

      # === UI/UX ===
      doom-themes          # 【テスト3】これが犯人か？
      doom-modeline        # 【テスト4】モードライン
      all-the-icons        # 【テスト4】アイコン
      rainbow-delimiters   # 【犯人候補1】括弧の色分け
      # highlight-indent-guides # 【犯人候補2】インデントガイド - まだコメントアウト

      # === 編集支援 ===
      company              # 自動補完
      company-box          # 【テスト5】補完UIの拡張
      yasnippet           # スニペット
      yasnippet-snippets  # スニペット集
      multiple-cursors    # マルチカーソル
      expand-region       # 選択範囲拡張
      smartparens         # 括弧の自動操作

      # === Navigation ===
      vertico             # ミニバッファ補完
      orderless           # あいまい検索
      marginalia          # ミニバッファ注釈
      consult             # 高機能検索
      embark              # コンテキストアクション

      # === プロジェクト管理 ===
      projectile          # プロジェクト管理
      treemacs            # 【テスト5】ファイルツリー
      treemacs-projectile # 【テスト5】projectile統合

      # === Git ===
      magit               # Git統合
      forge               # GitHub/GitLab統合
      git-gutter          # 【テスト4】差分表示

      # === LSP & TypeScript ===
      lsp-mode            # Language Server Protocol
      lsp-ui              # 【テスト5】LSP UI拡張
      lsp-treemacs        # 【テスト5】treemacs統合
      dap-mode            # Debug Adapter Protocol

      # TypeScript/JavaScript
      typescript-mode     # TypeScriptモード
      tide               # TypeScript IDE機能
      web-mode           # HTML/CSS/JS混在ファイル
      js2-mode           # 高機能JavaScriptモード
      rjsx-mode          # React JSX
      json-mode          # JSONモード
      prettier-js        # コードフォーマッタ

      # === 追加言語サポート ===
      nix-mode           # Nix言語
      yaml-mode          # YAML
      markdown-mode      # Markdown
      
      # === LaTeX サポート ===
      auctex             # 高機能LaTeXモード
      company-auctex     # LaTeX用Company補完
      pdf-tools          # PDF表示・注釈
      latex-preview-pane # LaTeXプレビューペイン

      # === ユーティリティ ===
      flycheck           # シンタックスチェック
      flycheck-pos-tip   # エラー表示改善
      editorconfig       # EditorConfig対応
      direnv             # direnv統合
      vterm              # ターミナルエミュレータ
      restclient         # REST APIクライアント

      # === 生産性 ===
      org                # Org-mode
      org-roam           # 知識管理
      org-modern         # モダンなOrg表示
    ];
  };

  # Emacs早期初期化ファイル（最小限の設定）
  home.file.".emacs.d/early-init.el".text = ''
    ;;; early-init.el --- Early initialization

    ;; UIの無効化（起動を高速化）
    (push '(menu-bar-lines . 0) default-frame-alist)
    (push '(tool-bar-lines . 0) default-frame-alist)
    (push '(vertical-scroll-bars) default-frame-alist)

    ;; 【テスト】日本語環境を設定（これが犯人か？）
    (set-language-environment "Japanese")

    ;; 【テスト6】フォント設定を明示的に追加
    (push '(font . "JetBrainsMono Nerd Font-12") default-frame-alist)

    (provide 'early-init)
    ;;; early-init.el ends here
  '';

  # Emacs設定ファイル
  home.file.".emacs.d/init.el".text = ''
    ;;; init.el --- Emacs configuration for TypeScript development


    ;; === 基本設定 ===
    (setq inhibit-startup-message t)
    (tool-bar-mode -1)
    (menu-bar-mode -1)
    (scroll-bar-mode -1)

    ;; 【テスト2】相対行番号表示（これが犯人か？）
    (global-display-line-numbers-mode t)
    (setq display-line-numbers-type 'relative)

    ;; 【テスト9】その他の基本設定
    (setq visible-bell t)         ; ビジュアルベル
    (electric-pair-mode 1)        ; 括弧自動閉じ
    (show-paren-mode 1)          ; 対応括弧ハイライト

    (setq-default indent-tabs-mode nil)
    (setq-default tab-width 2)
    (setq js-indent-level 2)
    (setq typescript-indent-level 2)

    ;; UTF-8設定
    (prefer-coding-system 'utf-8)
    (set-default-coding-systems 'utf-8)
    (set-terminal-coding-system 'utf-8)
    (set-keyboard-coding-system 'utf-8)

    ;; 【テスト8】描画関連設定（これが組み合わさると問題？）
    (setq-default bidi-paragraph-direction 'left-to-right)
    (setq bidi-inhibit-bpa t)
    (setq-default bidi-display-reordering nil)  ; 双方向テキストを無効化
    (setq inhibit-compacting-font-caches t)     ; フォントキャッシュを圧縮しない
    (setq auto-window-vscroll nil)              ; 自動スクロールを無効化
    (setq fast-but-imprecise-scrolling t)       ; スクロール高速化
    (setq jit-lock-defer-time 0)                ; 遅延なしで構文ハイライト

    ;; バックアップファイルの設定
    (setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
    (setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-saves/" t)))


    ;; === use-package初期化 ===
    (require 'use-package)
    (setq use-package-always-ensure t)

    ;; 【テスト3】doom-themesを使用
    (use-package doom-themes
      :config
      (setq doom-themes-enable-bold t
            doom-themes-enable-italic t)
      (load-theme 'doom-one t)
      (doom-themes-visual-bell-config)
      (doom-themes-org-config)

      ;; 【テスト7】日本語フォントを明示的に設定（これが決め手か？）
      (when (display-graphic-p)
        (set-face-attribute 'default nil :family "JetBrainsMono Nerd Font" :height 120)
        ;; 日本語フォントの設定
        (set-fontset-font t 'japanese-jisx0208 (font-spec :family "Noto Sans CJK JP"))
        (set-fontset-font t '(#x3040 . #x309f) "Noto Sans CJK JP")  ; ひらがな
        (set-fontset-font t '(#x30a0 . #x30ff) "Noto Sans CJK JP")  ; カタカナ
        (set-fontset-font t '(#x4e00 . #x9faf) "Noto Sans CJK JP")) ; 漢字
      )

    ;; 【テスト4】doom-modeline
    (use-package doom-modeline
      :init (doom-modeline-mode 1)
      :config
      (setq doom-modeline-height 25)
      (setq doom-modeline-bar-width 3)
      (setq doom-modeline-buffer-file-name-style 'truncate-upto-project))

    ;; 【テスト4】all-the-icons
    (use-package all-the-icons
      :if (display-graphic-p))

    ;; === Which Key ===
    (use-package which-key
      :init (which-key-mode)
      :diminish which-key-mode
      :config
      (setq which-key-idle-delay 0.3))

    ;; === Vertico & 補完 ===
    (use-package vertico
      :init
      (vertico-mode)
      :config
      (setq vertico-cycle t))

    (use-package orderless
      :init
      (setq completion-styles '(orderless basic)
            completion-category-defaults nil
            completion-category-overrides '((file (styles partial-completion)))))

    (use-package marginalia
      :init (marginalia-mode))

    (use-package consult
      :bind (("C-s" . consult-line)
             ("C-x b" . consult-buffer)
             ("M-g g" . consult-goto-line)
             ("M-g M-g" . consult-goto-line)
             ("C-x p f" . consult-find)))

    ;; === Company (自動補完) ===
    (use-package company
      :hook (after-init . global-company-mode)
      :config
      (setq company-idle-delay 0.1)
      (setq company-minimum-prefix-length 1)
      (setq company-selection-wrap-around t))

    ;; 【テスト5】company-box
    (use-package company-box
      :hook (company-mode . company-box-mode))

    ;; === YASnippet ===
    (use-package yasnippet
      :config
      (yas-global-mode 1))

    (use-package yasnippet-snippets)

    ;; === Projectile ===
    (use-package projectile
      :diminish projectile-mode
      :config (projectile-mode)
      :custom ((projectile-completion-system 'auto))
      :bind-keymap
      ("C-c p" . projectile-command-map)
      :init
      (setq projectile-project-search-path '("~/projects/" "~/work/")))

    ;; 【テスト5】Treemacs
    (use-package treemacs
      :defer t
      :bind
      (:map global-map
            ("M-0"       . treemacs-select-window)
            ("C-x t t"   . treemacs))
      :config
      (setq treemacs-width 30))

    (use-package treemacs-projectile
      :after (treemacs projectile))

    ;; === Magit ===
    (use-package magit
      :bind (("C-x g" . magit-status)
             ("C-x M-g" . magit-dispatch)))

    ;; 【テスト4】git-gutter
    (use-package git-gutter
      :hook (prog-mode . git-gutter-mode)
      :config
      (setq git-gutter:update-interval 0.02))

    ;; === LSP Mode ===
    (use-package lsp-mode
      :init
      (setq lsp-keymap-prefix "C-c l")
      :hook ((typescript-mode . lsp-deferred)
             (typescript-tsx-mode . lsp-deferred)
             (js2-mode . lsp-deferred)
             (web-mode . lsp-deferred))
      :commands (lsp lsp-deferred)
      :config
      (setq lsp-enable-which-key-integration t)
      (setq lsp-auto-guess-root t)
      (setq lsp-log-io nil)
      (setq lsp-restart 'auto-restart)
      (setq lsp-enable-symbol-highlighting t)
      (setq lsp-enable-on-type-formatting nil)
      (setq lsp-signature-auto-activate nil)
      (setq lsp-signature-render-documentation nil)
      (setq lsp-eldoc-hook nil)
      (setq lsp-modeline-code-actions-enable t)
      (setq lsp-modeline-diagnostics-enable t)
      (setq lsp-headerline-breadcrumb-enable t)
      (setq lsp-semantic-tokens-enable t)
      (setq lsp-enable-folding t)
      (setq lsp-enable-imenu t)
      (setq lsp-enable-snippet t)
      (setq lsp-enable-completion-at-point t))

    ;; 【テスト5】LSP UI
    (use-package lsp-ui
      :hook (lsp-mode . lsp-ui-mode)
      :config
      (setq lsp-ui-doc-enable t)
      (setq lsp-ui-doc-position 'at-point)
      (setq lsp-ui-sideline-enable t)
      (setq lsp-ui-sideline-show-hover t)
      (setq lsp-ui-sideline-show-diagnostics t)
      (setq lsp-ui-sideline-show-code-actions t))

    (use-package lsp-treemacs
      :after (lsp-mode treemacs))

    ;; === TypeScript & JavaScript ===
    (use-package typescript-mode
      :mode "\\.ts\\'"
      :config
      (setq typescript-indent-level 2))

    (use-package tide
      :after (typescript-mode company flycheck)
      :hook ((typescript-mode . tide-setup)
             (typescript-mode . tide-hl-identifier-mode)
             (before-save . tide-format-before-save))
      :config
      (setq tide-format-options
            '(:insertSpaceAfterFunctionKeywordForAnonymousFunctions t
              :placeOpenBraceOnNewLineForFunctions nil
              :indentSize 2
              :tabSize 2
              :insertSpaceBeforeAndAfterBinaryOperators t)))

    (use-package web-mode
      :mode (("\\.tsx\\'" . web-mode)
             ("\\.jsx\\'" . web-mode)
             ("\\.html\\'" . web-mode))
      :config
      (setq web-mode-markup-indent-offset 2)
      (setq web-mode-css-indent-offset 2)
      (setq web-mode-code-indent-offset 2)
      (setq web-mode-enable-auto-pairing t)
      (setq web-mode-enable-css-colorization t)
      (setq web-mode-enable-current-element-highlight t))

    ;; TypeScript in web-mode
    (add-hook 'web-mode-hook
              (lambda ()
                (when (string-equal "tsx" (file-name-extension buffer-file-name))
                  (setup-tide-mode))))

    (defun setup-tide-mode ()
      (interactive)
      (tide-setup)
      (flycheck-mode +1)
      (setq flycheck-check-syntax-automatically '(save mode-enabled))
      (eldoc-mode +1)
      (tide-hl-identifier-mode +1)
      (company-mode +1))

    ;; === Prettier ===
    (use-package prettier-js
      :hook ((js2-mode . prettier-js-mode)
             (typescript-mode . prettier-js-mode)
             (web-mode . prettier-js-mode)))

    ;; === Flycheck ===
    (use-package flycheck
      :init (global-flycheck-mode)
      :config
      (setq flycheck-display-errors-delay 0.3))

    ;; === Smartparens ===
    (use-package smartparens
      :hook (prog-mode . smartparens-mode))


    ;; === Expand Region ===
    (use-package expand-region
      :bind ("C-=" . er/expand-region))

    ;; === Multiple Cursors ===
    (use-package multiple-cursors
      :bind (("C-S-c C-S-c" . mc/edit-lines)
             ("C->" . mc/mark-next-like-this)
             ("C-<" . mc/mark-previous-like-this)
             ("C-c C-<" . mc/mark-all-like-this)))

    ;; 【犯人候補1】rainbow-delimitersを戻す
    (use-package rainbow-delimiters
      :hook (prog-mode . rainbow-delimiters-mode))

    ;; (use-package highlight-indent-guides
    ;;   :hook (prog-mode . highlight-indent-guides-mode)
    ;;   :config
    ;;   (setq highlight-indent-guides-method 'character))

    ;; === EditorConfig ===
    (use-package editorconfig
      :config
      (editorconfig-mode 1))

    ;; === Direnv ===
    (use-package direnv
      :config
      (direnv-mode))

    ;; === LaTeX設定 (AUCTeX) ===
    (use-package tex
      :ensure auctex
      :mode ("\\.tex\\'" . LaTeX-mode)
      :config
      ;; LuaLaTeXをデフォルトエンジンに設定
      (setq TeX-engine 'luatex)
      
      ;; 日本語文書用設定
      (setq TeX-default-mode 'japanese-latex-mode)
      (setq japanese-LaTeX-default-style "jlreq")
      (setq TeX-command-default "LuaLaTeX")
      
      ;; PDF出力設定
      (setq TeX-PDF-mode t)
      (setq TeX-view-program-selection '((output-pdf "PDF Tools")))
      (setq TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view)))
      
      ;; 自動保存時にコンパイル
      (setq TeX-save-query nil)
      (setq TeX-auto-save t)
      (setq TeX-parse-self t)
      
      ;; SyncTeX設定（ソースとPDFの相互ジャンプ）
      (setq TeX-source-correlate-mode t)
      (setq TeX-source-correlate-method 'synctex)
      (setq TeX-source-correlate-start-server t)
      
      ;; エラー表示設定
      (setq LaTeX-item-indent 0)
      (setq TeX-show-compilation t)
      
      ;; RefTeX統合（参照管理）
      (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
      (setq reftex-plug-into-AUCTeX t)
      
      ;; 数式プレビュー設定
      (setq preview-auto-cache-preamble t)
      
      ;; カスタムコマンド追加
      (add-hook 'LaTeX-mode-hook
                (lambda ()
                  (add-to-list 'TeX-command-list
                               '("LuaLaTeX" "lualatex -synctex=1 -interaction=nonstopmode %t"
                                 TeX-run-TeX nil t
                                 :help "Run LuaLaTeX"))
                  (add-to-list 'TeX-command-list
                               '("Latexmk" "latexmk -lualatex -pvc %t"
                                 TeX-run-TeX nil t
                                 :help "Run Latexmk with LuaLaTeX")))))
    
    ;; Company-AUCTeX設定
    (use-package company-auctex
      :after (company tex)
      :config
      (company-auctex-init))
    
    ;; PDF Tools設定
    (use-package pdf-tools
      :config
      (pdf-tools-install)
      (setq pdf-view-resize-factor 1.1)
      (setq-default pdf-view-display-size 'fit-page)
      ;; 暗い背景でのPDF表示
      (setq pdf-view-midnight-colors '("#ffffff" . "#1a1a1a"))
      (add-hook 'pdf-view-mode-hook (lambda() (pdf-view-midnight-minor-mode))))
    
    ;; LaTeXプレビューペイン
    (use-package latex-preview-pane
      :defer t
      :config
      (latex-preview-pane-enable))

    ;; === カスタムキーバインド ===
    (global-set-key (kbd "M-x") 'execute-extended-command)
    (global-set-key (kbd "C-x C-f") 'find-file)
    (global-set-key (kbd "C-x C-s") 'save-buffer)
    (global-set-key (kbd "C-x k") 'kill-buffer)
    (global-set-key (kbd "C-/") 'undo)
    (global-set-key (kbd "C-?") 'redo)
    (global-set-key (kbd "C-c f") 'project-find-file)
    (global-set-key (kbd "C-c r") 'lsp-rename)
    (global-set-key (kbd "C-c a") 'lsp-execute-code-action)
    (global-set-key (kbd "M-.") 'lsp-find-definition)
    (global-set-key (kbd "M-,") 'lsp-find-references)
    (global-set-key (kbd "C-c d") 'lsp-describe-thing-at-point)
    (global-set-key (kbd "C-c e n") 'flycheck-next-error)
    (global-set-key (kbd "C-c e p") 'flycheck-previous-error)
    (global-set-key (kbd "C-c e l") 'flycheck-list-errors)

    ;; === 最終設定 ===
    (add-hook 'emacs-startup-hook
              (lambda ()
                (message "Emacs ready for TypeScript development!")
                (message "Loading time: %s" (emacs-init-time))))

    (provide 'init)
    ;;; init.el ends here
  '';

  # TypeScript Language Server等の開発ツール
  # nodejs_22 は home.nix で管理（npm 同梱済み）
  # nodePackages.* は nodejs-20 依存のため除外し、npm global で管理する
  # npm i -g pnpm yarn typescript typescript-language-server eslint prettier nodemon ts-node
  home.packages = with pkgs; [
    # 【テスト6】Nerd Fontを追加
    (nerd-fonts.jetbrains-mono)
    (nerd-fonts.fira-code)

    # 【テスト7】日本語フォントも追加
    noto-fonts-cjk-sans
  ];

}