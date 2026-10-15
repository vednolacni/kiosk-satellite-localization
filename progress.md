# Napredek slovenskega prevoda (sl)

## Faza 0: priprava (končano 2026-10-12)
- Fork: vednolacni/kiosk-satellite-localization, polna zgodovina (unshallow), remote `upstream` = jxlarrea/kiosk-satellite-localization.
- `main` hitro previt na upstream/main `9b48a06` in pushan v fork.
- Veja `sl` ustvarjena iz `main` (še ni pushana).
- Upstream: `translations/sl/` ne obstaja; ni issueja ali PR-ja za slovenščino (preverjeno na spletnem vmesniku GitHub: 3 zaprti issueji, 10 zaprtih PR-jev, iskanje »sloven« 0 zadetkov).
- Katalog: 197 datotek `source/*_en.arb` (ne 196), 3865 sporočil, revizija `28cb2bf843bd4b25fb6a3af1f7f60cffb6a5e25e`.

## Faza 1: pravila in glosar (potrjeno 2026-10-15)
- Prebrano: README.md, docs/TRANSLATING.md, docs/CONTRIBUTOR-RULES.md, docs/PR-ACCEPTANCE.md, docs/CONTRIBUTOR-AGREEMENT.md (razdelek 5), .github/pull_request_template.md, tools/catalog.py.
- Glosar: `glossary.md` (v1; uporabnik je naročil nadaljevanje s fazo 2, odločitve D1 do D16 veljajo kot predlagane).
- Osnutek issueja: `issue.md`.
- Git identiteta (lokalno v repozitoriju): vednolacni <123391433+vednolacni@users.noreply.github.com>.
- Zapiski so od 2026-10-15 na ločeni veji `sl-notes` v forku (worktree `/home/user/sl-notes`).

## Faza 2: prevod
- 2026-10-15: `main` in `sl` usklajena z upstream/main `ed3d5e0`; katalog: 198 datotek, 3951 sporočil, revizija `26898f4d573212a790b4709c2825622fa0230c5a`.
- Načrt serij: `batches.txt`; orodja: `tools/extract.py`, `tools/build.py`, `tools/check.py`; zastavice: `flags.tsv`.

| Serija | Datoteke | Commit | Validate | Opombe |
|---|---|---|---|---|
| B01 | 15 datotek, 230 sporočil (about_identity do drawer_updates) | glej `git log sl` | OK, check.py 0 težav | »Phrase« → »Besedilo« (sprememba glosarja) |
| B02 | 15 datotek, 347 sporočil (entity_picker do gesture_outcomes) | glej `git log sl` | OK, check.py 0 težav | 4 negotova mesta v floti (N) |
| B03 | 15 datotek, 231 sporočil (gesture_trigger_editor do plugins_actions) | `a0eb483` | OK, check.py 0 težav | zvočne oznake Hi-Res in kHz enake angleščini (O) |
| B04 | 14 datotek, 254 sporočil (plugins_general do remote_overview_controls) | `b31e358` | OK, check.py 0 težav | »asset« = sredstvo (N); »this release« v sestavi (N) |
| B05 | 14 datotek, 255 sporočil (remote_overview_health do settings_camera_streaming) | `4a68f59` | OK, check.py 0 težav | relativni časi in štetja preoblikovani (S) |
| B06 | 11 datotek, 278 sporočil (settings_camera_streams_errors do settings_device_permissions) | `eed489c` | OK, check.py 0 težav | tehnični identifikatorji v napakah pretokov ostanejo (baseUrl, serverId …) |
| B07 | 10 datotek, 270 sporočil (settings_device_remote_administration do settings_esphome_announcements) | `d52f499` | OK, check.py 0 težav | popravek GitHub sklona v plugins_repository_errors |
| B08 | 14 datotek, 223 sporočil (settings_esphome_bluetooth do settings_home_assistant_rotation) | `ea5c999` | OK, check.py 0 težav | ime HA nastavitve (D13) označeno |
| B09 | 12 datotek, 218 sporočil (settings_home_assistant_setup do settings_kiosk_permissions) | `ff29b9e` | OK, check.py 0 težav | pot v HA (D13) označena |
| B10 | 11 datotek, 171 sporočil (settings_lockdown_general do settings_media_player_sendspin) | `9a50012` | OK, check.py 0 težav | pot v vmesniku Music Assistant prevedena (O) |
| B11 | 12 datotek, 280 sporočil (settings_media_player_sonos do settings_screensaver_face_preview) | `41a3cd4` | OK, check.py 0 težav | ime Android nastavitve in »luč zaslona« označena |
| B12 | 12 datotek, 285 sporočil (settings_screensaver_general do settings_screensaver_media_home_assistant) | `3502541` | OK, check.py 0 težav | oblika datuma LLLL-MM-DD (N) |
| B13 | 13 datotek, 277 sporočil (settings_screensaver_media_local do settings_search_extras) | `724fedb` | OK, check.py 0 težav | pot v aplikaciji in »Občuti se kot« označena |
| B14 | 10 datotek, 302 sporočil (settings_voice_satellite_appearance do settings_voice_satellite_tester) | `e72436c` | OK, check.py 0 težav | pot v HA (D13) in stran »Home Assistant Setup« označeni |
| B15 | 10 datotek, 214 sporočil (settings_voice_satellite_timers do setup_permissions) | `d229103` | OK, check.py 0 težav | pot v HA za dolgotrajne žetone (D13) označena |
