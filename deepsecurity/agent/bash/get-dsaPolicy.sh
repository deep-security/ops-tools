#!/bin/bash

if [ -a tempDsaConfig ]
  then
    rm tempDsaConfig
fi

/opt/ds_agent/sendCommand --get GetConfiguration | tail -n +4 > tempDsaConfig

policyid=$(xmllint -xpath 'string(//SecurityProfile/@id)' tempDsaConfig)
policyname=$(xmllint -xpath 'string(//SecurityProfile/@name)' tempDsaConfig)

rm tempDsaConfig

if [ -z $policyid ]
  then
    exit 1
fi

echo ${policyname},${policyid}
exit 0

