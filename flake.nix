{
  description = "This flake is a crime against docker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose.flakeModule
      ];
      perSystem = { pkgs, config, lib, ... }: {
        devShells.default = pkgs.mkShell { packages = [ pkgs.postgresql ]; };
        process-compose."default" = { config, ... }: {
            imports = [
              inputs.services-flake.processComposeModules.default
            ];

            services.postgres."pg1".enable = true;

            #settings.processes.debug.command = "while true; do echo \"$(date): I am debugging\"; sleep 2; done";
            settings.processes.pgweb =
              {
                command = pkgs.pgweb;
                depends_on."pg1".condition = "process_healthy";
              };
          };
      };
    };
}
