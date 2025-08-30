{
  description = "pfh cross-host Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Optional: nix-darwin for deeper macOS integration later
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }:
  let
    # helper to make a Home Manager config per host
    mkHome = { system, username, modules }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = modules ++ [
          { home.username = username;
            home.homeDirectory = if system == "aarch64-darwin"
                                  then "/Users/${username}"
                                  else "/home/${username}";
            home.stateVersion = "24.11";
            programs.zsh.enable = true;
          }
        ];
      };

    # Common packages for *all* machines
    commonModule = { pkgs, ... }: {
      home.packages = with pkgs; [
        git curl htop jq ripgrep fd unzip tree rsync
        # add more CLI tools you always want
      ];
      programs.ssh.enable = true;
      programs.git = {
        enable = true;
        userName = "Paul Hubbard";
        userEmail = "you@example.com";
      };
    };
  in {
    # Per-host user-level configs (Home Manager)
    homeConfigurations = {
      "pfh@web"     = mkHome { system = "x86_64-linux";  username = "pfh"; modules = [ commonModule ./hosts/web.nix     ]; };
      "pfh@servlet" = mkHome { system = "x86_64-linux";  username = "pfh"; modules = [ commonModule ./hosts/servlet.nix ]; };
      "pfh@thor"    = mkHome { system = "aarch64-darwin"; username = "pfh"; modules = [ commonModule ./hosts/thor.nix    ]; };
      "pfh@axiom"   = mkHome { system = "aarch64-darwin"; username = "pfh"; modules = [ commonModule ./hosts/axiom.nix   ]; };
    };

    # (Optional) macOS system-level integration later:
    # darwinConfigurations.thor = darwin.lib.darwinSystem {
    #   system = "aarch64-darwin";
    #   modules = [
    #     ./hosts/thor.nix
    #     home-manager.darwinModules.home-manager
    #     { users.users.pfh = { home = "/Users/pfh"; }; }
    #   ];
    # };
  };
}