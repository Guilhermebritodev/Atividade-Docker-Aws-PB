#!/bin/bash

# Atualiza todos os pacotes instalados no sistema
sudo yum update -y

# Instala o Docker
sudo yum install docker -y

# Inicia o serviço Docker
sudo systemctl start docker

# Habilita o serviço Docker para iniciar automaticamente na inicialização
sudo systemctl enable docker

# Adiciona o usuário ec2-user ao grupo docker para permitir a execução de comandos Docker sem sudo
sudo usermod -aG docker ec2-user

# Baixa a última versão do Docker Compose e salva em /usr/bin/docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose

# Torna o Docker Compose executável
sudo chmod +x /usr/bin/docker-compose

# Instala os utilitários Amazon EFS
sudo yum install amazon-efs-utils -y

# Cria um diretório para montar o EFS
sudo mkdir /mnt/efs/

# Altera as permissões do diretório para leitura, escrita e execução
sudo chmod +rwx /mnt/efs/

# Adicionar o DNS do console do EFS para a montagem
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0e4fad92023d9aaf4.efs.us-east-1.amazonaws.com:/ /mnt/efs

# Adiciona a entrada no fstab para montar o EFS automaticamente
echo "fs-0e4fad92023d9aaf4.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab

# Cria o arquivo de configuração do Docker Compose
cat <<EOF > /mnt/efs/docker-compose.yml
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - /mnt/efs/wordpress:/var/www/html
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: dbwordpress.chco46i8ez5r.us-east-1.rds.amazonaws.com
      WORDPRESS_DB_NAME: dbwordpress
      WORDPRESS_DB_USER: *****
      WORDPRESS_DB_PASSWORD: *******
      WORDPRESS_TABLE_CONFIG: wp_
 EOF
