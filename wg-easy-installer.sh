#!/bin/bash
#
# Copyright (c) 2024 Gabriel Soares de Lima
#
# Autor: Gabriel Soares de Lima
# Email: gabrielsdelima75@gmail.com
# GitHub: https://github.com/gabrielsdelima75
#
# Licença:
# Este script é fornecido "como está", sem garantias de qualquer tipo, expressas ou implícitas, incluindo, mas não se limitando, a garantias de comercialização e adequação para um propósito específico.
# Você pode distribuir e modificar este script, desde que o copyright e o aviso de licença acima sejam mantidos em todas as cópias ou partes substanciais do script.
#
# Para mais informações sobre a licença, consulte a Licença MIT (ou qualquer outra licença que você escolha).
#
# Uso:
# Este script automatiza a instalação do wg-easy em sistemas Linux, configurando o WireGuard VPN com a interface WebUI.
#
# Histórico de alterações:
# 2024-12-01: Gabriel Soares de Lima - Primeira versão do script.

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root."
  exit
fi

# Verifica dependências
echo "Verificando dependências..."

# Verifica o gerenciador de pacotes
if command -v apt &> /dev/null; then
  PACKAGE_MANAGER="apt"
elif command -v yum &> /dev/null; then
  PACKAGE_MANAGER="yum"
elif command -v dnf &> /dev/null; then
  PACKAGE_MANAGER="dnf"
else
  echo "Gerenciador de pacotes não encontrado. Este script é compatível com APT (Ubuntu/Debian) e YUM/DNF (CentOS/Fedora/RHEL)."
  exit 1
fi

# Função para instalar pacotes
install_package() {
  PACKAGE=$1
  if [ "$PACKAGE_MANAGER" == "apt" ]; then
    apt install -y "$PACKAGE"
  elif [ "$PACKAGE_MANAGER" == "yum" ]; then
    yum install -y "$PACKAGE"
  elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
    dnf install -y "$PACKAGE"
  fi
}

# Verifica se curl, git e node.js estão instalados
if ! command -v curl &> /dev/null; then
  echo "curl não encontrado. Instalando..."
  install_package curl
fi

if ! command -v git &> /dev/null; then
  echo "git não encontrado. Instalando..."
  install_package git
fi

