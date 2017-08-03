#!/bin/bash
# @category  tools
# @shortdesc Command benchmark
# @longdesc  Command benchmark
# @author Netzephir
# @license MIT license
# @version 1.1.1

############# init section ###############

#param global var
verbose='true'
showExecution='true'
outputHasCsv='false'
outputHasJson='false'
csvHeaders='true'
monitorSubProcess='true'
monitorLive='false'
pidToMonitor=""
forceRefreshTimer=""
outputCsvSeparator=','
nbExecution=1
commandToExec=''

while getopts 'hn:csmOJHS:li:r:' flag; do
	case $flag in
	  	h)
			echo "Usage: bench [OPTION]... [command to bench]"
			echo "-n [number]"
			echo "	Execute the command n times"
			echo '-c'
			echo "	Hide output of the executed command"
			echo "-s"
			echo "	Enable silent mode"
			echo "-m"
			echo "	Stop monitor subprocess"
			echo "-O"
			echo "	Make an output on csv format (not affected by -s)"
			echo "-J"
			echo "	Make an output on json format (not affected by -s)"
			echo "-H"
			echo "	Hide csv headers"
			echo "-S [Separator]"
			echo "	Change the separator for csv format (default ,)"
			echo "-l"
			echo "	Show live consumption"
			echo "-i [pid]"
			echo "	Survey a pid "
			echo "-r [number]"
			echo "	Set an refresh interval between 0.001 and 1 "
			exit 0
		;;
	    n) nbExecution="${OPTARG}" ;;
		c) showExecution='false' ;;
	    s) verbose='false' ;;
	    m) monitorSubProcess='false' ;;
		O) outputHasCsv='true' ;;
		J) outputHasJson='true' ;;
		H) csvHeaders='false' ;;
		S) outputCsvSeparator="${OPTARG}" ;;
		l) monitorLive='true' ;;
		i) pidToMonitor="${OPTARG}";monitorLive='true' ;;
		r) forceRefreshTimer="${OPTARG}" ;;
		*)  ;;
	esac
done
for (( i=0; i<OPTIND-1; i++)); do
    shift
done

others="$@"
commandToExec=${others[0]}
if [ $verbose = true ]
then
	echo -e "\e[1;33mStart benchmarking \"$commandToExec\"\e[0m"
	echo -e "\e[1;33mFor $nbExecution execution(s)\e[0m"
fi

# execution global var
executionMaxMem=()
executionMinMem=()
executionAvgMem=()
executionMedianMem=()
executionMaxCpu=()
executionMinCpu=()
executionAvgCpu=()
executionMedianCpu=()
executionTime=()
pid=""
pidList=""
startProcessTimer=""
timeToConvert=""
convertedTime=""
mem=()
cpu=()
col='%-15s'

############# function section ###############

function effectiveExit
{
	if [ ! -z $pid ]
	then
		kill "$pid"
	fi
	echo ""
	exitShowResults
}

#special show result for SIGINT
function exitShowResults
{
	calculateConso
	if [ $outputHasCsv = true ]
	then
		showCsvResults
	else
		if [ $verbose = true ]
		then
			showMemResults
	        showCpuResults
		fi
	fi
    exit 130
}

function checkSubProcess
{
	if [ ! -z $pid ]
	then
		#check=$(ps --no-headers -o 'etimes' -p "$pid")
		if [ ! -f /proc/$pid/exe ]
		then
			if [ ! -z $startProcessTimer ]
			then
				pid=""
				trap - CHLD
				endProcessTimer=$(date +%s%N)
				timer=$(($endProcessTimer - $startProcessTimer))
				timer=$(echo "scale=3;${timer}/1000000" | bc)
				startProcessTimer=""
				executionTime+=($timer)
			fi
		fi
	fi
}

function convertMilisecondToReadable
{
	minutes=$(echo "scale=0;${timeToConvert}/60000" | bc)
	subMin=$(echo "scale=3;${timeToConvert} - $minutes * 60000" | bc)
	timeToConvert=""
	realS=$(echo "scale=3;${subMin}/1000" | bc)
	convertedTime=$minutes"m"$realS"s"
}

function findSubProcess
{
	subs=$(ps --no-headers -o 'pid' --ppid "$1")
	subs=$(echo $subs | xargs)
	if [ ! -z "$subs" ]
	then
		pidList+=" $subs"
		findSubProcess "$subs"
	fi
}

