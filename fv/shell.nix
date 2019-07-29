{ pkgsSrc ? <nixpkgs>}:

with import pkgsSrc {};

stdenv.mkDerivation {
  name = "esm-fv";
  buildInputs = [
    flex
    getopt
    utillinux
    git
    gnumake
    jq
    nodejs
    openjdk8
    parallel
    zip
    z3
  ];

  shellHook = ''
    export PATH=$PATH:$KLAB_PATH/node_modules/.bin:$KLAB_PATH/bin
    export KLAB_EVMS_PATH=$KLAB_PATH/evm-semantics
  '';
}
