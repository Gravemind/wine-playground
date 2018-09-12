NAME		= test

CFLAGS		= -g -O3 -Wall -Wextra -Wshadow -Wundef -Wno-unused -Wno-unused-parameter
CXXFLAGS	= $(CFLAGS) -std=c++17
LDFLAGS		=
LDLIBS		= -lXi -lXt -lX11

SRCS		= $(shell find . -name "*.cpp")
OBJS		= $(SRCS:%.cpp=$(BUILDDIR)/%.o)
DEPS		= $(OBJS:%.o=%.d)

BUILDDIR	= build
RM			= rm

all: $(NAME)

clean:
	$(RM) -rf $(BUILDDIR)

re: clean all

run: $(NAME)
	@echo "Running:"
	./$(NAME)

.PHONY: $(NAME) all clean re run

$(NAME): $(BUILDDIR)/$(NAME)

$(BUILDDIR)/%.o: %.cpp Makefile | $(BUILDDIR)
	$(CXX) $(CXXFLAGS) -MD -MP -MF "$(@:%.o=%.d)" -o "$@" -c "$<"

$(BUILDDIR)/$(NAME): $(OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(OBJS) $(LDLIBS) -o "$@"

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

-include $(DEPS)
