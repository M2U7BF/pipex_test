#!/bin/bash

# テストフラグ
norminette_test=1
use_func_test=1
leak_test=1
func_test=1
mandatory_test=1
bonus_test=0

count=0

check_exit_status()
{
  if [ $? -ne $1 ]; then echo "exit: NG🔥"; else echo "exit: OK💎"; fi
}

increment_and_print() {
    ((count++))
    echo "[$count]-----------------------------------------------------------------"
}

pipex_test() {
    local expected_status=$1
    local expected_stderr=$2
    shift 2

    increment_and_print
    stderr_output=$(./pipex "$@" 2>&1 >/dev/null)
    status=$?

    printf "[execution] ./pipex "
    for arg in "$@"; do
      printf '"%s" ' "$arg"
    done
    echo ""

    if [ "$status" -ne "$expected_status" ]; then
        echo "[exit status] NG🔥"
        echo "$status, expected:$expected_status"
    else
      echo "[exit status] OK💎"
    fi

    if [ "$stderr_output" != "$expected_stderr" ]; then
        echo "[stderr_output] NG🔥"
        echo "result:\"$stderr_output\", expected:\"$expected_stderr\""
    else
      echo "[stderr_output] OK💎"
    fi

    if [ $leak_test -eq 1 ]; then
      valgrind --leak-check=full --show-leak-kinds=all -q ./pipex "$@"
    else
      ./pipex "$@"
    fi

    echo ""
}

test_argument_mandatory() {
  echo "引数の個数のテスト===================================================================="
  pipex_test 1 "Error" "a" "a" "a" "a" "a"
  pipex_test 1 "Error" "a" "a" "a"
  echo ""
}

test_mandatory() {
  echo "終了ステータスのテスト===================================================================="
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
  pipex_test 0 "pipex: .: Is a directory" "infile" "." "wc -l" "outfile"
  # 
  pipex_test 126 "pipex: .: Is a directory" "infile" "ls" "." "outfile"
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

  # ファイルサイズ大きい場合のテスト
  dd if=/dev/zero of=infile bs=1M count=50
  pipex_test 0 "" "infile" "ls" "wc -l" "outfile"
  echo "" > infile

  # 先頭のプロセスの出力が長い場合のテスト
  pipex_test 0 "" infile yes "head -n 10" outfile
}

echo "make fclean"
make fclean >/dev/null
make -n debug >/dev/null
if [ $? -eq 0 ]; then
  echo "make debug"
  make debug >/dev/null
else
  echo "make"
  make >/dev/null
fi
if [ $? -ne 0 ]; then
  exit 1
fi
echo ""

if [ $norminette_test -eq 1 ]; then
  echo "norminetteのテスト===================================================================="
  find mandatory -name "*.c" | xargs norminette | grep Error
  check_exit_status 1
  find mandatory -name "*.h" | xargs norminette | grep Error
  check_exit_status 1
  find bonus -name "*.c" | xargs norminette | grep Error
  check_exit_status 1
  find bonus -name "*.h" | xargs norminette | grep Error
  check_exit_status 1
  echo ""
fi

if [ $use_func_test -eq 1 ]; then
  echo "使用関数のチェック -------------------------------------------"
  nm -u ./pipex | grep GLIBC | grep -v -E '__libc_start_main|__stack_chk_fail|open|close|read|write|malloc|free|perror|strerror|access|dup|dup2|execve|exit|fork|pipe|unlink|wait|waitpid'
  check_exit_status 1
  echo ""
fi


# テスト用ファイル作成
if [ ! -e "outfile_permission" ]; then
  touch outfile_permission
  chmod -rw outfile_permission
fi
if [ ! -e "infile_permission" ]; then
  touch infile_permission
  chmod -rw infile_permission
fi
if [ $? -ne 0 ]; then
  exit 1
fi

if [ $func_test -eq 1 ]; then
  echo "メイン以外の基本関数のテスト -------------------------------------------"
  # cc -g3 -Wall -Werror -Wextra -o ./func_test pipex_test/test_main.c pipex.a lib/libft/libft.a && gdb ./func_test
  cc -g -Wall -Werror -Wextra -o ./func_test pipex_test/test_main.c \
    pipex.a lib/libft/libft.a lib/ft_dprintf/libftdprintf.a \
    && valgrind --leak-check=full -q ./func_test
  check_exit_status 0
  echo ""
fi

if [ $mandatory_test -eq 1 ]; then
  echo "mandatoryのテスト=========================================================================================================================================="
  test_argument_mandatory
  test_mandatory
  echo ""
fi

if [ $bonus_test -eq 1 ]; then
  echo "bonusのテスト========================================================================================================================================="
  make fclean
  make -n debug_bonus
  if [ $? -eq 0 ]; then
    make debug_bonus
  else
    make bonus
  fi
  if [ $? -ne 0 ]; then
    exit 1
  fi
  echo ""

  test_mandatory
  echo ""

  echo "bonusの基本パターン===================================================================="
  BONUS_OUTFILE_1="bonus_outfile"
  pipex_test 0 "" "infile" "/usr/bin/ls" "grep a" "wc -l" $BONUS_OUTFILE_1
  pipex_test 0 "" "infile" "/usr/bin/ls" "grep a" "grep a" "grep xxx" "wc -l" $BONUS_OUTFILE_1
  pipex_test 0 "" "infile" "/usr/bin/ls" "grep a" "grep a" "grep a" "grep a" "grep a" "grep a" "grep a" "grep xxx" "wc -l" $BONUS_OUTFILE_1

  # 先頭のプロセスの出力が長い場合のテスト
  pipex_test 0 "" infile yes "/usr/bin/ls" "grep a" "head -n 10" $BONUS_OUTFILE_1

  BONUS_OUTFILE_2="bonus_outfile_heredoc"
  # ヒアドキュメントのテスト
  # 実行例）
  # ./pipex here_doc EOF "grep error" sort outfile
  pipex_test 0 "" here_doc EOF "grep hello" sort $BONUS_OUTFILE_2 <<EOF
hello world
hello hello
EOF

  pipex_test 0 "" here_doc EOF "grep a" sort $BONUS_OUTFILE_2 <<EOF
EOF

  pipex_test 0 "" here_doc EOF "grep EOF" sort $BONUS_OUTFILE_2 <<EOF
EEOF
EOFF
EOF

  pipex_test 0 "" here_doc EOF "grep a" sort $BONUS_OUTFILE_2 <<a
aaa
a

fi

rm -f ' ' outfile_permission infile_permission
