#!/bin/bash
# ============================================================
#  Setup GitHub — Viagem EUA / México / Cruzeiro 2026
#  Cria o repositório, inicializa o git e publica o site.
#  Execute UMA VEZ. Depois disso o viagem_dashboard.py
#  faz o push automaticamente a cada atualização do JSON.
# ============================================================

set -e
REPO="viagem-eua-2026"
OWNER="fabianorondonia-source"
SITE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Setup GitHub Pages — Viagem EUA 2026      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Token do Chaveiro ──────────────────────────────────
TOKEN=$(security find-generic-password -s "github-fabiano-token" \
        -a "$OWNER" -w 2>/dev/null || true)

if [ -z "$TOKEN" ]; then
  echo "❌ Token não encontrado no Chaveiro do Mac."
  echo ""
  echo "Crie um PAT em: https://github.com/settings/tokens"
  echo "  Permissões necessárias: repo, pages"
  echo ""
  echo "Depois salve com o comando:"
  echo "  security add-generic-password -s github-fabiano-token \\"
  echo "    -a $OWNER -w SEU_TOKEN -U"
  echo ""
  read -p "Cole o token agora para continuar (ou Enter para sair): " TOKEN
  if [ -z "$TOKEN" ]; then
    echo "Saindo."
    exit 1
  fi
  # Salva no Chaveiro para uso futuro
  security add-generic-password -s "github-fabiano-token" \
    -a "$OWNER" -w "$TOKEN" -U 2>/dev/null && \
    echo "✅ Token salvo no Chaveiro." || true
fi

# ── 2. Cria o repositório via API (ignora se já existir) ──
echo "▶ Verificando/criando repositório $OWNER/$REPO..."
HTTP=$(curl -s -o /tmp/_gh_create.json -w "%{http_code}" \
  -X POST "https://api.github.com/user/repos" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$REPO\",\"private\":false,\"description\":\"Painel de viagem EUA/México/Cruzeiro 2026 — Fabiano & Renata\",\"auto_init\":false}")

if [ "$HTTP" = "201" ]; then
  echo "✅ Repositório criado: https://github.com/$OWNER/$REPO"
elif [ "$HTTP" = "422" ]; then
  echo "ℹ️  Repositório já existe — usando o existente."
else
  echo "⚠️  API respondeu $HTTP:"
  cat /tmp/_gh_create.json
fi

# ── 3. Inicializa git na pasta Site GitHub ─────────────────
cd "$SITE_DIR"

if [ ! -d ".git" ]; then
  git init -b main
  echo "✅ Git inicializado."
fi

# Remove travas residuais do iCloud
for lk in index.lock HEAD.lock objects/maintenance.lock refs/remotes/origin/main.lock; do
  rm -f ".git/$lk" 2>/dev/null || true
done

# ── 4. Configura remote com token ─────────────────────────
git remote remove origin 2>/dev/null || true
git remote add origin "https://$OWNER:$TOKEN@github.com/$OWNER/$REPO.git"

# ── 5. Commit e push ──────────────────────────────────────
git config user.email "fabianorondonia@gmail.com"
git config user.name "Fabiano Roberto"

git add -A
git diff --cached --quiet && echo "ℹ️  Nada novo para commitar." || \
  git commit -m "Publicação inicial — Viagem EUA/México/Cruzeiro 2026"

echo "▶ Enviando para o GitHub..."
git push -u origin main
echo "✅ Push concluído."

# ── 6. Ativa GitHub Pages (branch main, raiz /) ───────────
echo "▶ Ativando GitHub Pages..."
HTTP_PAGES=$(curl -s -o /tmp/_gh_pages.json -w "%{http_code}" \
  -X POST "https://api.github.com/repos/$OWNER/$REPO/pages" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"source":{"branch":"main","path":"/"}}')

if [ "$HTTP_PAGES" = "201" ] || [ "$HTTP_PAGES" = "409" ]; then
  echo "✅ GitHub Pages ativado."
else
  # Tenta via PUT (atualização se já existir)
  curl -s -X PUT "https://api.github.com/repos/$OWNER/$REPO/pages" \
    -H "Authorization: token $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"source":{"branch":"main","path":"/"}}' > /dev/null
  echo "ℹ️  Pages configurado (PUT)."
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅ Tudo pronto!                                         ║"
echo "║                                                          ║"
echo "║  Repositório : https://github.com/$OWNER/$REPO  ║"
echo "║  Site        : https://$OWNER.github.io/$REPO/  ║"
echo "║                                                          ║"
echo "║  O site fica disponível em ~2 minutos após o push.       ║"
echo "║  A cada mudança no viagem_dados.json, o dashboard        ║"
echo "║  fará push automático para manter o site atualizado.     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Abre o site no browser após 3 segundos
sleep 3 && open "https://$OWNER.github.io/$REPO/" &

read -p "Pressione Enter para fechar..."
