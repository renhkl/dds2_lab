#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'  
rm -rf transcript 

if ./compile.sh
then
	echo "Success"
else
	echo "Failure"
	exit 1
fi

if ./simulate.sh
then
	echo "Success"
else
	echo "Failure"
	exit 1
fi

printf "${RED}\nGenerating coverage report${NC}\n"
if vsim -coverage -voptargs="+fcover=sbcfet. +cover=sbcfet" -c test_hdlc bind_hdlc -do "coverage save -onexit -codeAll -assert -cvg coverage.ucdb; run -all; exit"
	then
		echo "Success"
	else
		echo "Failure"
		exit 1
	fi


#vsim -coverage \
#     -voptargs="+fcover=sbcfet. +cover=sbcfet" \
#	 -c \
#	 test_hdlc bind_hdlc \
#	 -do "coverage save -onexit -codeAll -assert -cvg coverage.ucdb; run -all exit"
	 

vcover report -html -output htmlReport -details coverage.ucdb

vcover report -details coverage.ucdb
