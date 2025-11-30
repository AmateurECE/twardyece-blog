#!/usr/bin/env sh

set -e
set -x

PARSERS_DIR=.ts-parsers

mkdir -p ${PARSERS_DIR}

fetch() {
  PN=$1
  PV=$2
  if [ ! -d ${PARSERS_DIR}/${PN}-${PV} ]; then
    if [ -n "$(find ${PARSERS_DIR} -maxdepth 1 -name ${PN}-*)" ]; then
      echo "Removing old version of ${PN}..."
      rm -rf ${PARSERS_DIR}/${PN}-*
    fi
    curl -L https://github.com/tree-sitter/${PN}/archive/refs/tags/v${PV}.tar.gz |
      tar -C ${PARSERS_DIR} -xzf -
  fi
}

fetch tree-sitter-ocaml 0.24.2
fetch tree-sitter-rust 0.24.0

CPP_PV=0.23.4
fetch tree-sitter-cpp ${CPP_PV}
(cd ${PARSERS_DIR}/tree-sitter-cpp-${CPP_PV} && npm install)

HASKELL_PV=0.23.1
if [ ! -d ${PARSERS_DIR}/tree-sitter-haskell-${HASKELL_PV} ]; then
  # Needed only until tree-sitter/tree-sitter-haskell#151 merges
  git -C ${PARSERS_DIR} clone --depth 1 --branch v${HASKELL_PV} \
    https://github.com/tree-sitter/tree-sitter-haskell.git \
    tree-sitter-haskell-${HASKELL_PV}
  (cd ${PARSERS_DIR}/tree-sitter-haskell-${HASKELL_PV} &&
    git remote add bugfix https://github.com/scherna/tree-sitter-haskell &&
    git fetch bugfix &&
    git cherry-pick --no-gpg-sign 6f6485f337bd7b8d6673a39edd490ac6a460a67b)
fi
