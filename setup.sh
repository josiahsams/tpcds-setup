#!/bin/bash

export WORKDIR=$HOME

grep -q '#StartTPCEnv' $HOME/.bashrc

if [ $? -eq 0 ];
then
  sed -i '/#StartTPCEnv/,/#StopTPCEnv/d' $HOME/.bashrc
fi

echo "#StartTPCEnv" >>$HOME/.bashrc
echo "export WORKDIR=${HOME}" >>$HOME/.bashrc
echo "export PATH=$PATH:${WORKDIR}/tpcds-setup:${WORKDIR}/tpcds-setup/utils" >>$HOME/.bashrc
echo "#StopTPCEnv" >>$HOME/.bashrc

echo "Updated .bashrc file."

${WORKDIR}/tpcds-setup/utils/install_tpcdep.sh

echo "Run 'source ~/.bashrc' to environment variables in your current login session."
