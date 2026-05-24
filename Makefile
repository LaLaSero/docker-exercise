LOGIN := yutakagi
DATA_DIR := /home/$(LOGIN)/data
MAC_DATA_DIR := /Users/$(LOGIN)/data
COMPOSE := docker compose -f srcs/docker-compose.yml
MAC_COMPOSE := docker compose -f srcs/docker-compose.yml -f srcs/docker-compose.macos.yml

all: up

prepare:
	mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

build: prepare
	$(COMPOSE) build

up: prepare
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v --rmi local

fclean: clean
	rm -rf $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb

re: fclean up

mac-prepare:
	mkdir -p $(MAC_DATA_DIR)/wordpress $(MAC_DATA_DIR)/mariadb
	test -f srcs/docker-compose.macos.yml || cp srcs/docker-compose.macos.yml.example srcs/docker-compose.macos.yml

mac-up: mac-prepare
	$(MAC_COMPOSE) up -d --build

mac-down:
	test -f srcs/docker-compose.macos.yml || cp srcs/docker-compose.macos.yml.example srcs/docker-compose.macos.yml
	$(MAC_COMPOSE) down

mac-clean:
	test -f srcs/docker-compose.macos.yml || cp srcs/docker-compose.macos.yml.example srcs/docker-compose.macos.yml
	$(MAC_COMPOSE) down -v --rmi local

mac-fclean: mac-clean
	rm -rf $(MAC_DATA_DIR)/wordpress $(MAC_DATA_DIR)/mariadb

mac-re: mac-fclean mac-up

.PHONY: all prepare build up down clean fclean re mac-prepare mac-up mac-down mac-clean mac-fclean mac-re
