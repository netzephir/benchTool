# benchTool
Tool for benching and survey programs
Acutal version is 1.1.1


## Getting Started

BenchTool is a tool to benchmark a program 
Or to survey a specific PID and this children

### Prerequisites

Need program "BC"

```
sudo apt-get install bc
```

### Installing

No install needed, ready to go.
You can make an alias

```
alias bench='<PATH_TO_BENCH>/bench.sh'
```

### How to use
There is two mode on the tool.
The first one is the benchMark mode, it survey a new launch command during an execution.
```
./bench.sh php test.php
```
You can Execute it n times by bench, all execution will be stored
```
./bench.sh -n 5000 php test.php
```
The result will look like : 
```
./bench.sh -n 3 php test.php
Start benchmarking "php test.php"
For 3 execution(s)

Execution 1/3
Hello world
Execution 2/3
Hello world
Execution 3/3
Hello world
================================== Bench results =================================

Execution #     Min memory      Max memory      Avg memory      Median memory
0               0B              25MB            25MB            25MB
1               0B              25MB            25MB            25MB
2               0B              25MB            24MB            25MB

Execution #     Min cpu         Max cpu         Avg cpu         Median cpu
0               0%              1%              0.54%           0.5%
1               0%              0%              0.00%           0%
2               0%              1%              0.56%           0.5%

Execution #     Execution time
0               0m3.021s
1               0m3.021s
2               0m3.023s

```
You can output a CSV
```
./bench.sh -sOn 3 php test.php
Execution #,Min memory,Max memory,Avg memory,Median memory,Min cpu,Max cpu,Avg cpu,Median cpu,Execution time
0,0,25272,25057,25272,0,1,0.58,.5,3024.560
1,0,25660,25446,25660,0,2,1.17,1.0,3036.901
2,0,25508,25096,25508,0,1,0.59,.5,3027.433
```
Or a json
```
./bench.sh -sJn 3 php test.php
[{"minMemory":"0","maxMemory":"25704","avgMemory":"25504","medianMemory":"25704","minCpu":"0","maxCpu":"1","avgCpu":"0.53","medianCpu":"0.5","executionTime":"3019.921"},{"minMemory":"0","maxMemory":"25684","avgMemory":"25490","medianMemory":"25684","minCpu":"0","maxCpu":"1","avgCpu":"0.56","medianCpu":"0.5","executionTime":"3025.445"},{"minMemory":"0","maxMemory":"25520","avgMemory":"25144","medianMemory":"25520","minCpu":"0","maxCpu":"2","avgCpu":"1.00","medianCpu":"1.0","executionTime":"3035.331"}]
```
You have a lot more option available, you can find them with the -h option
```
./bench.sh -h
Usage: bench [OPTION]... [command to bench]
-n [number]
	Execute the command n times
-c
	Hide output of the executed command
-s
	Enable silent mode
-m
	Stop monitor subprocess
-O
	Make an output on csv format (not affected by -s)
-J
	Make an output on json format (not affected by -s)
-H
	Hide csv headers
-S [Separator]
	Change the separator for csv format (default ,)
-l
	Show live consumption
-i [pid]
	Survey a pid 
-r [number]
	Set an refresh interval between 0.001 and 1
```
## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds



## Authors

* **Netzephir** - *Initial work*
## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Changelog
###1.2.1 : 
- Correct little 
- Stabilize kill and interupt
- Reduce RAM consumption
###1.2.0 : 
- Add json export format
###1.1.0 : 
- Add survey function
###1.0.0 : 
- First function version