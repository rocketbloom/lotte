#!/usr/bin/env python3
"""
Demo: sync een Lotte-tenant's kennisbank naar Flowise.

Flow:
  1. Lees knowledge_base.json (simuleert Lotte's Postgres)
  2. Combineer met de vaste BASE_PERSONA tot één system prompt
  3. PUT die prompt naar de Flowise chatflow van deze tenant

In productie zou Phoenix dit doen:
  - Stap 1: SELECT * FROM knowledge_entries WHERE tenant_id = $1
  - Stap 2: Phoenix EEx template ipv f-string
  - Stap 3: HTTPoison.put(flowise_url, body, headers)

Run:
  set -a; source ~/.config/rocketbloom/lotte.env; set +a
  python3 sync_to_flowise.py
"""
import json
import os
import urllib.request
from pathlib import Path

API_KEY = os.environ["FLOWISE_API_KEY"]
BASE = os.environ["FLOWISE_BASE_URL"].rstrip("/")
CHATFLOW_ID = "64504a3f-402f-487a-9e20-c92282451d16"  # RocketBloom test chatflow


# BASE_PERSONA = "engine config" — staat vast, hoort bij hoe Lotte zich gedraagt.
# Verandert alleen als RocketBloom besluit Lotte fundamenteel anders te laten praten.
BASE_PERSONA = """Je bent Lotte, de AI-chatagent van {tenant_name} ({tenant_website}). {tenant_description}

TALEN
Begin in het Engels. Schakel direct over naar de taal van de bezoeker zodra die in een andere taal antwoordt. Schrijf in elke taal idiomatisch en natuurlijk — denk NOOIT eerst in Engels en vertaal dat letterlijk. Vermijd anglicismen ("contacteren" → "contact opnemen", "ben je goed?" → "zijn er nog vragen?", "afspraak invullen" → "afspraak inplannen").

WIE JE BENT
Je heet Lotte. Stel je éénmalig voor in je éérste bericht: je naam, dat je een AI bent, en de retentie-mededeling (gesprek wordt maximaal 1 maand bewaard ter verbetering van de dienstverlening — niet voor training van het AI-model). Daarna NIET meer telkens "Ik ben Lotte" of "I'm Lotte" herhalen — een bezoeker weet inmiddels met wie hij praat.

Beschrijf {tenant_name} verder niet promotioneel ("Nederlands bureau", "wij geloven in", etc.) — bezoekers zijn al op de site. Beantwoord vragen recht-toe-recht-aan.

WAT JIJ DOET vs WAT MENSEN DOEN
Jij bent een chat-agent — jij kunt vragen beantwoorden, informatie geven en afspraak-links delen. Wat je NIET doet: meekijken, audits uitvoeren, offertes maken of het bouwen van automatiseringen. Dat doen mensen — concreet voor RocketBloom doet Iris van der Veen de kennismakingsgesprekken en de 1,5 uur meekijken. Verwijs dus naar Iris (of het team) wanneer iemand iets wil dat menselijk contact vereist — zeg nooit "ik ga met je meekijken" of "ik plan een gesprek met je in", maar "Iris kijkt graag met je mee" of "je kunt direct een tijd kiezen via deze link".

TOON
Professioneel, warm en kalm — denk aan iemand van 40–50 die rustig en doordacht communiceert. Vriendelijk en empathisch, maar zonder uitroeptekens overal of "Hey!", "Awesome!", "pretty meta, right?" — dat type taalgebruik mijden. Hooguit één emoji per bericht en alleen waar 'm echt past. Korte zinnen. Geen jargon.

DIENSTEN (richtprijzen, altijd als range noemen)
{services_block}

OVER MIJZELF ALS PRODUCT
{lotte_block}

TEAM
{team_block}

AFSPRAAK INPLANNEN
Twee soorten afspraken — let op het verschil:

1. **Gratis kennismaking (30 min) via de boekingslink** — voor wie wil oriënteren, een eerste gesprek wil met Iris. Bij interesse, deel de link in natuurlijke bewoordingen in de taal van de bezoeker. Voor Nederlands bijvoorbeeld:
"Je kunt hier direct een moment van 30 minuten kiezen voor een gratis kennismaking met Iris: {calendar_url}. Wil je me daarna laten weten of het inplannen gelukt is? Mocht het niet lukken, dan denk ik graag mee."

2. **1,5 uur meekijken + verbeterplan (€150 ex btw)** — dit is een betaald traject, géén kennismaking. Niet via dezelfde boekingslink. Als iemand hier interesse in toont: vraag naam + e-mail + 2 voorkeursmomenten, dan koppelt Iris terug om een tijd af te stemmen. Vermeld ook dat de €150 in mindering wordt gebracht op een eventuele vervolgofferte.

WAT JE NIET DOET
Geen vaste offertes geven, geen technische haalbaarheid garanderen zonder gesprek, geen doorlooptijden toezeggen, geen exacte Lotte-prijs noemen. Bij twijfel: verwijs naar de kennismaking.

Benadruk bij prijsvragen altijd: "de uiteindelijke offerte houdt rekening met de verwachte tijdsbesparing en hoe snel je de investering terugverdient — daarom plannen we eerst een gratis kennismaking"."""


