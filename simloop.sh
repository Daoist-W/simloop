#bin/bash

# this script executes exampleB4a in a loop, changing the geometries located in B4DetectorConstruction
# based on a txt file containing geometry data. all the necessary reinitialising/set up is also done.

# these are in effect the steps that would usually be done manually
## -> edit geometry data
## cd ~/MProject/test/build
## make
## ./exampleB4a -m run1.mac > output.txt
#
#
# script needs to be stored in the root directory of your simulation folder 
#
# assumes there is a txt file with all the values needed with the following column order
# does not account for headers, so pelase remove these from the txt file
# nofLayers   absoThickness   gapthickness   calorSizeXY


# set up
GEOMETRY_FILE='geometries.txt'
TARGET_FILE='./src/B4DetectorConstruction.cc'
FILENAME='simulation'
RUN='0'


# this function prints out the help documentation for usage
function usage {
	echo -e "Usage ${0} [-v] [-f] \e[4mFILENAME\e[0m" >&2
	echo '	Execute exampleB4a simulation in a loop with changing geometries.' >&2
	echo '	Geometries are sourced from geometries.txt in space separated format:' >&2
	echo
	echo '	nofLayers absoThickness gapthickness calorSizeXY' >&2
	echo
	echo '	all results files are saved to ./results/' >&2
	echo '	all Geant4 output is redirected to geant4output.txt' >&2
	echo '	  -v          Verbose mode' >&2
	echo -e '	  -f \e[4mFILENAME\e[0m Change default prefix for results files' >&2

}

# this function checks if the previous command was successful, if it fails then an error message is shown and 
# when the program terminates it will be with a non zero exit status
function checkStatus {
	EXIT_STATUS=${?}
	if [[ ${EXIT_STATUS} -ne 0 ]]; then
		#statements
		echo "WARNING: ($EXIT_STATUS) - ${@}" >&2
		sleep 1
	fi
	return $EXIT_STATUS
}

# prints errors to the terminal 
function logerror {
	local ERROR="${@}"
	echo
	echo "${ERROR}" >&2
	echo
	usage
	exit 1
}

# prints standard output to the terminal
function log {
	if [[ $VERBOSE = 'true' ]]; then
		#statements
		echo -e ${@}
	fi
}

# this block of code handles the options provided for this script
while getopts vf: OPTION
do
	case ${OPTION} in
		v) VERBOSE='true' ;;
		f) FILE_NAME=${OPTARG} ;;
		?) logerror "ERROR: invalid option"
	esac
done


while IFS= read line
do


	# make sure there are exactly 4 variables for geometry
	NUM_VARS=$(echo $line | wc -w)
	if [[ $NUM_VARS -ne 4 ]]; then
		#statements
		logerror "ERROR: ${line} is an invalid line format, exiting..."
	fi
	nofLayers=$(echo "$line" | awk '{print $1}')
	absoThickness=$(echo "$line" | awk '{print $2}')
	gapthickness=$(echo "$line" | awk '{print $3}')
	calorSizeXY=$(echo "$line" | awk '{print $4}')

	log "applying geometries for run $RUN: 
		\n\tnofLayers: $nofLayers 
		\n\tabsoThickness: $absoThickness 
		\n\tgapthickness: $gapthickness 
		\n\tcalorSizeXY: $calorSizeXY"

	# replace values inside B4D file 
	sed -i "s/^.*G4int nofLayers = .*$/  G4int nofLayers = ${nofLayers};/g" $TARGET_FILE
	sed -i "s/^.*G4double absoThickness = .*$/  G4double absoThickness = ${absoThickness}.*um;/g" $TARGET_FILE
	sed -i "s/^.*G4double gapThickness = .*$/  G4double gapThickness = ${gapthickness}.*um;/g" $TARGET_FILE
	sed -i "s/^.*G4double calorSizeXY = .*$/  G4double calorSizeXY = ${calorSizeXY}.*um;/g" $TARGET_FILE

	# changing timestamp on file to ensure its changes are picked up by make
	touch $TARGET_FILE

	# make > /dev/null
	checkStatus "something went wrong with make, please review"
	# ./exampleB4a -m run1.mac > geant4output.txt
	checkStatus "something went wrong with executing the exampleB4a file, please review"

	log "saving results to ./results..."
	# create directory ./results if it doesn't exist
	mkdir -p ./results
	cp ./build/B4.root "./results/${FILENAME}_run${RUN}.root"
	RUN=$((RUN + 1))
done < $GEOMETRY_FILE



