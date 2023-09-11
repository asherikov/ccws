# not supported:
#	due to possible conflicts with system libraries, e.g., glibc, it is
#	necessary to install *everything* via nix packages, which currently
#	not interesting for me
CCWS_NIX_VERSION?=2.17.0
CCWS_NIX_PKG_VERSION?=23.05

install_nix:
	${MAKE} download CCWS_DOWNLOAD_DIR=nix FILES="https://releases.nixos.org/nix/nix-${CCWS_NIX_VERSION}/install"
	sh "${CCWS_CACHE}/nix/install" --no-daemon --no-modify-profile

# https://www.breakds.org/post/nix-based-c++-workflow/
nix_workspace_flake: assert_PKG_arg_must_be_specified
	@/bin/echo -e "{\n\
description = \"${VENDOR} workspace flake\";\n\
inputs = {\n\
    nixpkgs.url = \"github:NixOS/nixpkgs/${CCWS_NIX_PKG_VERSION}\";\n\
    utils.url = \"github:numtide/flake-utils\";\n\
    utils.inputs.nixpkgs.follows = \"nixpkgs\";\n\
};\n\
outputs = {\n\
    self, nixpkgs, ...\n\
}\n\
@inputs: inputs.utils.lib.eachSystem [ \"x86_64-linux\" \"aarch64-linux\" ] (\n\
    system: let pkgs = import nixpkgs { inherit system; };\n\
    in {\n\
        devShell = pkgs.mkShell rec {\n\
            name = \"${VENDOR}-workspace\";\n\
            packages = with pkgs; [\n\
                cmake\n\
                ${PKG}\n\
            ];\n\
        };\n\
    }\n\
);\n\
}" > "${WORKSPACE_DIR}/src/flake.nix"
	@echo "Add ${WORKSPACE_DIR}/src/flake.nix to git before using it -> https://github.com/NixOS/nix/issues/6642"

nix_show:
	bash -c "${SETUP_SCRIPT}; ${CCWS_NIX} flake show '${WORKSPACE_DIR}/src'"

nix_develop:
	bash -c "${SETUP_SCRIPT}; ${CCWS_NIX} develop '${WORKSPACE_DIR}/src'"
