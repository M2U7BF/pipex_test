#include "debug.h"

void	put_strarr(char **str)
{
	int	i;

	if (str == NULL)
		return ;
	i = 0;
	while (str[i])
	{
		printf("[%d] %s,\n", i, str[i]);
		i++;
	}
}
