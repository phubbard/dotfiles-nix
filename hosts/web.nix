{ pkgs, ... }: {
  # per-host overrides for "web"
  home.packages = with pkgs; [ tmux ];
}
