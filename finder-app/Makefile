CC = gcc
CROSS_CC = aarch64-none-linux-gnu-gcc
CFLAGS = -Wall -Werror

TARGET = writer
SRC = writer.c
OBJ = $(SRC:.c=.o)

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

clean:
	rm -f $(TARGET) $(OBJ)

cross-compile:
	$(CROSS_CC) $(CFLAGS) -o $(TARGET) $(SRC)
