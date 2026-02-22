{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.lualatex;
in
{
  options.programs.lualatex = {
    enable = mkEnableOption "LuaLaTeX環境";

    packageSet = mkOption {
      type = types.str;
      default = "scheme-basic";
      description = ''
        TeXLiveパッケージセット
        - scheme-minimal: 最小構成
        - scheme-basic: 基本構成（推奨）
        - scheme-medium: 中規模
        - scheme-full: フル構成（大容量）
      '';
    };

    extraPackages = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "pgf" "beamer" "biblatex" ];
      description = "追加するTeXLiveパッケージ";
    };

    enableJapanese = mkOption {
      type = types.bool;
      default = true;
      description = "日本語文書作成環境（LuaTeX-ja）を有効化";
    };

    enableBibliography = mkOption {
      type = types.bool;
      default = true;
      description = "文献管理ツール（biber/biblatex）を有効化";
    };

    enableDiagrams = mkOption {
      type = types.bool;
      default = false;
      description = "図表作成パッケージ（TikZ/PGF）を有効化";
    };

    enablePresentations = mkOption {
      type = types.bool;
      default = false;
      description = "プレゼンテーション作成（Beamer）を有効化";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # TeXLive環境（最小構成）
      (texlive.combine (
        {
          inherit (texlive) scheme-basic
            # LuaLaTeX基本
            luatex
            luaotfload
            
            # 最小限の必須パッケージ
            fontspec
            unicode-math
            xkeyval
            etoolbox;
        }
        // optionalAttrs cfg.enableJapanese {
          inherit (texlive)
            luatexja
            haranoaji;
        }
        // lib.genAttrs cfg.extraPackages (name: texlive.${name})
      ))
      
      # 補助ツール
      texlab        # Language Server Protocol for LaTeX
      
      # PDF関連
      poppler_utils # pdftotext, pdfinfo等
      ghostscript   # PostScript/PDF処理
      
      # 画像変換
      pdf2svg       # PDF→SVG変換
      inkscape      # SVG編集・変換
    ];

    # LaTeX用テンプレートディレクトリ作成
    home.file.".config/latex/templates/.keep".text = "";
    
    # latexmk設定ファイル（LuaLaTeX用）
    home.file.".latexmkrc".text = ''
      # LuaLaTeX設定
      $pdf_mode = 4;  # LuaLaTeX使用
      $lualatex = 'lualatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
      
      # 出力ディレクトリ
      $out_dir = 'build';
      
      # Biber設定（文献管理）
      $biber = 'biber %O --bblencoding=utf8 -u -U --output_safechars %B';
      
      # クリーンアップ対象
      $clean_ext = 'synctex.gz synctex.gz(busy) run.xml bbl bcf blg nav snm vrb';
      
      # 継続的コンパイル設定
      $continuous_mode = 1;
      $pdf_previewer = 'start evince %O %S';
    '';
    
    # シェルエイリアス
    programs.zsh.shellAliases = mkIf config.programs.zsh.enable {
      # LaTeX関連コマンド
      lualatex-watch = "latexmk -pvc";
      lualatex-clean = "latexmk -c";
      lualatex-cleanall = "latexmk -C";
      tex2pdf = "lualatex -output-format=pdf";
    };
    
    programs.bash.shellAliases = mkIf config.programs.bash.enable {
      # LaTeX関連コマンド
      lualatex-watch = "latexmk -pvc";
      lualatex-clean = "latexmk -c";
      lualatex-cleanall = "latexmk -C";
      tex2pdf = "lualatex -output-format=pdf";
    };
  };
}