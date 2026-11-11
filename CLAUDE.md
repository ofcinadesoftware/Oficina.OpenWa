# OpenWA da Oficina: instruções para o Claude Code

Esta é a sessão "OpenWA": dona do gateway de WhatsApp compartilhado pelos apps da Oficina (Hikya Chat, Karfy, Kid Money; produção e sandbox na mesma instância). Hospeda, atualiza, reinicia e configura o gateway. Os apps só consomem a API e os webhooks; a configuração do lado deles é com a sessão de cada app. O manual completo é o **README.md** desta pasta; o histórico, `docs/historico-cerebro.md` (pode estar velho, confira na VM).

## Mapa
- `OpenWA/` (raiz): clone do original `rmyndharis/OpenWA`, no tag da versão em uso (hoje v0.26.0). **Não altere o código do original**; versões novas vêm de `git fetch --tags`.
- `OpenWA/oficina/`: o nosso repositório (`ofcinadesoftware/Oficina.OpenWa`): compose, `.env.exemplo`, backup e documentação. O clone do original ignora esta pasta (`.git/info/exclude`).
- **Antes de mexer, rode `git pull` em `oficina/`**: o clone local já ficou atrás do GitHub (em 10/11, local em bb5f13a e remoto com d2bef3e).
- A VM recebe os arquivos sempre a partir de um commit (`git archive HEAD`), e `.versao-deploy` registra qual commit está lá (ver README, "Estrutura").

## Regras
- **Teste local antes da VM**: toda versão nova e toda mudança de configuração passam antes pelo OpenWA local (`npm ci && npm run build && npm run start:prod` na raiz, `http://127.0.0.1:2785`). A VM não tem OpenWA de sandbox.
- **Backup antes** de `docker compose up -d --build` na VM (`./backup-openwa.sh`). Leia o `CHANGELOG.md` antes de trocar de versão.
- **Chaves**: uma por app e por ambiente, OPERATOR, presa ao IP fixo do container (`allowedIps`). Ficam só na VM (`chaves-apps.env`, `.env`, `painel-senha.txt`), copiadas VM para VM. Nunca no repositório, no chat ou no código dos apps. A chave ADMIN não vai para nenhum app. Não abra arquivos de chave sem pedido expresso do Bruno.
- **Teste de mensagem só para o número de teste do Bruno** (README, "Regra de testes"). Nunca para outro número.
- **Limite de 300 envios por dia por sessão** (`SEND_PACING_WARMUP_SCHEDULE`, decisão do Bruno em 08/11); a trava de conversas novas (`SEND_PACING_COLD_DAILY_CAP`) segue no padrão. Número recém-criado: considere voltar a rampa.
- **Trocar de motor** (whatsapp-web.js / Baileys) exige ler o QR de todas as sessões de novo. Só com o Bruno avisado.
- Risco permanente: cliente não oficial, número pode ser banido. Use números que se aceite perder.

## Consumidores
A tabela de apps, serviços, IPs fixos, chaves e webhooks está no README, seção "Consumidores". Não duplique aqui. Regras para todo app desta instância (README, "Apps que criam sessões dividem a mesma instância"): só `sessionId` do próprio banco, prefixo do app no nome da sessão, webhook só nas próprias sessões e com `secret`, sandbox só com número de teste.

**Mudou URL, porta, chave ou IP? Avise a sessão do app** (Hikya, Karfy, Kid Money) para ela ajustar a configuração. Separar instâncias quando o primeiro cliente externo pagante conectar um número.

## Estado em 10/11/2026
- No ar em `https://wa.oficinadesoftware.com` (painel, `/api/`, `/api/docs`) e pela rede interna `http://openwa-interno:2785/api/`. O `wa.oficinadesoftware.com.br` já está no Caddy, mas **aguarda DNS** (registro A `wa` na Cloudflare, "DNS only").
- Motor Baileys desde 03/11; não se anuncia online desde 08/11 (`BAILEYS_MARK_ONLINE_ON_CONNECT=false`).
- **Todas as sessões desconectadas desde 07/11** (a da Lume, desvinculada pelo celular em 08/11). Qualquer app que for usar WhatsApp precisa de QR novo.
- `docs/historico-cerebro.md` ainda não está versionado.
