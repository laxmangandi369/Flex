CC = g++
OPT = -O3
error-recovery: lexer.cpp parser.cpp
	$(CC) $(OPT) $^ -o $@

lexer.hpp lexer.cpp: lexer.l
	flex --header-file=lexer.hpp -o lexer.cpp lexer.l 

parser.hpp parser.cpp: parser.y
	bison -d -v -o parser.cpp parser.y
