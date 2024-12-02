# Automação de Instalação do wg-easy

Este repositório contém um script Bash para automatizar a instalação do **wg-easy**, uma interface web para o **WireGuard VPN**. O script configura o ambiente necessário e instala as dependências para que você possa configurar e gerenciar facilmente o seu servidor WireGuard com uma interface gráfica.

## Características

- Instala o **wg-easy** e suas dependências.
- Configura o **WireGuard VPN** com uma interface web para fácil gerenciamento.
- Suporta firewall **iptables**, **ufw** e **firewalld**.
- Configurações de rede como `WG_DEFAULT_DNS` (com DNS da CloudFlare) e `LANG` (configurado para `pt`).
- Personalização da senha de acesso à interface web, utilizando a hash gerada automaticamente.

## Requisitos

Antes de executar o script, verifique se o sistema possui as seguintes dependências instaladas:

- **curl**
- **git**
- **wireguard-tools**
- **iptables**, **ufw** ou **firewalld** (dependendo da configuração do firewall)
- **Node.js** (versão >= 20.x)
- **Dependêcias node: bcryptjs e readline-sync**

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
```
## Como usar o script
# Passo 1: Baixar o script
Clone este repositório no seu servidor ou máquina que irá rodar o wg-easy:

```bash
git clone https://github.com/gabrielsdelima75/wgeasy-install-script.git
cd wgeasy-install-script
```
## Passo 2: Tornar o script executável
Antes de executar o script, você precisa torná-lo executável:

```bash
chmod +x install-wg-easy.sh
```

## Passo 3: Executar o script
Agora você pode executar o script para instalar e configurar o wg-easy:

```bash
./install-wg-easy.sh
```
O script irá configurar automaticamente as variáveis de ambiente, como o DNS do Google (8.8.8.8 e 8.8.4.4), o idioma (LANG=pt_BR.UTF-8), além de instalar o wg-easy, o WireGuard e configurar o firewall de acordo com a sua configuração (iptables, ufw ou firewalld).

## Passo 4: Acessar a interface web
Após a instalação, você pode acessar a interface web do wg-easy através do navegador, utilizando o IP ou domínio do seu servidor, na porta configurada (por padrão 51821):

## Passo 5: Definir a senha para a interface web
O script irá gerar automaticamente uma senha com hash para o acesso à interface web. Caso queira alterar a senha, use o comando abaixo para gerar um novo hash:

```bash
node wgpw-local.js 'nova_senha'
Copie a hash gerada e cole no arquivo wg-easy.service na variável PASSWORD_HASH para atualizar a senha.
```

## Isenção de Responsabilidade

**Este repositório e o script fornecido são fornecidos "como estão", sem garantias de qualquer tipo, expressas ou implícitas, incluindo, mas não se limitando, a garantias de comercialização ou adequação a um propósito específico.**

Ao utilizar este script, **você assume total responsabilidade pela implementação**, configuração e uso do mesmo em seu ambiente. O autor deste repositório não se responsabiliza por danos diretos, indiretos, incidentais, especiais ou consequenciais, incluindo, mas não se limitando, a perda de dados, falhas no sistema ou problemas de rede causados pelo uso deste script.

**Recomenda-se que você faça backup completo de seus dados e configure adequadamente seu ambiente antes de executar o script ou até mesmo revise o script por inteiro.**

Ao utilizar o script, você concorda em isentar o autor e os colaboradores de qualquer responsabilidade legal, financeira ou técnica relacionada ao uso deste software.