**Title:** Slovenian (sl) localization

**Body:**

Hello! I would like to add Slovenian to Kiosk Satellite.

- **Language tag:** `sl` (standard Slovenian, no regional variant). Native language name: Slovenščina.
- **Scope:** the complete current English catalog (197 files, 3,865 messages at source revision `28cb2bf`), submitted in one PR from my fork. I will sync with `main` before requesting review.
- **Translator:** I am a native Slovenian speaker.
- **AI assistance:** I am preparing drafts with Claude (Anthropic) through Claude Code, working from the English source and a Slovenian glossary that I approved. I review every message myself and edit where needed. Optional training was turned off before any project material was used. The PR description will include the full disclosure (product, account type, terms link and scope).
- **Rendering:** Slovenian uses the Latin script with č, š and ž (plus ć and đ in some names). I don't expect font problems, but I can't test on a device yet, so the PR will say "not yet tested".

**Question about plural forms**

Slovenian has four number forms: singular, dual, and two plural forms (1 pogled, 2 pogleda, 3 pogledi, 5 pogledov). The catalog supports only named placeholders, and `tools/catalog.py` rejects ICU plural expressions, so a message like `{count} views` cannot be correct for every number in Slovenian as a plain sentence.

About 85 messages depend on a number this way (counts, "N minutes ago", "Retrying in Ns" and similar). My plan is to rephrase them so they read correctly for any number, without changing their meaning:

- a label followed by the number: `{count} views` becomes "Pogledi: {count}" ("Views: {count}");
- abbreviated units, which don't inflect: "pred {count} min" ("{count} min ago"), "Nov poskus čez {seconds} s" ("Retrying in {seconds} s");
- separate English messages for one item (for example `1 view`) are translated normally.

Is this approach acceptable to you? If plural support is planned soon and you would rather have those messages wait for it, I'm happy to adjust. I'll list every rephrased message in the PR so it is easy to review.

Thank you for making the app translatable!
