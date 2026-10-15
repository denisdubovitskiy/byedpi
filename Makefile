TARGET = ciadpi

CPPFLAGS = -D_DEFAULT_SOURCE
CFLAGS += -I. -std=c99 -O2 -Wall -Wno-unused -Wextra -Wno-unused-parameter -pedantic
WIN_LDFLAGS = -lws2_32 -lmswsock

HEADERS = conev.h desync.h error.h extend.h kavl.h mpool.h packets.h params.h proxy.h win_service.h
SRC = packets.c main.c conev.c proxy.c desync.c mpool.c extend.c
WIN_SRC = win_service.c

OBJ = $(SRC:.c=.o)
WIN_OBJ = $(WIN_SRC:.c=.o)

PREFIX := /usr/local
INSTALL_DIR := $(DESTDIR)$(PREFIX)/bin/

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) -o $(TARGET) $(OBJ) $(LDFLAGS)

windows: $(OBJ) $(WIN_OBJ)
	$(CC) -o $(TARGET).exe $(OBJ) $(WIN_OBJ) $(WIN_LDFLAGS)

$(OBJ): $(HEADERS)
.c.o:
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $<

clean:
	rm -f $(TARGET) $(TARGET).exe $(OBJ) $(WIN_OBJ)

install: $(TARGET)
	mkdir -p $(INSTALL_DIR)
	install -m 755 $(TARGET) $(INSTALL_DIR)

# Локальный прогон GitHub Actions через act (https://github.com/nektos/act).
# Настройки маппинга раннеров — в .actrc: macos-latest выполняется прямо
# на хосте, ubuntu-latest — в контейнере catthehacker/ubuntu:act-latest
# (первый pull ~1.5 ГБ). Джоба windows-mingw тянет apt внутри контейнера.
# act не читает docker context (Docker Desktop / Lima) — берём сокет из него сами.
DOCKER_HOST ?= $(shell docker context inspect --format '{{.Endpoints.docker.Host}}' 2>/dev/null)
export DOCKER_HOST

ci:
	act push

ci-linux:
	act push -j linux

ci-macos:
	act push -j macos

ci-windows:
	act push -j windows-mingw

.PHONY: ci ci-linux ci-macos ci-windows
