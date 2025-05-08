#!bin/pipex

# pipex_test 1 "$expected" "infile" "ls" "wc -l" "outfile"

count=0

increment_and_print() {
    ((count++))
    echo "$count"
}

pipex_test() {
    local expected_status=$1
    local expected_stderr=$2
    shift 2

    increment_and_print
    stderr_output=$(./pipex "$@" 2>&1 >/dev/null)
    status=$?

    if [ "$status" -ne "$expected_status" ]; then
        echo "NG, $status, expected:$expected_status"
    fi

    if [ "$stderr_output" != "$expected_stderr" ]; then
        echo "NG, $stderr_output, expected:$expected_stderr"
    fi
}

make re
# make bonus

if [ ! -e "outfile_permission" ]; then
  touch outfile_permission
  chmod 000 outfile_permission
fi
if [ ! -e "infile_permission" ]; then
  touch infile_permission
  chmod 000 infile_permission
fi

# 1~5
pipex_test 0 "pipex: nonexisting: No such file or directory" "nonexisting" "ls" "wc -l" "outfile"
pipex_test 0 "nonexisting: command not found" "infile" "nonexisting" "wc -l" "outfile"
pipex_test 127 "nonexisting: command not found" "infile" "ls" "nonexisting" "outfile"
pipex_test 0 "pipex: infile_permission: Permission denied" "infile_permission" "ls" "wc -l" "outfile"
pipex_test 0 "pipex: /usr/bin/sudo: Permission denied" "infile" "sudo" "wc -l" "outfile"
# 
pipex_test 126 "pipex: /usr/bin/sudo: Permission denied" "infile" "ls" "sudo" "outfile"
pipex_test 1 "pipex: outfile_permission: Permission denied" "infile" "ls" "wc -l" "outfile_permission"
pipex_test 0 "pipex: : No such file or directory" "" "ls" "wc -l" "outfile"
pipex_test 0 "'' : command not found" "infile" "" "wc -l" "outfile"
pipex_test 127 "'' : command not found" "infile" "ls" "" "outfile"
# 
pipex_test 1 "pipex: : No such file or directory" "infile" "ls" "wc -l" ""
pipex_test 0 "" "infile" "ls -l" "wc" "outfile"
pipex_test 0 "" "infile" "ls" "wc -l" "outfile"
pipex_test 0 "" "infile" "/usr/bin/ls" "wc -l" "outfile"
pipex_test 0 "" "infile" "ls" "/usr/bin/wc -l" "outfile"
# 
pipex_test 0 "" "infile" "grep nonexisting" "wc -l" "outfile"
pipex_test 1 "" "infile" "ls" "grep nonexisting" "outfile"
pipex_test 0 "pipex: /: Is a directory" "infile" "/" "wc -l" "outfile"
pipex_test 126 "pipex: /: Is a directory" "infile" "ls" "/" "outfile"
pipex_test 0 "pipex: .: filename argument required" "infile" "." "wc -l" "outfile"
# 
pipex_test 2 "pipex: .: filename argument required" "infile" "ls" "." "outfile"
pipex_test 0 "" "./lib" "ls" "wc -l" "outfile"
pipex_test 1 "pipex: ./lib: Is a directory" "infile" "ls" "wc -l" "./lib"
pipex_test 0 "pipex: /usr/bin/lsxx: No such file or directory" "infile" "/usr/bin/lsxx" "wc -l" "outfile"
pipex_test 127 "pipex: /usr/bin/lsxx: No such file or directory" "infile" "ls" "/usr/bin/lsxx" "outfile"
# 
rm -f " "
pipex_test 0 "pipex:  : No such file or directory" " " "ls -l" "wc -l" "outfile"
pipex_test 0 " : command not found" "infile" " " "wc -l" "outfile"
pipex_test 127 " : command not found" "infile" "ls -l" " " "outfile"
pipex_test 0 "" "infile" "ls -l" "wc -l" " "

# ファイルサイズ大きい
dd if=/dev/zero of=infile bs=1M count=50
pipex_test 0 "" "infile" "ls" "wc -l" "outfile"
echo "" > infile

# bonus ---------------------------------
pipex_test 0 "" "infile" "/usr/bin/ls" "grep a" "wc -l" "outfile"
pipex_test 0 "" "infile" "/usr/bin/ls" "grep a" "grep a" "grep xxx" "wc -l" "outfile"

# echo 28
# pipex_test 0 "" here_doc EOF "grep error" sort outfile

rm -f ' '
