# OpenWA da Oficina de Software

Gateway de WhatsApp compartilhado pelos projetos da Oficina (Hikya Chat e os que vierem), mantido pelo Claude. Usamos o [rmyndharis/OpenWA](https://github.com/rmyndharis/OpenWA) (MIT) **sem alterar o código**. Este repositório (`ofcinadesoftware/Oficina.OpenWa`) guarda só o nosso deploy: compose, modelo de `.env`, backup e esta documentação.

## Estrutura

Este repositório fica **dentro** de um clone do OpenWA original, na pasta `oficina/` (o compose constrói a imagem a partir de `..`):

```
/opt/openwa/            clone de github.com/rmyndharis/OpenWA, no tag da versão em uso
/opt/openwa/oficina/    arquivos deste repositório (Oficina.OpenWa) + segredos (.env etc., fora do git)
```

No PC: `Oficina.Software/OpenWA/` (clone do original) e `Oficina.Software/OpenWA/oficina/` (clone deste repositório). O clone do original ignora a pasta pela linha `oficina/` em `.git/info/exclude`.

A VM não tem acesso ao GitHub (como no Kid Money e no Accounts): os arquivos deste repositório vão do PC para lá, sempre a partir de um commit, e `.versao-deploy` registra qual commit está na VM:

```bash
cd Oficina.Software/OpenWA/oficina
git archive HEAD | ssh -i ~/.ssh/oficina_vps ubuntu@147.15.7.73 'cd /opt/openwa/oficina && tar -x'
ssh -i ~/.ssh/oficina_vps ubuntu@147.15.7.73 "echo 'commit=$(git rev-parse --short HEAD) (ofcinadesoftware/Oficina.OpenWa)' > /opt/openwa/oficina/.versao-deploy"
```

O `tar` só sobrescreve os arquivos versionados; `.env`, `chaves-apps.env` e `painel-senha.txt` ficam intactos.

Não há fork: as versões novas do OpenWA vêm direto do original (`git fetch --tags`), e nós escolhemos quando trocar de tag. Fork só se um dia precisarmos corrigir o código antes do autor.

## Onde roda

| Item | Valor |
|---|---|
| VM | `instance-kidmoney` (Oracle Cloud, ARM64), a mesma do Kid Money. Detalhes: `KidMoney/docs/servidor-producao.md` |
| Pasta | `/opt/openwa` (clone do OpenWA original no tag da versão) + `/opt/openwa/oficina` (este repositório + `.env`) |
| Versão | fixa: imagem `oficina-openwa:<OPENWA_VERSION>`, construída do tag `v<OPENWA_VERSION>` (hoje 0.26.0) |
| Acesso público | `https://wa.oficinadesoftware.com` (o `wa.oficinadesoftware.com.br` já está no Caddy, mas ainda sem DNS; painel, API em `/api/`, Swagger em `/api/docs`), pelo Caddy do Kid Money (`/opt/kidmoney/Caddyfile`, rede `kidmoney_edge`) |
| Acesso interno | `http://openwa-interno:2785/api/` pela rede Docker `openwa`, para apps na mesma VM (não passa pelo Caddy) |
| Proteção | painel e Swagger pedem usuário `oficina` + senha no Caddy (senha só na VM: `/opt/openwa/oficina/painel-senha.txt`); `/api/*` fica aberto e exige chave. Chaves de apps na VM são restritas por `allowedIps` ao IP fixo do container |
| DNS | registro A `wa` → `147.15.7.73` na zona `oficinadesoftware.com` (cPanel da HostGator). Para ativar o .com.br: criar o A `wa` na Cloudflare ("DNS only"); o Caddy emite o certificado sozinho |
| Engine | Baileys desde 03/11/2026 (sem navegador). O whatsapp-web.js 1.34.7 parou de gerar QR com o WhatsApp Web atual; trocar de motor exige ler o QR de todas as sessões de novo |
| Dados | volume `openwa_data`: SQLite, sessões pareadas, mídia |
| Backup | `backup-openwa.sh` no cron às 04:30 → `/opt/openwa/backups`, 14 dias |

## Primeiro deploy

```bash
sudo mkdir -p /opt/openwa && sudo chown ubuntu:ubuntu /opt/openwa
git clone --branch v0.26.0 --depth 1 https://github.com/rmyndharis/OpenWA.git /opt/openwa
mkdir -p /opt/openwa/backups /opt/openwa/oficina && sudo chown 997:997 /opt/openwa/backups   # 997 = usuário openwa do container
# enviar os arquivos deste repositório (ver "Estrutura") e então:
cd /opt/openwa/oficina && cp .env.exemplo .env && chmod 600 .env
# preencher API_MASTER_KEY e API_KEY_PEPPER (openssl rand -hex 32) e SSRF_ALLOWED_HOSTS
docker compose up -d --build                         # build arm64 na própria VM (demora alguns minutos)
chmod +x backup-openwa.sh && (crontab -l; echo '30 4 * * * /opt/openwa/oficina/backup-openwa.sh >> /opt/openwa/backup.log 2>&1') | crontab -
```

Depois, no painel (`https://wa.oficinadesoftware.com`, primeiro a senha do Caddy), entre com a `API_MASTER_KEY` e crie **uma chave de API por projeto**. A chave ADMIN não vai para nenhum app.

## Como um app se conecta

**App fora da VM:** use `https://wa.oficinadesoftware.com/api/` com a chave dele. O webhook precisa ser uma URL HTTPS pública do app (hosts públicos não entram no `SSRF_ALLOWED_HOSTS`).

**App na mesma VM:** use a rede interna. No compose do app:

```yaml
services:
  hikyachat-api:
    environment:
      OpenWA__Url: http://openwa-interno:2785/api/
    networks: [default, openwa]
networks:
  openwa:
    external: true
```

Use sempre `openwa-interno`, não `openwa`: se o app também estiver na `kidmoney_edge` (rede do Caddy), `openwa` resolve pelo IP de lá e a chave dá 403.

E no `.env` do OpenWA, o nome do serviço entra em `SSRF_ALLOWED_HOSTS` (senão o OpenWA recusa entregar o webhook num host da rede privada). Depois: `docker compose up -d`.

Cada projeto usa sessões com o próprio prefixo e registra os próprios webhooks, sempre com `secret` (HMAC-SHA256 em `X-OpenWA-Signature`). Contrato: Swagger em `https://wa.oficinadesoftware.com/api/docs` e `docs/06-api-specification.md`.

## Consumidores

| App | Onde | Chave | Webhook |
|---|---|---|---|
| Hikya Chat (produção) | `/opt/hikyachat`, serviço `hikyachat-api`, IP fixo 172.21.100.10 | `hikyachat` | `http://hikyachat-api:8080/webhooks/openwa` |
| Hikya Chat (sandbox) | `/opt/hikyachat`, serviço `hikyachat-api-sandbox`, IP fixo 172.21.100.11 | `hikyachat-sandbox` | `http://hikyachat-api-sandbox:8080/webhooks/openwa` |
| Karfy (sandbox) | `/opt/karfy-sandbox`, serviço `api` (alias `karfy-sandbox-api`), IP fixo 172.21.100.21 | `karfy-sandbox` | `http://karfy-sandbox-api:8080/webhooks/whatsapp` |
| Karfy (produção, ainda não subiu) | alias `karfy-api`, IP fixo 172.21.100.20 | a criar | `http://karfy-api:8080/webhooks/whatsapp` |
| Kid Money (sandbox) | `/opt/kidmoney`, serviço `api-sandbox` (alias `kidmoney-api-sandbox`), IP fixo 172.21.100.31 | `kidmoney-sandbox` (só a sessão `kidmoney-sandbox` e o chat 5592991258492) | `http://kidmoney-api-sandbox:8080/webhooks/whatsapp` (cadastrado com a chave admin: a chave do app não alcança `/webhooks`) |
| Kid Money (produção, aguarda o Bruno) | serviço `api-prod` (alias `kidmoney-api`), IP fixo 172.21.100.30 | `kidmoney-prod` (só a sessão `kidmoney-prod`) | `http://kidmoney-api:8080/webhooks/whatsapp` |

Uma chave por ambiente: assim o sandbox não alcança as sessões da produção, e revogar uma não derruba a outra. Cada ambiente registra o webhook (com o próprio `secret`) só nas próprias sessões. Eventos do Hikya: `message.received`, `message.sent`, `message.ack`, `message.failed`, `session.status`.

As chaves ficam em `/opt/openwa/oficina/chaves-apps.env` na VM (`chmod 600`, fora do git) e são copiadas de lá para o `.env` do app, também na VM. Nunca vão para repositório nem chat. As duas são OPERATOR sem escopo de sessões, porque o Hikya cria sessões pela tela dele (criar sessão exige chave sem escopo). Em compensação, cada uma só vale a partir do IP fixo do seu container (`allowedIps`: `172.21.100.10/32` e `172.21.100.11/32`): usadas de qualquer outro lugar, inclusive pela internet, dão 403. Mudou o IP? `PUT /api/auth/api-keys/{id}` com o novo `allowedIps`.

### Apps que criam sessões dividem a mesma instância

Criar sessão exige chave sem escopo de sessões, e uma chave sem escopo enxerga, envia e registra webhook em **todas** as sessões da instância, criadas por qualquer chave (o OpenWA não guarda quem criou a sessão). Hoje Hikya e Karfy (produção e sandbox) dividem esta instância de propósito, até o Hikya virar a camada de WhatsApp dos apps. Por isso, todo app que usa esta instância segue estas regras:

- Usa só os `sessionId` gravados no próprio banco. Nunca lista sessões para escolher uma e nunca aceita `sessionId` vindo da tela ou da requisição.
- Registra webhook só nas próprias sessões e descarta evento de sessão desconhecida.
- Dá às sessões nomes com o prefixo do app (`hikya-`, `karfy-`).
- Tem uma chave por ambiente, OPERATOR, presa ao IP fixo do container.
- No sandbox, usa só números de teste.

Quando o primeiro cliente externo pagante conectar um número, separe as instâncias.

Mudou URL, porta ou chave? Avise a sessão do app para ela ajustar a configuração.

Regra de testes: mensagens de teste só para **5592991258492**.

## Atualizar

**Nosso deploy** (compose, backup, docs): commit e push aqui, depois envie para a VM (ver "Estrutura") e rode `docker compose up -d` em `/opt/openwa/oficina`.

**Versão do OpenWA**: as versões saem em github.com/rmyndharis/OpenWA/releases. Nada atualiza sozinho. A VM não tem OpenWA de sandbox (produção e sandbox dos apps usam a mesma instância), então **toda versão nova e toda mudança de configuração é testada antes no OpenWA local do PC** (`Oficina.Software/OpenWA`, `npm ci && npm run build && npm run start:prod`, em `http://127.0.0.1:2785`). Só depois de testada vai para a VM:

```bash
# na VM: trocar o tag e a versão juntos (o .env.exemplo do repositório também, para registrar)
cd /opt/openwa && git fetch --tags && git checkout vX.Y.Z
sed -i 's/^OPENWA_VERSION=.*/OPENWA_VERSION=X.Y.Z/' oficina/.env
cd oficina && ./backup-openwa.sh && docker compose up -d --build
```

Leia o `CHANGELOG.md` antes: algumas versões pedem migração (`docs/14-migration-guide.md`). Para voltar, faça o checkout do tag anterior e volte o `OPENWA_VERSION` (a imagem antiga continua no Docker).

## Restore

`docs/11-operational-runbooks.md` (o `scripts/restore.sh` roda dentro do container). Com a pasta `sessions/` restaurada, as sessões voltam sem ler o QR Code.

## Riscos

O WhatsApp não autoriza clientes não oficiais: um número pode ser banido, principalmente com envio em massa ou para quem não tem o número salvo. O `SEND_PACING_ENABLED` ajuda, mas não elimina o risco. Use números que a gente aceite perder.
