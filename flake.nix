{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.lua51Packages.lua
            pkgs.lua51Packages.luarocks
            # pkgs.lua51Packages.fzy
            # pkgs.vimPlugins.blink-cmp
          ];
        };
        packages.default = pkgs.vimUtils.buildVimPlugin {
          name = "blink-cmp-words";
          src = ./.;
          dependencies = with pkgs.vimPlugins; [ blink-cmp ];

        };
      });
}
