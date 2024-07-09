# Atividade-Docker-Aws-PB

# Atividade de Docker + AWS | COMPASS UOL

### Descrição da atividade proposta:

1. instalação e configuração do DOCKER ou CONTAINERD no host EC2;
2. Efetuar Deploy de uma aplicação Wordpress com container de aplicação RDS database Mysql;
3. configuração da utilização do serviço EFS AWS para estáticos do container de aplicação Wordpress;
4. configuração do serviço de Load Balancer AWS para a aplicação Wordpress;
 - Pontos de atenção:
   - não utilizar ip público para saída do serviços WordPress (Evitem publicar o serviço WP via IP Público)
   - sugestão para o tráfego de internet sair pelo LB (Load Balancer Classic)
   - pastas públicas e estáticos do wordpress sugestão de utilizar o EFS (Elastic File Sistem)
   - Aplicação Wordpress precisa estar rodando na porta 80 ou 8080;

## Configurações feitas em ambiente AWS

* **VPC**

    * Foi criada uma VPC para a construção do projeto (ATV_Docker-vpc). 
    * Foram criadas 2 Subredes Privadas e 2 Subredes Públicas, para as instâncias e para o load balancer, respectivamente (em duas AZ).
    * A VPC foi criada junto com um NAT Gateway.
    * A VPC foi criada sem endpoint.

      
* **Security Groups**
  
    * Foi criado um Security Group para as instâncias, RDS e Load Balancer.
    * Portas utilizadas para configurar os security groups:
      - HTTP	TCP	80 
      - HTTPS	TCP	443 
      - SSH	TCP	22 
      - MYSQL/Aurora TCP	3306 
      - NFS	TCP	2049 

 
* **EFS**

    * Foi criado um Elastic File System para que os serviços se comuniquem entre as instâncias.
    * O nome dado ao EFS foi EFS_ATV_Docker.

 
* **RDS**
  
    * Foi criado um RDS (Relational Database) MySQL 8.0.35.
    * O nome dado foi dbwordpress.
    * O modelo utilizado foi no tier gratuito.
    * A classe utilizada foi d3.t3micro.
    * Armazenamento de 20gb gp2.


* **EC2**
  
    *  O modelo utilizado para a criação das instâncias foi:
    *  AMI: Amazon Linux 2.
    *  Modelo: t3.small.
    *  EBS: 8gb gp2.
    *  No final da configuração, foi utilizado um userdata.sh para fazer as configurações iniciais da máquina para uso e algumas configurações adicionais.
 
* **USERDATA Comentado** 

```
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
      WORDPRESS_DB_USER: ******
      WORDPRESS_DB_PASSWORD: ********
      WORDPRESS_TABLE_CONFIG: wp_
 EOF

```

  * **Configuração adicional na instância**

    * Na instância, eu verifiquei a montagem do EFS utiliznado o comando `` df -h ``
    * Utilizei também o `` docker-compose up -d `` e o `` docker ps `` para a montagem.
    * Confirmei com o comando `` docker exec -it (ID do container wordpress) /bin/bash ``
    * Utilizei também o ``apt-get update`` e `` apt-get install default-mysql-client -y ``
    * Para entrar no banco de dados e confirmar o que foi feito, utilizei `` mysql -h (Endpoint do RDS) -P 3306 -u admin -p ``
  
  * **Clone da instância**

    * Foi criada uma cópia da primeira AMI para servir de modelo para a segunda instância criada para que o Load Balancer (configurado posteriormente) possa funcionar corretamente.
    * Após a criação da cópia da AMI, esse modelo foi utilizado para a criação da instância que subiu em uma AZ diferente da primeira instância.

  
  * **VPC ENDPOINT**

    * Foi criado um VPC ENDPOINT para conexão das instâncias, pois ambas encontram-se em subredes privadas.
    * O endpoint utilizado foi um EC2 Instance Connect Endpoint.


* **Target Group**

  * Foi criado um Target Group para conectar as instâncias com o load balancer.
  * O nome dado ao TG foi TG-ec2-atv-Docker.
  * A porta utilizada foi a 80, ipv4 HTTP1.
  * As duas instâncias criadas anteriormente foram adicionadas ao target group.

  
* **Load Balancer**

  * Foi criado um load balancer (aplicação) para fazer o balanceamento do tráfego entre as instâncias.
  * Em listeners, foi utilizada a porta 80, assim como no target group.
  * O nome dado foi LB-atv-Docker.
  * O load balancer foi criado utilizando as duas subredes públicas para estar disponível nas duas zonas de disponibilidade das instâncias previamente criadas.

* **Auto Scaling**

  * Foi criado um modelo de execução do Auto Scaling para deixar ele pronto para iniciar.
  * Será selecionada a VPC utilizada no projeto.
  * Ele será anexado ao load balancer criado anteriormente, junto ao target group.
  * O Auto Scaling em si não foi executado, pois foi sugerido iniciar apenas próximo da apresentação, a fim de evitar custos desnecessários.

