#include "../mandatory/pipex.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void	free_s_array(char **array)
{
	int	i;

	i = 0;
	if (array == NULL)
		return ;
	while (array[i])
	{
		free(array[i]);
		i++;
	}
	free(array);
}

void	put_test_name(char *s)
{
	printf("%s ----------\n", s);
}

void	put_ng(void)
{
	printf("NG🔥\n");
}

void	put_ok(void)
{
	printf("OK💎\n");
}

// コマンドパスを探して、必要に応じてもとの値を書き換える関数
void	test_get_command_path(char *envp[])
{
	char	*cmd_paths[] = {ft_strdup("/bin/ls"), ft_strdup("ls"),
			ft_strdup(""), ft_strdup("/"), ft_strdup("//"), ft_strdup("//////"),
			ft_strdup("/bin/nonexisting"), ft_strdup("nonexisting"),
			ft_strdup("sudo")};
	int		expected[] = {0, 0, EXIT_CMD_NOT_FOUND, EISDIR, EISDIR, EISDIR, ENOENT,
				EXIT_CMD_NOT_FOUND, EACCES};
	int		result;
	char	**path_env;
	int		len;

	put_test_name("get_command_path");
	len = sizeof(cmd_paths) / sizeof(cmd_paths[0]);
	path_env = get_path_env(envp);
	for (int i = 0; i < len; i++)
	{
		printf("TEST %d: cmd_name=%s, path_env=（略）\n", i, cmd_paths[i]);
		result = get_command_path(&cmd_paths[i], path_env);
		if (result != expected[i])
		{
			put_ng();
			printf("result return_value:%d, expected: %d\n", result,
				expected[i]);
			printf("\n");
		}
		else
		{
			put_ok();
			printf("\n");
		}
		if (result == 0)
			free(cmd_paths[i]);
	}
	free_s_array(path_env);
	printf("\n");
}

// accessの挙動調査
void	test_access(void)
{
	char	*in[] = {"", "/", "//", "//////////////////////////////", " ",
			"nonexisting", "infile_permission"};
	int		len;
	int		result;

	put_test_name("access");
	len = sizeof(in) / sizeof(in[0]);
	for (int i = 0; i < len; i++)
	{
		printf("TEST %d: pathname=\"%s\", mode=F_OK\n", i, in[i]);
		result = access(in[i], F_OK);
		printf("result:%d\n", result);
		if (result < 0)
			perror("access");
		printf("\n");
		printf("pathname=%s, mode=R_OK\n", in[i]);
		result = access(in[i], R_OK);
		printf("result:%d\n", result);
		if (result == -1)
			perror("access");
		printf("\n");
		printf("pathname=%s, mode=W_OK\n", in[i]);
		result = access(in[i], W_OK);
		printf("result:%d\n", result);
		if (result == -1)
			perror("access");
		printf("\n");
	}
	printf("\n");
}

// accessの挙動調査
void	test_open(void)
{
	char	*in[] = {"", "/", "//", "//////////////////////////////", " ",
			"nonexisting", "infile_permission"};
	int		len;
	int		result;

	put_test_name("open");
	len = sizeof(in) / sizeof(in[0]);
	for (int i = 0; i < len; i++)
	{
		printf("TEST %d: pathname=\"%s\", flags=O_RDONLY\n", i, in[i]);
		result = open(in[i], O_RDONLY);
		printf("result:%d\n", result);
		if (result == -1)
			perror("open");
		printf("\n");
		printf("pathname=\"%s\", flags=(O_WRONLY)\n", in[i]);
		result = open(in[i], O_WRONLY);
		printf("result:%d\n", result);
		if (result == -1)
			perror("open");
		printf("\n");
		printf("pathname=\"%s\", flags=(O_WRONLY | O_CREAT | O_TRUNC), mode=0664\n", in[i]);
		result = open(in[i], O_WRONLY | O_CREAT | O_TRUNC, 0664);
		printf("result:%d\n", result);
		if (result == -1)
			perror("open");
		printf("\n");
	}
	unlink(" ");
	unlink("nonexisting");
	printf("\n");
}

void	test_open_infile(void)
{
	char	*filenames[] = {"", "/", "//", "//////////////////////////////",
			" ", "nonexisting", "infile_permission"};
	int		fds[] = {0, 0, 0, 0, 0, 0, 0};
	int		expected[] = {ENOENT, 0, 0, 0, ENOENT, ENOENT, EACCES};
	int		len;
	int		result;

	put_test_name("open_infile");
	len = sizeof(filenames) / sizeof(filenames[0]);
	for (int i = 0; i < len; i++)
	{
		printf("TEST %d: file_name=\"%s\", fd=（略）\n", i, filenames[i]);
		result = open_infile(filenames[i], &fds[i]);
		if (result != expected[i])
		{
			put_ng();
			printf("result return_value:%d, expected: %d\n", result,
				expected[i]);
			printf("\n");
		}
		else
		{
			put_ok();
			printf("\n");
		}
		if (result != 1)
			close(fds[i]);
	}
}

void	test_open_outfile(void)
{
	char	*filenames[] = {"", "/", "//", "//////////////////////////////",
			" ", "nonexisting", "infile_permission"};
	int		fds[] = {0, 0, 0, 0, 0, 0, 0};
	int		expected[] = {ENOENT, EISDIR, EISDIR, EISDIR, 0, 0, EACCES};
	int		len;
	int		result;

	put_test_name("open_outfile");
	len = sizeof(filenames) / sizeof(filenames[0]);
	for (int i = 0; i < len; i++)
	{
		printf("TEST %d: file_name=\"%s\", fd=（略）\n", i, filenames[i]);
		result = open_outfile(filenames[i], &fds[i]);
		if (result != expected[i])
		{
			put_ng();
			printf("result return_value:%d, expected: %d\n", result,
				expected[i]);
			printf("\n");
		}
		else
		{
			put_ok();
			printf("\n");
		}
		if (result != 1)
			close(fds[i]);
	}
	unlink("nonexisting");
}

void	test_process(char *envp[])
{
	char	*command_strs[] = {"cat"};
	int		in_fds[] = {open("/", O_RDONLY)};
	int		out_fds[] = {open("outfile", O_WRONLY | O_CREAT | O_TRUNC, 0664)};
	int		expected[] = {1};
	int		len;
	int		result;

	put_test_name("process");
	len = sizeof(command_strs) / sizeof(command_strs[0]);
	for (int i = 0; i < len; i++)
	{
		printf("TEST %d: command_strs=\"%s\", envp=（略）, in_fd=%d, out_fd=%d\n",
			i, command_strs[i], in_fds[i], out_fds[i]);
		result = process(command_strs[i], envp, in_fds[i], out_fds[i]);
		if (result != expected[i])
		{
			put_ng();
			printf("result return_value:%d, expected: %d\n", result,
				expected[i]);
			printf("\n");
		}
		else
    {
      put_ok();
      printf("\n");
    }
	}
}

int	main(int argc, char **argv, char *envp[])
{
	(void)argc;
	(void)argv;
	(void)envp;
	test_open();
	test_open_infile();
	test_open_outfile();
	test_access();
	test_get_command_path(envp);
	test_process(envp);
	return (0);
}