function calculateConso
{
    #calculate and store info
  	compileMem=$( IFS=$'\n'; echo "${mem[*]}
  	#start calculating memory informations" | awk 'NR == 1 { max=$1; min=$1; sum=0 }{ if ($1>max) max=$1; if ($1<min) min=$1; sum+=$1;} END {printf "%d %d %d\n", min, max, sum/NR}' )
  	medianMem=$( IFS=$'\n'; echo "${mem[*]}" | sort -n | awk ' { a[i++]=$1; }END { x=int((i+1)/2); if (x < (i+1)/2) print (a[x-1]+a[x])/2; else print a[x-1]; }')
  	#split in array to get each elem
  	compileMemArr=()
  	for elem in $compileMem
	do
	    compileMemArr+=($elem)
	done
	executionMinMem+=(${compileMemArr[0]})
	executionMaxMem+=(${compileMemArr[1]})
	executionAvgMem+=(${compileMemArr[2]})
	executionMedianMem+=($medianMem)

	#start calculating memory informations
	compileCpu=$( IFS=$'\n'; echo "${cpu[*]}" | awk 'NR == 1 { max=$1; min=$1; sum=0 }{ if ($1>max) max=$1; if ($1<min) min=$1; sum+=$1;} END {printf "%d %d %.2f\n", min, max, sum/NR}' )
  	medianCpu=$( IFS=$'\n'; echo "${cpu[*]}" | sort -n | awk ' { a[i++]=$1; }END { x=int((i+1)/2); if (x < (i+1)/2) print (a[x-1]+a[x])/2; else print a[x-1]; }')
  	#split in array to get each elem
  	compileCpuArr=()
  	for elem in $compileCpu
	do
	    compileCpuArr+=($elem)
	done
	executionMinCpu+=(${compileCpuArr[0]})
	executionMaxCpu+=(${compileCpuArr[1]})
	executionAvgCpu+=(${compileCpuArr[2]})
	executionMedianCpu+=($medianCpu)

	mem=()
    cpu=()
}

#show results functions
function showCpuResults
{
    printf "$col $col $col $col %s" "Execution #" "Min cpu" "Max cpu" "Avg cpu" "Median cpu"
    echo ""
    for((i=0;i<${#executionMinCpu[@]};i++));
    do
        printf "$col $col $col $col %s" $i "${executionMinCpu[$i]}%" "${executionMaxCpu[$i]}%" "${executionAvgCpu[$i]}%" "${executionMedianCpu[$i]}%"
        echo ""
    done
    echo ""
}

function showMemResults
{
    echo ""
    echo -e "\e[1m================================== Bench results =================================\e[0m"
    echo ""
    printf "$col $col $col $col %s" "Execution #" "Min memory" "Max memory" "Avg memory" "Median memory"
    echo ""
    for((i=0;i<${#executionMinMem[@]};i++));
    do

        printf "$col $col $col $col %s" $i "$(numfmt --to=iec --from-unit=K --suffix=B --padding=7 ${executionMinMem[$i]} | xargs)" "$(numfmt --to=iec --from-unit=K --suffix=B --padding=7 ${executionMaxMem[$i]} | xargs)" "$(numfmt --to=iec --from-unit=K --suffix=B --padding=7 ${executionAvgMem[$i]} | xargs)" "$(numfmt --to=iec --from-unit=K --suffix=B --padding=7 ${executionMedianMem[$i]} | xargs)"
        echo ""
    done
    echo ""
}

function showTimers
{
    printf "$col %s" "Execution #" "Execution time"
    echo ""
    for((i=0;i<${#executionTime[@]};i++));
    do
        timeToConvert=${executionTime[$i]}
        convertMilisecondToReadable
        printf "$col %s" $i $convertedTime
        convertedTime=""
        echo ""
    done
    echo ""
}

function showCsvResults
{
	if [ $csvHeaders = true ]
	then
		echo "Execution #"$outputCsvSeparator"Min memory"$outputCsvSeparator"Max memory"$outputCsvSeparator"Avg memory"$outputCsvSeparator"Median memory"$outputCsvSeparator"Min cpu"$outputCsvSeparator"Max cpu"$outputCsvSeparator"Avg cpu"$outputCsvSeparator"Median cpu"$outputCsvSeparator"Execution time"
	fi
	for((i=0;i<${#executionMinMem[@]};i++));
	do
	    echo $i$outputCsvSeparator${executionMinMem[$i]}$outputCsvSeparator${executionMaxMem[$i]}$outputCsvSeparator${executionAvgMem[$i]}$outputCsvSeparator${executionMedianMem[$i]}$outputCsvSeparator${executionMinCpu[$i]}$outputCsvSeparator${executionMaxCpu[$i]}$outputCsvSeparator${executionAvgCpu[$i]}$outputCsvSeparator${executionMedianCpu[$i]}$outputCsvSeparator${executionTime[$i]}
	done
}

function showJsonResults
{
    jsonRender="["
    for((i=0;i<${#executionMinMem[@]};i++));
	do
        jsonRender=$jsonRender'{'
        jsonRender=$jsonRender'"minMemory":"'${executionMinMem[$i]}'",'
        jsonRender=$jsonRender'"maxMemory":"'${executionMaxMem[$i]}'",'
        jsonRender=$jsonRender'"avgMemory":"'${executionAvgMem[$i]}'",'
        jsonRender=$jsonRender'"medianMemory":"'${executionMedianMem[$i]}'",'
        jsonRender=$jsonRender'"minCpu":"'${executionMinCpu[$i]}'",'
        jsonRender=$jsonRender'"maxCpu":"'${executionMaxCpu[$i]}'",'
        jsonRender=$jsonRender'"avgCpu":"'${executionAvgCpu[$i]}'",'
        jsonRender=$jsonRender'"medianCpu":"'${executionMedianCpu[$i]}'",'
        jsonRender=$jsonRender'"executionTime":"'${executionTime[$i]}'"'
        jsonRender=$jsonRender'}'
        j=$(($i + 1))
        if [ ! -f ${executionMinMem[$j]} ]
        then
            jsonRender=$jsonRender','
        fi
	done
    jsonRender=$jsonRender"]"

    echo $jsonRender
}

#Main monitor function
function grabConso
{
	finish=0
	timer=0
	nbLoop=0

	#start infinite while for looking process ressource usage
	sleepTime=0.001
	if [ ! -z $forceRefreshTimer ]
	then
	    sleepTime=$forceRefreshTimer
	fi
	#init show liveResult if pidMonitorMod
    if [ $monitorLive = true ] && [ $verbose = true ]
    then
        echo "live execution"
        echo "Memory : 0"
        echo "Cpu : 0"
    fi
	while true;
	do
		#make a sleep for limiting the number of stored data
		sleep $sleepTime
		nbLoop=$(($nbLoop + 1));
	  	if [ ! -f /proc/$1/exe ]
	  	then
	  		finish=1
  			break;
  		fi
  		pidList=$1

  		#monitor subprocess
  		if [ $monitorSubProcess = true ]
  		then
  			findSubProcess $1
  		fi
  		#get the the process ressource usage
  		output=$(ps --no-headers -o '%cpu,rss' -p "$pidList")
  		#split in array to get each elem
  		arrOutput=()
  		nbElem=1
  		tempMem=0
  		tempCpu=0
  		for elem in $output
		do
			if [ $(($nbElem % 2)) = 0 ]
			then
				tempMem=$(echo $tempMem + $elem | bc)
			else
				tempCpu=$(echo $tempCpu + $elem | bc)
			fi
		    nbElem=$(($nbElem + 1))
		done
		#store results
		mem+=(${tempMem})
		cpu+=(${tempCpu})

		#change the sleep timer if the process become longer
		if [ -z $forceRefreshTimer ]
        then
            if [ $nbLoop -eq 200 ]
            then
                sleepTime=0.01
            elif [ $nbLoop -eq 1400 ]
            then
                sleepTime=0.1
            fi
        fi
        #show liveResult if pidMonitorMod
        if [ $monitorLive = true ] && [ $verbose = true ]
        then
            echo -en "\e[2A";
            echo -en "                           \r"
            echo "Memory : $(numfmt --to=iec --from-unit=K --suffix=B --padding=7 $tempMem | xargs)"
            echo -en "                           \r"
            echo "Cpu : $tempCpu %"
        fi
  	done
  	#end show liveResult if pidMonitorMod
    if [ $monitorLive = true ] && [ $verbose = true ]
    then
        echo ""
        echo ""
    fi


    calculateConso

	#security process killer
  	if [ $finish == 0 ]
  	then
  		pid = ""
  		kill "$pid"
	fi

}


############# execution section ###############

# check if monitor mode
if [ -z $pidToMonitor ]
then
    #here a trap for correctly do the interruption
    trap effectiveExit INT

    #Start the main execution
    for ((n=1;n<=$nbExecution;n++))
    do
        if [ $verbose = true ]
        then
            echo ""
            echo -e "\e[0;33mExecution $n/$nbExecution\e[0m"
        fi
        #enable survey on child process
        set -m
        #start mesuring time for this sub execution
        startProcessTimer=$(date +%s%N)

        if [ $showExecution = "false" ] || [ $monitorLive = "true" ] || [ $verbose = "false" ]
        then
            $commandToExec &>/dev/null &

        else
            $commandToExec &
        fi
        pid="$!"
        #make a trap for subprocess signal
        trap checkSubProcess CHLD
        grabConso $pid
    done
else
	#Trap to show result at the end
    trap exitShowResults INT
    #Trap for child process to stop execution
    trap checkSubProcess CHLD
    #Launch survey mode
    grabConso $pidToMonitor
fi


#start formatting output
if [ $outputHasCsv = true ] || [ $outputHasJson = true ]
then
    if [ $outputHasCsv = true ]
    then
        showCsvResults
    fi

    if [ $outputHasCsv = true ] && [ $outputHasJson = true ]
    then
        echo " "
    fi

    if [ $outputHasJson = true ]
    then
        showJsonResults
    fi
else
	if [ $verbose = true ]
	then
		showMemResults
        showCpuResults
        showTimers
	fi
fi

