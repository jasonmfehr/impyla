#!/bin/bash
set -euo pipefail

IMPYLA_HOME="$(readlink -f "$(dirname "${0}")/../..")"
PYTHON_VERSION="${PYTHON_VERSION:-3.9}"

# setup temp workdir
TMP_DIR=$(mktemp -d impyla-dbapi-XXXX)
pushd "${TMP_DIR}"
function cleanup_tmp_dir {
    popd
    rm -rf "${TMP_DIR}"
}
trap cleanup_tmp_dir EXIT

curl https://repo.anaconda.com/miniconda/Miniconda3-py38_23.3.1-0-Linux-x86_64.sh > miniconda.sh
chmod 755 miniconda.sh
./miniconda.sh -b -p "${TMP_DIR}/miniconda"

export PATH="${TMP_DIR}/miniconda/bin:${PATH}"
conda update -y -q conda
conda info -a

# Install impyla and deps into new environment
CONDA_ENV_NAME=pyenv-impyla-local-test
conda create -y -q -n "${CONDA_ENV_NAME}" python="${PYTHON_VERSION}" pip
source activate "${CONDA_ENV_NAME}"
pip install sqlalchemy
pip install unittest2 pytest pytest-cov

pip install -r "${IMPYLA_HOME}/impala/tests/requirements.txt"
pip install "${IMPYLA_HOME}"

py.test --connect \
    --cov impala \
    --cov-report xml --cov-report term \
    --cov-config .coveragerc \
    "${IMPYLA_HOME}/impala"