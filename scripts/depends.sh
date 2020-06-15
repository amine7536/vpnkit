#!/usr/bin/env sh
set -ex

# Set up the exact set of dependant packages

REPO_ROOT=$(git rev-parse --show-toplevel)

case "$(uname -s)" in
  CYGWIN*)

    ### From ocaml-ci-scripts

    # default setttings
    SWITCH="${OPAM_COMP}"
    OPAM_URL='https://github.com/fdopen/opam-repository-mingw/releases/download/0.0.0.2/opam64.tar.xz'
    OPAM_ARCH=opam64

    if [ "$PROCESSOR_ARCHITECTURE" != "AMD64" ] && \
           [ "$PROCESSOR_ARCHITEW6432" != "AMD64" ]; then
      	OPAM_URL='https://github.com/fdopen/opam-repository-mingw/releases/download/0.0.0.2/opam32.tar.xz'
        OPAM_ARCH=opam32
    fi

    curl -fsSL -o "${OPAM_ARCH}.tar.xz" "${OPAM_URL}"
    tar -xf "${OPAM_ARCH}.tar.xz"
    "${OPAM_ARCH}/install.sh"

    PATH="/usr/x86_64-w64-mingw32/sys-root/mingw/bin:${PATH}"
    export PATH

    ### Custom
    OPAM_SANBOX_ARG="--disable-sandboxing"
    export REPO_ROOT=$(cygpath.exe -w $(git rev-parse --show-toplevel))    
    export OPAM_REPO=$(cygpath.exe -w "${REPO_ROOT}/repo/win32")
    export OPAMROOT=$(cygpath.exe -w "${REPO_ROOT}/_build/opam")
  ;;
esac


if [ -z "${OPAMROOT}" ]; then
  OPAMROOT=${REPO_ROOT}/_build/opam
fi

export OPAMROOT
export OPAMYES=1
export OPAMCOLORS=1

# if a compiler is specified, use it; otherwise use the system compiler
if [ -n "${OPAM_COMP}" ]; then
  OPAM_COMP_ARG="--compiler=${OPAM_COMP}"
  OPAM_SWITCH_ARG="--switch=${OPAM_COMP}"
fi

# Disable sandboxing when running in a container
if [ -f /.dockerenv ]; then
  OPAM_SANBOX_ARG="--disable-sandboxing"
fi

# opam init -v -n ${OPAM_COMP_ARG} ${OPAM_SWITCH_ARG} ${OPAM_SANBOX_ARG}
opam init -v -n ${OPAM_COMP_ARG} ${OPAM_SWITCH_ARG} local "${OPAM_REPO}" $OPAM_SANBOX_ARG
echo opam configuration is:
opam config env
eval $(opam config env)

export PATH="${OPAMROOT}/${OPAM_COMP}/bin:${PATH}"

# opam remote add vpnkit ${OPAM_REPO}
# opam pin add -y -n vpnkit ${REPO_ROOT}
opam install depext -y -v
opam install depext-cygwinports -y || true
OPAMWITHTEST=false opam depext vpnkit -y
OPAMVERBOSE=false opam install alcotest charrua-client-mirage tcpip -y
opam install --deps-only vpnkit -y
# opam pin remove vpnkit
