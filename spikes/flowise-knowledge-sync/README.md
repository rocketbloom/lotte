# Spike: Flowise ← Lotte kennisbank sync

**Doel:** demonstreren hoe Lotte (Phoenix) kennis naar een Flowise chatflow stuurt zodat de chat-agent de juiste antwoorden geeft per tenant.

**Voor wie:** Melle, om mee te denken over de Phoenix-implementatie.

## Het patroon

```
┌─────────────────────────┐         ┌──────────────────────────┐
│  Lotte (Phoenix)        │         │  Flowise                 │
│                         │         │  (cloud nu, later self-  │
│  Klant past FAQ aan in  │  PUT    │  hosted)                 │
│  dashboard              │  ──→    │                          │
│           ↓             │         │  1 chatflow per tenant   │
│  Knowledge_entries      │         │  System prompt = base    │
│  table (per tenant)     │         │  persona + tenant's      │
│           ↓             │         │  kennis                  │
│  Sync logic combineert  │         │                          │
│  base persona +         │         │  Bezoeker chat → LLM-    │
│  kennis tot system      │         │  call met die prompt     │
│  prompt                 │         │                          │
└─────────────────────────┘         └──────────────────────────┘
```

**Splitsing:**
- **Vast (in Phoenix code):** persona, toon, taalregels, "wat doe je niet" — hoort bij hoe Lotte zich gedraagt
- **Variabel (in DB):** services, prijzen, FAQ, bedrijfsspecifieke info, calendar-link — per tenant anders

## Wat doet deze proefopstelling

1. `knowledge_base.json` — simuleert de toekomstige `knowledge_entries` tabel in Lotte's Postgres
2. `sync_to_flowise.py` — leest die JSON, rendert er een system prompt van, pusht naar Flowise via de REST API
3. `phoenix_equivalent.ex` — schets van hoe ditzelfde in Phoenix/Elixir eruit zou zien

## Uitvoeren (lokaal)

```bash
cd lotte/spikes/flowise-knowledge-sync
set -a; source ~/.config/rocketbloom/lotte.env; set +a
python3 sync_to_flowise.py
```

Output toont:
- Welke tenant + hoeveel entries
- Lengte + preview van de gegenereerde prompt
- Bevestiging dat 't naar Flowise gepusht is

Test daarna in Flowise of de chat de juiste info pakt:
- `https://cloud.flowiseai.com/canvas/64504a3f-402f-487a-9e20-c92282451d16`

## Verwacht datamodel in Lotte (voorstel)

```elixir
schema "knowledge_entry" do
  field :category, :string      # "service", "about_lotte", "faq", "general"
  field :title, :string
  field :content, :text
  field :price_range, :string   # optioneel, alleen voor services
  field :language, :string      # "nl", "en", "all" — voor meertalige FAQ later

  belongs_to :tenant, Lotte.Tenants.TenantModel, type: :binary_id
  timestamps()
end
```

Op `tenant`:
```elixir
field :flowise_chatflow_id, :string   # gekoppelde Flowise chatflow per tenant
field :calendar_url, :string          # boekingslink per tenant
field :default_language, :string
```

## Wanneer pushen?

Drie opties:

1. **Direct bij iedere knowledge_entry create/update/delete** — eenvoudig, real-time, maar veel API-calls bij bulk-acties
2. **Debounced via background job** (Oban) — verzamel wijzigingen, push na X seconden inactiviteit. Productie-vriendelijk
3. **"Publish" knop in dashboard** — klant beslist zelf wanneer wijzigingen live gaan. Transparant maar handmatig

Suggestie: optie 2 voor productie, optie 1 voor MVP.

## Wat dit NIET doet (en bewust niet)

- Geen vector store / RAG — dat is een latere optimalisatie als kennisbanken groot worden
- Geen tenant-provisioning (nieuwe klant → automatisch nieuwe Flowise chatflow) — dat is een aparte spike
- Geen sync terug (conversations van Flowise → Lotte) — andere richting, ander stuk werk

## Open keuzes voor Melle en Iris

1. **Wanneer pushen?** (zie hierboven, opties 1/2/3)
2. **Persona configureerbaar maken in dashboard?** Sommige tenants willen formeler/informeler. Nu is persona hardcoded in de Phoenix-code.
3. **Hoe meertaligheid?** Per knowledge entry een language-veld? Of laat je het LLM zelf vertalen?
4. **Conversation history terughalen voor dashboard:** via Flowise's `/api/v1/chatmessage` endpoint pollen, of webhook van Flowise op nieuwe berichten?
