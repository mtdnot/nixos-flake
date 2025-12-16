{ config, pkgs, ... }:

{
  # macOS system defaults
  system.defaults = {
    # Dock設定
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.2;
      orientation = "bottom";
      show-recents = false;
      tilesize = 48;
      minimize-to-application = true;
      launchanim = false;
      static-only = false;
      show-process-indicators = true;
      mru-spaces = false;  # スペースを最近使った順に並べない
    };
    
    # Finder設定
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;  # 隠しファイルを表示しない（必要に応じてtrue）
      CreateDesktop = true;
      FXDefaultSearchScope = "SCcf";  # 現在のフォルダを検索
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";  # カラム表示
      QuitMenuItem = true;  # Finderを終了できるように
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;  # タイトルバーにフルパスを表示
    };
    
    # システム全体
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";  # ダークモード
      AppleShowScrollBars = "WhenScrolling";
      AppleKeyboardUIMode = 3;  # フルキーボードアクセス
      ApplePressAndHoldEnabled = false;  # キーリピートを有効化
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      "com.apple.swipescrolldirection" = true;  # ナチュラルスクロール
      "com.apple.sound.beep.feedback" = 0;  # ビープ音を無効化
    };
    
    # トラックパッド
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };
    
    # Activity Monitor
    ActivityMonitor = {
      IconType = 5;  # CPU使用率
      OpenMainWindow = true;
      ShowCategory = 100;  # All Processes
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };
    
    # スクリーンショット
    screencapture = {
      location = "~/Desktop";
      type = "png";
      disable-shadow = true;
    };
    
    # ログインウィンドウ
    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = false;
    };
  };
  
  # キーボードショートカット
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = false;  # 必要に応じてtrue
  };
}