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
          buildInputs = [ pkgs.lua51Packages.lua pkgs.lua51Packages.luarocks ];
        };
        packages.default = pkgs.vimUtils.buildVimPlugin {
          name = "telescope-words.nvim";
          src = ./.;
        };

      });
}