if ! command -v node &> /dev/null; then
  echo "node.js não encontrado. Instalando..."
  if [ "$PACKAGE_MANAGER" == "apt" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 
    install_package nodejs
  elif [ "$PACKAGE_MANAGER" == "yum" ] || [ "$PACKAGE_MANAGER" == "dnf" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - 
    install_package nodejs
  fi
fi

echo "Iniciando a instalação do wg-easy..."

# Habilita o encaminhamento de pacotes IP
echo "Configurando o sistema..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.src_valid_mark=1" >> /etc/sysctl.conf
sysctl -p

# baixa o arquivo wg-easy.service alterado do nosso repo
echo "Baixando wg-easy.service..."
curl -Lo /etc/systemd/system/wg-easy.service https://raw.githubusercontent.com/gabrielsdelima75/wgeasy-install-script/main/wg-easy.service

# Clona o repositório wg-easy
echo "Baixando o wg-easy..."
git clone https://github.com/wg-easy/wg-easy
cd wg-easy || exit

# coisas do node
mv src /app
cd /app || exit

npm ci --omit=dev
cp -r node_modules ..

# Solicita as variáveis de configuração
echo "Digite o idioma para o Web UI (opções: pt, en, ua, ru, tr, no, pl, fr, de, ca, es, ko, vi, nl, is, chs, cht, it, th, hi, ja, si): "
read -p "Idioma (default: pt): " LANG
LANG=${LANG:-pt}

echo "Digite o endereço público ou IP do servidor (WG_HOST): "
read -p "IP público (default: REPLACEME): " WG_HOST
WG_HOST=${WG_HOST:-REPLACEME}

echo "Digite a senha para a interface do Web UI (ou deixe em branco para não usar senha): "
read -sp "Senha: " PASSWORD
echo
if [ -n "$PASSWORD" ]; then
  PASSWORD_HASH=$(node -e "console.log(require('crypto').createHash('sha256').update('$PASSWORD').digest('hex'))")
else
  PASSWORD_HASH=""
fi

# Solicita o DNS para os clientes (opção de personalizar)
echo "Digite os servidores DNS para os clientes (default: 1.1.1.1, 1.0.0.1): "
read -p "DNS (default: 1.1.1.1, 1.0.0.1): " WG_DEFAULT_DNS
WG_DEFAULT_DNS=${WG_DEFAULT_DNS:-"1.1.1.1, 1.0.0.1"}

# Solicita a porta do painel Web UI
echo "Digite a porta TCP para o Web UI (default: 51821): "
read -p "Porta (default: 51821): " PORT
PORT=${PORT:-51821}

# Solicita a porta UDP para a VPN
echo "Digite a porta UDP para o serviço WireGuard (default: 51820): "
read -p "Porta UDP (default: 51820): " WG_PORT
WG_PORT=${WG_PORT:-51820}

# Solicita o dispositivo de rede
echo "Digite o dispositivo de rede para encaminhar o tráfego WireGuard (default: eth0): "
read -p "Dispositivo de rede (default: eth0): " WG_DEVICE
WG_DEVICE=${WG_DEVICE:-eth0}

# Solicita a MTU
echo "Digite o valor da MTU para os clientes (default: 1420): "
read -p "MTU (default: 1420): " WG_MTU
WG_MTU=${WG_MTU:-1420}

# Solicita os IPs permitidos
echo "Digite os IPs permitidos para os clientes (default: 0.0.0.0/0, ::/0): "
read -p "IPs permitidos (default: 0.0.0.0/0, ::/0): " WG_ALLOWED_IPS
WG_ALLOWED_IPS=${WG_ALLOWED_IPS:-"0.0.0.0/0,::/0"}

# Substitui as variáveis no arquivo wg-easy.service
echo "Configurando o wg-easy.service..."
sed -i "s|Environment=\"PASSWORD=REPLACEME\"|Environment=\"PASSWORD_HASH=${PASSWORD_HASH}\"|g" /etc/systemd/system/wg-easy.service
sed -i "s|Environment=\"LANG=pt\"|Environment=\"LANG=${LANG}\"|g" /etc/systemd/system/wg-easy.service
sed -i "s|Environment=\"WG_HOST=REPLACEME\"|Environment=\"WG_HOST=${WG_HOST}\"|g" /etc/systemd/system/wg-easy.service
sed -i "s|Environment=\"WG_DEFAULT_DNS=8.8.8.8,8.8.4.4\"|Environment=\"WG_DEFAULT_DNS=${WG_DEFAULT_DNS}\"|g" /etc/systemd/system/wg-easy.service
sed -i "s|Environment=\"PORT=51821\"|Environment=\"PORT=${PORT}\"|g" /etc/systemd/system/wg-easy.service
sed -i "s|Environment=\"WG_PORT=51820\"|Environment=\"WG_PORT=${WG_PORT}\"|g" /etc/systemd/system/wg-easy.service
sed -i "s|Environment=\"WG_DEVICE=ens1\"|Environment=\"WG_DEVICE=${WG_DEVICE}\"|g" /etc/systemd/system/wg-easy.service
sed -i "s|Environment=\"WG_MTU=1420\"|Environment=\"WG_MTU=${WG_MTU}\"|g" /etc/systemd/system/wg-easy.service
sed -i "s|Environment=\"WG_ALLOWED_IPS=0.0.0.0/0,::/0\"|Environment=\"WG_ALLOWED_IPS=${WG_ALLOWED_IPS}\"|g" /etc/systemd/system/wg-easy.service

# Configura o serviço
echo "Habilitando e iniciando o serviço wg-easy..."
systemctl daemon-reload
systemctl enable --now wg-easy.service

echo "Instalação do wg-easy concluída com sucesso!"