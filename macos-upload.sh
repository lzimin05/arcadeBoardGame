#!/bin/zsh

echo ""

print -P "%F{blue}---------  Генерация SVF файла ---------%f%F{magenta}"
docker exec quartus /bin/bash -c "cd /macOS/Documents/University/S6/Computers/arcadeBoardGame && \
    /quartus/quartus/bin/quartus_cpf -c -q 25MHz -g 3.3 -n p ./output_files/arcadeBoardGame.sof ./arcadeBoardGame.svf"
print -P "%F{green}---------  Генерация SVF файла успешно выполнено! ---------%f"

echo ""

print -P "%F{blue}---------  Загрузка SVF файла ---------%f%F{magenta}"
cd ~/Documents/University/S6/Computers/arcadeBoardGame
openFPGALoader -c usb-blaster ./arcadeBoardGame.svf
print -P "%F{green}---------  Загрузка SVF файла успешно выполнено! ---------%f"

echo ""