#!/bin/bash

echo "make re"
make re > /dev/null
unset PATH
./pipex infile sort sort outfile
