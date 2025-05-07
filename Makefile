SRCS = debug.c
OBJS = $(SRCS:.c=.o)
CFLAG = -g -Wall -Werror -Wextra
NAME = debug


all:			$(NAME)

$(NAME): $(OBJS)
	$(CC) $(OBJS) \
	-o $(NAME)

clean:
	$(RM) $(OBJS)

fclean: clean
	$(RM) $(NAME)

re: fclean $(NAME)

# test:
# 	@test -d pipex_test || git clone git@github.com:M2U7BF/pipex_test.git
# 	bash pipex_test/test.sh

%.o: %.c
	$(CC) $(CFLAG) -O3 -c $< -o $@
