#!/bin/bash
SITE="$(cd "$(dirname "$0")" && pwd)"
OWNER="fabianorondonia-source"
REPO="viagem-eua-2026"

echo "▶ Removendo lock residual..."
rm -f "$SITE/.git/index.lock" "$SITE/.git/HEAD.lock" 2>/dev/null

echo "▶ Obtendo token do Chaveiro..."
TOKEN=$(security find-generic-password -s "github-fabiano-token" -a "$OWNER" -w 2>/dev/null)
if [ -n "$TOKEN" ]; then
  git -C "$SITE" remote set-url origin \
    "https://$OWNER:$TOKEN@github.com/$OWNER/$REPO.git"
fi

git -C "$SITE" config user.email "fabianorondonia@gmail.com"
git -C "$SITE" config user.name "Fabiano Roberto"

git -C "$SITE" add -A
git -C "$SITE" diff --cached --quiet && echo "ℹ️  Nada novo para commitar." || \
  git -C "$SITE" commit -m "Atualização — link Operadora + senha + link Maps hotéis"

echo "▶ Push..."
git -C "$SITE" push origin main && echo "✅ Publicado!" || echo "❌ Erro no push"

read -p "Pressione Enter para fechar..."