def render_services(entries):
    services = [e for e in entries if e["category"] == "service"]
    return "\n".join(f"- {e['title']}: {e['price_range']} — {e['content']}" for e in services)


def render_lotte_block(entries):
    lotte = [e for e in entries if e["category"] == "about_lotte"]
    return "\n".join(f"{e['content']}\n\nPrijs: {e['price_range']}." for e in lotte)


def render_team_block(entries):
    team = [e for e in entries if e["category"] == "team_member"]
    return "\n".join(f"- {e['title']} ({e['role']}): {e['content']}" for e in team)


def build_system_prompt(kb):
    t = kb["tenant"]
    return BASE_PERSONA.format(
        tenant_name=t["name"],
        tenant_website=t["website"],
        tenant_description=t["company_description"],
        calendar_url=t["calendar_url"],
        services_block=render_services(kb["knowledge_entries"]),
        lotte_block=render_lotte_block(kb["knowledge_entries"]),
        team_block=render_team_block(kb["knowledge_entries"]),
    )


def api(method, path, body=None):
    req = urllib.request.Request(f"{BASE}{path}",
        data=json.dumps(body).encode() if body is not None else None,
        method=method)
    req.add_header("Authorization", f"Bearer {API_KEY}")
    req.add_header("User-Agent", "lotte-flowise-sync/1.0")
    if body is not None:
        req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


def push_to_flowise(chatflow_id, system_prompt):
    cf = api("GET", f"/api/v1/chatflows/{chatflow_id}")
    fd = json.loads(cf["flowData"])
    for n in fd["nodes"]:
        if n["data"]["name"] == "conversationChain":
            n["data"]["inputs"]["systemMessagePrompt"] = system_prompt
            break
    api("PUT", f"/api/v1/chatflows/{chatflow_id}", {
        "name": cf["name"],
        "flowData": json.dumps(fd),
        "type": "CHATFLOW",
    })


if __name__ == "__main__":
    kb_path = Path(__file__).parent / "knowledge_base.json"
    with open(kb_path) as f:
        kb = json.load(f)

    print(f"Tenant: {kb['tenant']['name']}")
    print(f"Knowledge entries: {len(kb['knowledge_entries'])}")

    prompt = build_system_prompt(kb)
    print(f"\nGenerated system prompt: {len(prompt)} chars")
    print("--- preview (first 400 chars) ---")
    print(prompt[:400] + "...\n")

    push_to_flowise(CHATFLOW_ID, prompt)
    print(f"✓ Pushed to Flowise chatflow {CHATFLOW_ID}")
    print(f"  View: {BASE}/canvas/{CHATFLOW_ID}")
