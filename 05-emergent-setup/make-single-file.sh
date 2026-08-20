#!/usr/bin/env bash
# Concatenate the whole bundle into one markdown file.
#
# Why: Emergent accepts PDF uploads reliably and loose markdown files less so.
# One combined file converts to a single PDF you can drop into the chat.
#
# Usage, from inside emergent-build/:
#     bash 05-emergent-setup/make-single-file.sh
#
# Produces:  emergent-build-combined.md
#
# To turn it into a PDF, either open it in any markdown editor and print to PDF,
# or if you have pandoc:
#     pandoc emergent-build-combined.md -o emergent-build-combined.pdf
#
# The raw research in 99-research-raw/ is deliberately EXCLUDED — it is ~330KB
# of engineer-facing detail with file:line citations, which is noise for an AI
# builder and would blow up the PDF. Upload those separately only if asked.

set -euo pipefail

cd "$(dirname "$0")/.."
OUT="emergent-build-combined.md"

# Order matters: framing, then look, then data, then screens, then rules.
FILES=(
  "README.md"
  "01-product/01-what-this-is.md"
  "03-design-system/01-design-brief.md"
  "03-design-system/03-component-styling.md"
  "04-data-contracts/02-data-model.md"
  "04-data-contracts/01-api-reference.md"
  "01-product/02-sales-cockpit-spec.md"
  "01-product/03-component-catalogue.md"
  "01-product/04-user-flows.md"
  "02-pricing-engine/01-pricing-primer-plain-english.md"
  "02-pricing-engine/02-pricing-rules-and-math.md"
  "02-pricing-engine/03-config-schema-and-defaults.md"
  "02-pricing-engine/04-worked-examples-golden.md"
  "05-emergent-setup/04-guardrails-do-not-change.md"
  "00-KICKOFF-PROMPT.md"
)

{
  echo "# ChainIT Sales Cockpit and Pricing Engine — complete rebuild context"
  echo
  echo "Combined from the emergent-build bundle. Each section below was a"
  echo "separate file; the divider marks where one ends and the next begins."
  echo
  echo "The design tokens are in a separate file, \`03-design-system/02-tokens.css\`."
  echo "Upload that one as CSS, not as part of this document."
  echo
} > "$OUT"

for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    {
      echo
      echo "---"
      echo
      echo "<!-- source: $f -->"
      echo
      cat "$f"
      echo
    } >> "$OUT"
  else
    echo "warning: $f not found, skipping" >&2
  fi
done

echo "wrote $OUT ($(wc -l < "$OUT") lines, $(du -h "$OUT" | cut -f1))"
