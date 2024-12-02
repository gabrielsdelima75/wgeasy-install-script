# Automação de Instalação do wg-easy

Este repositório contém um script Bash para automatizar a instalação do **wg-easy**, uma interface web para o **WireGuard VPN**. O script configura o ambiente necessário e instala as dependências para que você possa configurar e gerenciar facilmente o seu servidor WireGuard com uma interface gráfica.

## Características

- Instala o **wg-easy** e suas dependências.
- Configura o **WireGuard VPN** com uma interface web para fácil gerenciamento.
- Suporta firewall **iptables**, **ufw** e **firewalld**.
- Configurações de rede como `WG_DEFAULT_DNS` (com DNS do Google: 8.8.8.8 e 8.8.4.4) e `LANG` (configurado para `pt_BR.UTF-8`).
- Personalização da senha de acesso à interface web, utilizando a hash gerada automaticamente.

## Requisitos

Antes de executar o script, verifique se o sistema possui as seguintes dependências instaladas:

- **curl**
- **git**
- **Node.js** (versão >= 12.x)
- **iptables**, **ufw** ou **firewalld** (dependendo da configuração do firewall)

### Como verificar se as dependências estão instaladas

```bash
# Verificar curl
curl --version

# Verificar git
git --version

# Verificar Node.js
node -v

# Verificar firewall (iptables)
sudo iptables -L

# Verificar firewall (ufw)
sudo ufw status

# Verificar firewall (firewalld)
sudo firewall-cmd --state