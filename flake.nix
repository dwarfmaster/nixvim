{
  description = "A neovim configuration system for NixOS";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nmdSrc.url = "gitlab:rycee/nmd";
  inputs.nmdSrc.flake = false;

  outputs = { self, nixpkgs, nmdSrc, flake-utils, ... }@inputs:
    with nixpkgs.lib;
    with builtins;
    let
      # TODO: Support nesting
      nixvimModules = map (f: ./modules + "/${f}") (attrNames (builtins.readDir ./modules));

      modules = pkgs: nixvimModules ++ [
        (rec {
          _file = ./flake.nix;
          key = _file;
          config = {
            _module.args = {
              pkgs = mkForce pkgs;
              lib = pkgs.lib;
              helpers = import ./plugins/helpers.nix { lib = pkgs.lib; };
            };
          };
        })

        ./plugins/default.nix
      ];

      flakeOutput =
        flake-utils.lib.eachDefaultSystem
          (system: let
            pkgs = import nixpkgs { inherit system; };
          in {
            packages.docs = import ./docs {
              pkgs = import nixpkgs { inherit system; };
              lib = nixpkgs.lib;
              nixvimModules = nixvimModules;
              inherit nmdSrc;
            };

            legacyPackages.makeNixvim = import ./wrappers/standalone.nix pkgs (modules pkgs);
          });
    in
    flakeOutput // {
      nixosModules.nixvim = import ./wrappers/nixos.nix modules;
      homeManagerModules.nixvim = import ./wrappers/hm.nix modules;
    };
}
