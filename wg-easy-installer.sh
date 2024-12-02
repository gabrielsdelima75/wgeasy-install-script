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
if command -v apt-get &> /dev/null; then
  PACKAGE_MANAGER="apt-get"
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
  if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
    apt-get install -y "$PACKAGE"
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
  if [ "$PACKAGE_MANAGER" == "apt-get" ]; then
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
    install_package nodejs
  elif [ "$PACKAGE_MANAGER" == "yum" ] || [ "$PACKAGE_MANAGER" == "dnf" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_16.x | bash -
    install_package nodejs
  fi
fi

echo "Iniciando a instalação do wg-easy..."

# Habilita o encaminhamento de pacotes IP
echo "Configurando o sistema..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.src_valid_mark=1" >> /etc/sysctl.conf
sysctl -p

# Clona o repositório wg-easy
echo "Baixando o wg-easy..."
git clone https://github.com/wg-easy/wg-easy
cd wg-easy || exit

git checkout production
mv src /app
cd /app || exit

npm ci --omit=dev
cp -r node_modules ..

# Configura firewall
echo "Detectando firewall em uso..."

# Verifica qual firewall está sendo usado
if systemctl is-active --quiet ufw; then
  FIREWALL="ufw"
elif systemctl is-active --quiet firewalld; then
  FIREWALL="firewalld"
else
  FIREWALL="iptables"
fi

# Função para configurar o firewall
configure_firewall() {
  if [ "$FIREWALL" == "ufw" ]; then
    echo "Configuração do UFW..."
    ufw allow 51821/tcp # Web UI
    ufw allow 51820/udp # WireGuard
  elif [ "$FIREWALL" == "firewalld" ]; then
    echo "Configuração do Firewalld..."
    firewall-cmd --zone=public --add-port=51821/tcp --permanent # Web UI
    firewall-cmd --zone=public --add-port=51820/udp --permanent # WireGuard
    firewall-cmd --reload
  else
    echo "Configuração do iptables..."
    iptables -A INPUT -p tcp --dport 51821 -j ACCEPT # Web UI
    iptables -A INPUT -p udp --dport 51820 -j ACCEPT # WireGuard
    service iptables save # Salva as regras no iptables
  fi
}

# Chama a função para configurar o firewall
configure_firewall

# Retorna para o diretório anterior
cd - || exit

# Baixa o arquivo de serviço wg-easy
echo "Baixando o arquivo de serviço wg-easy.service..."
curl -Lo /etc/systemd/system/wg-easy.service https://raw.githubusercontent.com/wg-easy/wg-easy/production/wg-easy.service

# Solicita a senha e gera a hash
read -sp "Digite a senha para a interface do Web UI: " PASSWORD
echo
PASSWORD_HASH=$(node -e "console.log(require('crypto').createHash('sha256').update('$PASSWORD').digest('hex'))")

# Substitui as variáveis no arquivo wg-easy.service
echo "Configurando o wg-easy.service..."
sed -i "s|Environment=\"PASSWORD=REPLACEME\"|Environment=\"PASSWORD_HASH=${PASSWORD_HASH}\"|g" /etc/systemd/system/wg-easy.service

# Adiciona variáveis de ambiente LANG e WG_DEFAULT_DNS
echo "Adicionando variáveis de ambiente..."
sed -i '/\[Service\]/a Environment="LANG=pt"' /etc/systemd/system/wg-easy.service
sed -i '/\[Service\]/a Environment="WG_DEFAULT_DNS=8.8.8.8,8.8.4.4"' /etc/systemd/system/wg-easy.service

# Configura o serviço
echo "Habilitando e iniciando o serviço wg-easy..."
systemctl daemon-reload
systemctl enable --now wg-easy.service

echo "Instalação do wg-easy concluída com sucesso!"