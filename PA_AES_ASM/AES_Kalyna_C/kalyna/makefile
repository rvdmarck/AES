CC = gcc
CFLAGS = -W -Wall -ansi -pedantic -std=c99
EXEC = main


all: $(EXEC)

main: aes.o main.o
	$(CC) -o $@ $^

aes.o: aes.c
	$(CC) -o $@ -c $< $(CFLAGS)

main.o: main.c aes.h
	$(CC) -o $@ -c $< $(CFLAGS)

clean:
	rm -rf *.o

superclean: clean
	rm -rf $(EXEC)

# $@ : nom de la cible
# $< : nom première dépendance
# $^ : liste des dépendances 