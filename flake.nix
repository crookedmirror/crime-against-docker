{
  description = "This flake is a crime against docker";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose.url = "github:Platonic-Systems/process-compose-flake";
  };
  
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose.flakeModule
      ];

      perSystem = { pkgs, lib, ... }: {
        devShells.default = pkgs.mkShell { packages = [ pkgs.bashInteractive ]; };

	process-compose."default" = {
	  settings = {
	      environment = {
	        PGDATA = "./data";
	      };
	      processes = {
		#uncomment followup line to debug failed service start/crash
		#debug.command = "while true; do echo \"$(date): I am debugging\"; sleep 2; done";
	        postgres-init.command = ''
		  if ! [ -f ./data/PG_VERSION ]; then
 	            echo "$(date): Creating Database cluster directory."
                    ${pkgs.postgresql}/bin/initdb
                    echo "$(date): Done"
		  else
		    echo "$(date): Nothing to do"
		  fi 
	        '';
		postgres-start = {
		  depends_on."postgres-init".condition = "process_completed_successfully";
		  command = "${pkgs.postgresql}/bin/pg_ctl start -o \"-k /tmp\"";
		  shutdown.command = "${pkgs.postgresql}/bin/pg_ctl stop -m fast";
		  readiness_probe.exec.command = "ss -ln | grep 5432";
		};
	     };
          };	  
	}; 
      };
    };
}
