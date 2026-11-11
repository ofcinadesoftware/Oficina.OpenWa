# Histórico técnico vindo do segundo cérebro

> Movido em 2026-11-10 da nota `_areas/hikya-chat.md` do cérebro do Bruno (a parte do OpenWA), que passou a guardar só o estado de negócio e de produto.
> Aqui fica só o que não estava no `README.md` deste repositório (Oficina.OpenWa) ou no `git log`. Texto quase literal, agrupado por data. Pode estar desatualizado: confira na VM antes de usar.

## 2026-11-01

- OpenWA local para testes no notebook: 0.26.0 em `http://localhost:2785`, mesma engine da produção, por `npm run start:prod` numa aba do terminal (não sobe sozinho com o Windows).
- Teste confirmou que chave sem escopo vê todas as sessões (base da regra de instância única para Karfy e Hikya).

## 2026-11-03

- Troca para Baileys. Kid Money sandbox integrado (avisos + aprovação respondendo "sim"); remetente `@lid` vem sem o 9; `RESOLVE_LID_TO_PHONE` ligado. Sessão `hikya-teste` precisou de QR novo.
- Botões e enquetes não servem para resposta: no Baileys o voto de enquete não chega.

## 2026-11-07

- A pedido do Bruno, todas as sessões desconectadas. Produção: logout em `karfy-01a1...`, `kidmoney-sandbox` e `hikya-teste` (todas `disconnected`, sem número; `hikya-teste` já não estava vinculada). Local: `bruno-claro` desvinculada. Qualquer app que use WhatsApp precisa ler QR de novo.

## 2026-11-08

- Chave `karfy-prod` criada (OPERATOR, allowedIps 172.21.100.20/32); README atualizado (entrou no commit bb5f13a).
- Limite diário de envio fixo em 300 por sessão (decisão do Bruno), backup antes; commit bb5f13a com push, VM nesse commit.
- O celular do número parava de notificar porque o Baileys se anuncia online ao conectar. Produção passou a usar `BAILEYS_MARK_ONLINE_ON_CONNECT=false` (commit d2bef3e no Oficina.OpenWa segundo a nota do cérebro, VM nesse commit). Mensagens seguem normais; só o "online"/visto por último deixa de vir do gateway. Em 10/11 o d2bef3e está no `main` do GitHub, mas este clone local estava atrás (último commit local bb5f13a): faça `git pull` antes de mexer.
- A sessão da Lume (`karfy-01a1bb7d...`) foi desvinculada pelo celular às 22:54 e precisa de QR novo; nenhuma sessão de produção conectada nesse momento.
