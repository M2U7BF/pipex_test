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

// コマンドパスを探して、必要に応じてもとの値を書き換える関数
void	test_get_command_path(char *envp[])
{
	char	*cmd_paths[] = {ft_strdup("/bin/ls"), ft_strdup("ls"),
			ft_strdup(""), ft_strdup("/"), ft_strdup("//"), ft_strdup("//////"),
			ft_strdup("/bin/nonexisting"), ft_strdup("nonexisting"),
			ft_strdup("sudo")};
	int		expected[] = {0, 0, EXIT_CMD_NOT_FOUND, 0, 0, 0, EXIT_CMD_NOT_FOUND,
				EXIT_CMD_NOT_FOUND, EXIT_PERMISSION_DENIED};
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
			printf("result return_value:%d, expected: %d\n", result,
				expected[i]);
			printf("\n");
		}
		else
			printf("OK\n\n");
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
			"nonexisting"};
	int		len;

	put_test_name("access");
	len = sizeof(in) / sizeof(in[0]);
	for (int i = 0; i < len; i++)
	{
		printf("pathname=%s, mode=F_OK\n", in[i]);
		printf("result:%d\n", access(in[i], F_OK));
		printf("\n");
		printf("pathname=%s, mode=R_OK\n", in[i]);
		printf("result:%d\n", access(in[i], R_OK));
		printf("\n");
	}
	printf("\n");
}

int	main(int argc, char **argv, char *envp[])
{
	(void)argc;
	(void)argv;
	(void)envp;
	test_access();
	test_get_command_path(envp);
	return (0);
}
