# Glosar EN → SL za Kiosk Satellite (osnutek v1 za potrditev)

Vir: `source/*_en.arb` (197 datotek, 3865 sporočil, revizija `28cb2bf843bd4b25fb6a3af1f7f60cffb6a5e25e`), vključno s `context`, `description` in `x-notes`.
Oznaka **[D#]** pomeni odločitev, ki jo potrdite ali spremenite (seznam v razdelku 1).
Oznaka *Android* ali *HA* pomeni izraz, ki ga uporabniki poznajo iz slovenskega Androida ali Home Assistanta.

---

## 0. Splošna slogovna pravila

1. **Gumbi, ukazi, oznake stikal in menijev:** velelnik ednine ali samostalnik: Shrani, Prekliči, Omogoči kamero, V redu.
2. **Navodila, vprašanja, napake, naslovljene na uporabnika:** vikanje: Izberite …, Vnesite …, Ali želite …?, Poskusite znova.
3. **Opisi pod nastavitvami, ki povedo, kaj nastavitev naredi:** 3. oseba sedanjika: »Skrije glavo in stransko vrstico …«, »Prikaže …«. Če angleščina uporabnika neposredno naslavlja (»Pick a …«), vikanje.
4. **Velika začetnica** samo na začetku in pri lastnih imenih, tudi kjer ima angleščina Title Case (»Nastavitve zaslona«, »Zdaj se predvaja«).
5. **Stanja:** kratka oblika srednjega spola ali povedek: Povezano, Ustavljeno, Ni na voljo, Deluje.
6. **Fragmenti v `android_service`:** male začetnice, brez končnega ločila; aplikacija jih združi z vejicami in doda veliko začetnico in piko (»posluša aktivacijsko besedo«).
7. **Placeholderji** ostanejo v imenovalniku, sklon nosi samostalnik pred njimi: »z napravo {name}«, »na kiosku {name}«, »profil {name}«, »različica {version}«. Brez preteklika, ki bi se moral spolsko ujemati s placeholderjem: »Zagnano: {value}« namesto »{value} se je zagnal«.
8. **Števila:** ICU množina ni podprta; glej razdelek 16. Vsako tako sporočilo dobi zastavico »preoblikovano zaradi števila«.
9. **Ločila:** glej razdelek 17. Pomišljaja U+2013 in U+2014 sta prepovedana.
10. **Kratko in naravno.** Opozoril ne oslabimo in pogojev ne izpustimo. Ne uvajamo besedila, ki ga v izvirniku ni.

---

## 1. Odločitve za potrditev

| # | Tema | Predlog | Alternativa | Utemeljitev |
|---|---|---|---|---|
| D1 | Sklanjanje imen izdelkov | **Ne sklanjamo.** Ime ostane v imenovalniku, sklon nosi občno ime pred njim: »v sistemu Home Assistant«, »s sistemom Home Assistant«, »aplikacija Kiosk Satellite«, »integracija Voice Satellite«, »strežnik Immich«. Kjer stavek dopušča imenovalnik, ime stoji samo: »Home Assistant ni dosegljiv.« | Sklanjamo s končnicami: »v Home Assistantu«, »Home Assistanta«. Bolj pogovorno, a ime se spremeni. | Ustaljena praksa slovenske lokalizacije (Microsoft, Android); ime ostane natanko tako, kot ga pravilo zahteva; skladno z vašim pravilom za placeholderje. |
| D2 | wake word | **aktivacijska beseda** (»Občutljivost aktivacijske besede«) | beseda za bujenje | Krajše v sestavljenkah (engine, sensitivity, detection, tester); ni zamenljivo z budilko (alarm) in z bujenjem zaslona (wake screen). |
| D3 | remote admin / Remote Administration | **oddaljeno skrbništvo**; admin password = **skrbniško geslo**; Remote management = **oddaljeno upravljanje** | oddaljena administracija | »Skrbnik/skrbništvo« uporablja Android (Skrbnik naprave) in Microsoft; Remote management je v katalogu ločeno stikalo, zato ločen izraz. |
| D4 | drawer, kiosk drawer, kiosk menu | **meni kioska** (vse tri) | stranski meni / predal | Katalog uporablja »drawer« in »kiosk menu« za isti meni (poteg z levega roba). »Predal« je dobeseden in uporabniku manj jasen. |
| D5 | Fleet: leader / follower | **vodja** / **sledilec** (Followers = Sledilci; Lead this fleet = Vodi to floto) | vodilni kiosk / podrejeni kiosk | Ohrani prispodobo izvirnika in deluje kot samostalnik v naslovih; »podrejeni« je daljše v statusih. |
| D6 | Hold mode / Lockdown Mode | **način zadržanja** (zadrži trenutni pogled) / **način zaklepa** (onemogoči dotike zaslona) | način mirovanja (zavajajoče: mirovanje = sleep) / popolni zaklep | Opis: Hold mode ustavi ohranjevalnik, menjavanje pogledov in vrnitev domov; Lockdown onemogoči interakcijo z zaslonom. |
| D7 | announcement / announce | **razglas / razglasiti** (»Razglas vsem«, »{name} razglaša«) | glasovno obvestilo | »Obvestilo« je že notification. »Razglas« je ustaljen za sporočilo prek zvočnikov in je kratek. |
| D8 | Intercom | **interkom** | domofon (to je vratna naprava), interfon | Funkcija je pogovor med kioski, ne vratni sistem. |
| D9 | media | **mediji / medijski** (»Glasnost medijev«, »Predvajalnik medijev«) | predstavnost (Android: »Glasnost predstavnosti«) | Home Assistant v slovenščini uporablja »Mediji«; »predstavnost« je formalna, uporabniki pa bolj poznajo »mediji«. |
| D10 | tablet | **tablica** | tablični računalnik | Kratko in splošno razumljivo; v navodilih se pojavi 29-krat. |
| D11 | Presledek pred %, enotami in … | **navaden presledek** (»10 %«, »5 s«, »Nalaganje …«) | nedeljivi presledek U+00A0 | Drugi jeziki v repozitoriju ga ne uporabljajo; navaden presledek je viden pri pregledu in ga validator zagotovo sprejme. |
| D12 | Imena funkcij sredi stavka | V narekovajih »…«, kadar bi bilo brez njih dvoumno: »Pokaži »Zdaj se predvaja««, sicer brez. | vedno brez narekovajev | Angleščino loči Title Case, ki ga v slovenščini nimamo. |
| D13 | Poti po menijih Home Assistanta v besedilu (npr. Settings → Devices & Services → Add Entry) | Prevedemo z ustaljenimi izrazi: »Nastavitve → Naprave in storitve → Voice Satellite → Dodaj vnos«; označimo za pregled | pustimo angleško | Uporabnik s slovenskim HA vidi slovenske menije. Gre za posamezne ustaljene izraze, ne za prepisane nize. |
| D14 | Android | Sklanjamo kot udomačeno ime: »različica Androida«, »v Androidu« | »sistem Android« | »Android« ni na seznamu imen, ki se ne prevajajo, in se v slovenščini splošno sklanja. |
| D15 | Realtime (stran in možnost »{provider} Realtime«) | Naslov strani: **Realni čas**; »{provider} Realtime« ostane (ime API-ja ponudnika) | vse pustimo »Realtime« | »OpenAI Realtime« je ime izdelka, naslov strani pa je opis funkcije. |
| D16 | pill (timer pills, speaker selection pill) | **značka** (»značke časovnikov«); kjer je element gumb: »gumb za izbiro zvočnika« | kapsula | »Pill« je zaobljen element. »Značka« je ustaljena za majhne oznake. |

---

## 2. Imena izdelkov in tehnični izrazi (ne prevajamo)

| Izvirnik | Raba v slovenskem besedilu (po D1) |
|---|---|
| Kiosk Satellite | »Kiosk Satellite« v imenovalniku; drugače »aplikacija Kiosk Satellite«, »storitev Kiosk Satellite« |
| Home Assistant, HA | »Home Assistant«; drugače »v sistemu Home Assistant«, »nadzorna plošča Home Assistant«; »HA« ostane |
| Voice Satellite | vedno »integracija Voice Satellite« ali samo ime v imenovalniku |
| ESPHome | »ESPHome«; »naprava ESPHome«, »strežnik ESPHome«, »entitete ESPHome« |
| Shizuku | »aplikacija Shizuku«, »dostop Shizuku« |
| Immich | »strežnik Immich«, »mediji Immich« |
| Sonos | »zvočniki Sonos«, »prostor Sonos« |
| Music Assistant | »strežnik Music Assistant«, »predvajalnik Music Assistant« |
| Sendspin | »predvajalnik Sendspin« |
| Go2RTC | »strežnik Go2RTC«, »pretok Go2RTC« |
| DLNA, RTSP, ONVIF, HACS, Assist | nespremenjeno; »cevovod Assist«, »repozitorij HACS« |
| ADB ukazi, entity ID-ji, URL-ji, JSON, imena datotek, paketi (`me.jxl.kiosk_satellite`) | nespremenjeno, znak za znakom |
| TLS, HTTPS, HTTP, PEM, SHA-256, EC, RSA, MCP, API, URL, URI, ZIP, APK, DEX, ELF, JAR, WebView, logcat, Wi-Fi, Bluetooth, GPS, QR, PIN, MAC, IP, IPv4, IPv6, mDNS, RAM, WHEP, WebRTC, MSE, HLS, H.265, FLAC, Opus, PCM, TFLite, ONNX, openWakeWord, vsWakeWord | nespremenjeno; »naslov IP«, »naslov MAC«, »koda QR«, »ključ API«, »vrata API« |
| GitHub, OpenAI, xAI, Gemini, Google, Apple, Samsung, Amazon, Xiaomi, Qingping, BTHome, Eddystone, Tile, August/Yale, Windows, Nest | nespremenjeno |
| Android | sklanjamo (D14) |
| CPU | »procesor« v daljših oznakah (»Obremenjenost procesorja«); »CPE« v kratki ploščici |

---

## 3. Skupna dejanja (gumbi)

| EN | SL | Opomba |
|---|---|---|
| Import | Uvozi | |
| Back | Nazaj | |
| Next | Naprej | |
| Finish | Dokončaj | |
| Working… | Obdelava … | |
| Settings | Nastavitve | *Android, HA* |
| Cancel | Prekliči | |
| OK | V redu | |
| Grant | Odobri | dovoljenje |
| Enable / Disable | Omogoči / Onemogoči | |
| Turn on / Turn off | Vklopi / Izklopi | |
| Refresh | Osveži | |
| Reload | Znova naloži | |
| Restart | Znova zaženi | |
| Test | Preizkusi | |
| Install / Uninstall | Namesti / Odmesti | *Android* (»Odmesti«) |
| Save | Shrani | |
| Retry | Poskusi znova | gumb |
| Try again | Poskusi znova (gumb) / Poskusite znova (navodilo) | |
| Copy | Kopiraj | |
| Add | Dodaj | |
| Remove | Odstrani | |
| Delete | Izbriši | |
| Close | Zapri | |
| Clear | Počisti | |
| Browse | Prebrskaj | |
| Set | Nastavi | |
| Edit | Uredi | |
| Choose / Pick / Select | Izberi | |
| Select all | Izberi vse | |
| Move up / Move down | Premakni gor / Premakni dol | |
| Rename | Preimenuj | |
| Duplicate | Podvoji | |
| Download / Upload | Prenesi / Naloži | |
| Share | Deli | |
| Open | Odpri | |
| Exit | Izhod | |
| Start / Stop | Zaženi / Ustavi | |
| Confirm | Potrdi | |
| Replace | Zamenjaj | |
| Renew | Obnovi | potrdilo |
| Validate | Preveri | |
| Accept / Decline | Sprejmi / Zavrni | |
| Dismiss | Opusti (obvestilo, opozorilo) / Zapri (ohranjevalnik, pogled kamer, Zdaj se predvaja) | *Android* »Opusti« |
| Postpone | Odloži | |
| Snooze | Dremež | *Android, ura* |
| Undo | Razveljavi | |
| Done | Končano | |
| Apply | Uporabi | |
| Configure | Konfiguriraj | |
| Help | Pomoč | |
| Learn more | Več o tem | |
| Log in / Log out | Prijava / Odjava | |
| Loading… | Nalaganje … | |
| Checking… | Preverjanje … | |
| Searching… | Iskanje … | |
| Search (polje) | Iskanje | |
| Hour / Minute | Ura / Minuta | |
| Up / Down | Gor / Dol | |
| Previous month / Next month | Prejšnji mesec / Naslednji mesec | |

## 4. Stanja

| EN | SL |
|---|---|
| On / Off (stanje) | Vklopljeno / Izklopljeno |
| on / off (mala začetnica v sestavi) | vklopljeno / izklopljeno |
| Enabled / Disabled | Omogočeno / Onemogočeno |
| Connected / Not connected | Povezano / Ni povezano |
| Running / Not running | Deluje / Ne deluje |
| Stopped | Ustavljeno |
| Idle | Nedejavno |
| Paused | Začasno ustavljeno |
| Available / Unavailable | Na voljo / Ni na voljo |
| Unknown | Neznano |
| Online / Offline | Povezano / Brez povezave |
| Unreachable | Nedosegljivo |
| Missing | Manjka |
| Granted / Not granted | Odobreno / Ni odobreno |
| Not set | Ni nastavljeno |
| Ready | Pripravljeno |
| Busy | Zasedeno |
| Failed | Ni uspelo |
| X failed | »X ni uspel/uspela/uspelo« po spolu samostalnika: Posodobitev ni uspela, Prenos ni uspel |
| Could not X | X ni bilo mogoče (»Datoteke ni bilo mogoče prebrati.«) ali »Ni mogoče X« |
| Up to date | Posodobljeno |
| Validated / Not validated | Preverjeno / Ni preverjeno |
| Default | Privzeto |
| Auto / Automatic | Samodejno |
| None | Brez (možnost) / Nič (količina) |
| Never / Always | Nikoli / Vedno |
| Custom | Po meri |
| (optional) | (neobvezno) |
| Required | Obvezno |
| just now | pravkar |

---

## 5. Home Assistant

| EN | SL | Opomba |
|---|---|---|
| dashboard | nadzorna plošča | *HA*, vaše pravilo |
| Whole dashboard | Celotna nadzorna plošča | |
| Default dashboard | Privzeta nadzorna plošča | |
| view / subview | pogled / podpogled | *HA* |
| entity | entiteta | *HA* |
| area | območje | *HA* |
| device | naprava | |
| integration | integracija | *HA* |
| automation | avtomatizacija | *HA* |
| script | skripta | *HA* |
| service (HA) | storitev | *HA* |
| action (HA, gesture) | dejanje | *HA* |
| event / event type / event data | dogodek / vrsta dogodka / podatki dogodka | |
| service data | podatki storitve | |
| domain | domena | |
| trigger | sprožilec | *HA* |
| state | stanje | |
| sensor / binary sensor / text sensor | senzor / binarni senzor / besedilni senzor | |
| switch / button / number / select / light / update / text | stikalo / gumb / število / izbira / luč / posodobitev / besedilo | vrste entitet |
| weather entity | vremenska entiteta | |
| base URL | osnovni URL | |
| long-lived access token | dolgotrajni dostopni žeton | |
| token | žeton | |
| header / sidebar | glava / stranska vrstica | |
| HA kiosk mode | kioskni način HA | skrije glavo in stransko vrstico HA |
| Assist pipeline | cevovod Assist | |
| satellite / satellite entity | satelit / entiteta satelita | |
| Devices & Services → Add Entry | Naprave in storitve → Dodaj vnos | [D13] |
| Profile → Security | Profil → Varnost | [D13] |
| Custom Pages | Strani po meri | |
| External pages | Zunanje strani | |
| Dashboard View Rotation | Menjavanje pogledov nadzorne plošče | »rotation« ni vrtenje zaslona |
| Seconds per view | Sekunde na pogled | |
| Fade between views | Prelivanje med pogledi | |
| Return to home dashboard view | Vrnitev na domači pogled nadzorne plošče | |
| Hold mode | način zadržanja | [D6] |
| Optimizations | Optimizacije | |
| Watched entities | Spremljane entitete | |
| Filter dashboard updates | Filtriraj posodobitve nadzorne plošče | |
| carousel | vrtiljak | |
| haptics | haptični odziv | |
| Vibration strength | Moč vibriranja | |
| tap sounds | zvoki dotika | |
| Secure context proxy | posrednik za varen kontekst | |
| theme / Dark / Light / System | tema / Temna / Svetla / Sistemska | |
| Log in automatically | Samodejna prijava | |
| Validate connection | Preveri povezavo | |
| media browser | brskalnik medijev | |
| Home Assistant Setup | Nastavitev Home Assistant | stran v nastavitvah |

## 6. Naprava, Android in kioskni način

| EN | SL | Opomba |
|---|---|---|
| kiosk | kiosk (kioska, kiosku, kioski) | |
| Kiosk Mode | kioskni način | |
| exit gesture | kretnja za izhod | |
| Kiosk mode PIN | PIN za kioskni način | |
| Lockdown Mode | način zaklepa | [D6] |
| Screen is locked | Zaslon je zaklenjen | |
| lockdown shield | zaščita zaklepa | |
| Blackout screen | Črn zaslon | |
| Allowed Actions | Dovoljena dejanja | |
| drawer / kiosk drawer / kiosk menu | meni kioska | [D4] |
| status bar | vrstica stanja | *Android* |
| notification shade | podokno z obvestili | *Android* |
| recents | nedavne aplikacije | *Android* |
| home button / power button / volume buttons | gumb za začetni zaslon / gumb za vklop / gumba za glasnost | |
| context menus | kontekstni meniji | |
| pull to refresh | Povleci za osvežitev | |
| pinch to zoom | Povečava z razmikom prstov | |
| Start on boot | Zaženi ob vklopu naprave | |
| Home Launcher | Domači zaganjalnik | ime funkcije |
| App Launcher | Zaganjalnik aplikacij | ime funkcije |
| home screen | začetni zaslon | *Android* |
| screen pinning | pripenjanje zaslona | *Android* |
| device owner / ownership | lastnik naprave / lastništvo naprave | |
| Accessibility | Dostopnost | *Android* |
| Permissions Manager | Upravitelj dovoljenj | |
| Required system permissions | Zahtevana sistemska dovoljenja | |
| permission | dovoljenje | *Android*, vaše pravilo |
| grant screen | zaslon za odobritev | |
| Display over other apps | Prikaz čez druge aplikacije | *Android* |
| Modify system settings | Spreminjanje sistemskih nastavitev | *Android* |
| Usage access | Dostop do podatkov o uporabi | *Android* |
| Notification access | Dostop do obvestil | *Android* |
| All files access | Dostop do vseh datotek | *Android* |
| Unrestricted battery | Neomejena poraba baterije | *Android* |
| Nearby devices | Naprave v bližini | *Android* |
| Location | Lokacija | *Android* |
| Notifications | Obvestila | *Android* |
| Device admin | Skrbnik naprave | *Android* |
| System UI guard | Zaščita sistemskega vmesnika | |
| Kiosk protections | Zaščite kioska | |
| Kiosk Satellite Service | Storitev Kiosk Satellite | |
| foreground service (types) | (vrste) storitve v ospredju | *Android* |
| wake lock / Wi-Fi lock | zaklep bujenja / zaklep Wi-Fi | |
| Device name / mDNS name | Ime naprave / Ime mDNS | |
| (Legacy) renderer | (starejši) upodabljalnik | grafika, ne DLNA |
| user agent | uporabniški agent | |
| uptime | čas delovanja | |
| storage / internal storage | shramba / notranja shramba | |
| Battery level / plugged / low | Raven baterije / priključeno / nizka | |
| Hardware | Strojna oprema | |
| Device model / Android version / Android build | Model naprave / Različica Androida / Gradnja Androida | |
| tablet | tablica | [D10] |
| root access / shell access | korenski dostop / dostop do lupine | |
| command | ukaz | |
| guide / Setup guide | vodnik / Vodnik za nastavitev | |
| Optional update helper | Neobvezni pomočnik za posodobitve | |
| app | aplikacija | |
| Exit Application | Zapri aplikacijo | |
| Clear web cache | Počisti spletni predpomnilnik | |
| Follow Android | Kot v Androidu | tema |
| first-time setup / wizard | začetna nastavitev / čarovnik | |
| Welcome | Dobrodošli | |
| Connect (korak) | Povezava | |
| Recommended settings | Priporočene nastavitve | |
| backup / Restore backup | varnostna kopija / Obnovi varnostno kopijo | |
| Scan the QR code | Preberite kodo QR | |
| flashlight | svetilka | *Android* |

## 7. Oddaljeno skrbništvo, TLS, flota

| EN | SL | Opomba |
|---|---|---|
| Remote Administration / remote admin | oddaljeno skrbništvo | [D3] |
| Remote management | oddaljeno upravljanje | [D3] |
| Admin password | skrbniško geslo | |
| Admin address | naslov za skrbništvo | |
| Server port / port | vrata strežnika / vrata | |
| Overview | Pregled | |
| Quick controls | Hitri kontrolniki | |
| Needs attention | Zahteva pozornost | |
| Find other kiosks | Najdi druge kioske | |
| Switch kiosk | Zamenjaj kiosk | |
| Reload page | Znova naloži stran | |
| Fleet Management / fleet | Upravljanje flote / flota | |
| leader / follower | vodja / sledilec | [D5] |
| Lead this fleet | Vodi to floto | |
| profile | profil | |
| sync / synced | sinhronizacija, sinhroniziraj / sinhronizirano | |
| credentials | poverilnice | |
| Excluded settings | Izključene nastavitve | |
| categories | kategorije | |
| invitation / invite / join | povabilo / povabi / pridruži se | |
| push (settings) | pošiljanje (nastavitev) | |
| TLS certificate / certificate | potrdilo TLS / potrdilo | *Android* (»Varnostna potrdila«) |
| Self-signed / Imported | Samopodpisano / Uvoženo | |
| Expires | Poteče | |
| fingerprint | prstni odtis | |
| private key / public certificate / certificate chain | zasebni ključ / javno potrdilo / veriga potrdil | |
| encryption | šifriranje | |
| connection protocol | protokol povezave | |

## 8. Zaslon in zvok

| EN | SL | Opomba |
|---|---|---|
| Screen & Audio | Zaslon in zvok | |
| Display cutout | Izrez zaslona | *Android* |
| Use the cutout area / Avoid the cutout / Short edges only | Uporabi območje izreza / Izogni se izrezu / Samo krajša robova | |
| Screen orientation | Usmerjenost zaslona | |
| Landscape / Reverse landscape / Portrait / Reverse portrait | Ležeče / Obrnjeno ležeče / Pokončno / Obrnjeno pokončno | |
| Keep screen on | Ohrani zaslon vklopljen | |
| brightness | svetlost | *Android*, vaše pravilo |
| Default brightness | Privzeta svetlost | |
| Adaptive brightness | Prilagodljiva svetlost | *Android* |
| ambient light / light sensor / light level | svetloba okolice / senzor svetlobe / raven svetlobe | |
| Dark room / Bright room | Temen prostor / Svetel prostor | |
| Brightness curve | Krivulja svetlosti | |
| Always-on display | Vedno vklopljen zaslon | |
| volume | glasnost | vaše pravilo |
| Master volume | Glavna glasnost | |
| Media volume | Glasnost medijev | [D9] |
| Assistant volume | Glasnost pomočnika | |
| Audio Devices | Zvočne naprave | |
| microphone / speaker | mikrofon / zvočnik | |
| Capture mode / Capture format | Način zajemanja / Oblika zajemanja | |
| Echo cancellation | Odpravljanje odmeva | |
| Noise suppression | Dušenje šuma | |
| Microphone gain | Ojačanje mikrofona | |
| Microphone channel | Kanal mikrofona | |
| Downmix | Združitev kanalov | |
| Raw microphone | Neobdelan zvok mikrofona | |
| Voice communication | Glasovna komunikacija | |
| Microphone level | Raven mikrofona | |

## 9. Ohranjevalnik zaslona

| EN | SL | Opomba |
|---|---|---|
| screensaver | ohranjevalnik zaslona | vaše pravilo |
| Idle timeout | Čas nedejavnosti | |
| Screensaver mode | Način ohranjevalnika zaslona | |
| Pixel shift | Premikanje slikovnih pik | |
| Dim / Dim level | Zatemnitev / Raven zatemnitve | |
| Black / Clock / Website | Črn zaslon / Ura / Spletna stran | načini |
| Photo Gallery / Local Media / Home Assistant Media / Immich Media | Galerija fotografij / Lokalni mediji / Mediji Home Assistant / Mediji Immich | |
| Camera Streams | Pretoki kamer | |
| Weather Mood | Vremensko razpoloženje | |
| Brighten for notifications | Posvetli za obvestila | |
| Turn screen off after | Izklopi zaslon po | |
| Wake to screensaver | Zbujanje v ohranjevalnik zaslona | |
| wake (the screen / dashboard) | zbuditi | |
| Dismiss on motion / face / proximity / person | Zapri ob gibanju / obrazu / bližini / osebi | |
| Postpone screensaver on … | Odloži ohranjevalnik zaslona ob … | |
| Motion / Face / Proximity / Person Detection | Zaznavanje gibanja / obraza / bližine / osebe | |
| Occupancy | Prisotnost | |
| heartbeat | signal delovanja | |
| Scheduled Screensavers | Načrtovani ohranjevalniki zaslona | |
| widget | pripomoček | *Android* |
| At a Glance | Na prvi pogled | ime funkcije |
| slideshow | diaprojekcija | |
| transition | prehod | |
| Crossfade / Slide / Zoom / Ken Burns / Random | Prelivanje / Drsenje / Povečava / Ken Burns / Naključno | |
| Shuffle | Naključni vrstni red | |
| Fill the screen | Zapolni zaslon | |
| Smart | Pametno | |
| metadata | metapodatki | |
| Date taken | Datum posnetka | |
| Camera details | Podatki o fotoaparatu | EXIF, ne kamera kioska |
| focal length / aperture / ISO | goriščna razdalja / zaslonka / ISO | |
| Text drop shadow | Senca besedila | |
| Vignette strength | Moč vinjete | |
| Text scaling / Text scale / Text size | Velikost besedila | |
| Pair portrait / landscape photos | Združi pokončne / ležeče fotografije v pare | |
| subfolders | podmape | |
| Digital Clock / Flip Clock / Roller Clock | Digitalna ura / Preklopna ura / Valjčna ura | |
| Night mode | Nočni način | |
| card color / digit color | barva kartice / barva števk | |
| Global widget scaling | Splošna velikost pripomočkov | |

## 10. Kamera in pretoki

| EN | SL | Opomba |
|---|---|---|
| camera (naprave) | kamera | |
| Front / Back / External | Sprednja / Zadnja / Zunanja | |
| snapshot | posnetek (kamere) | |
| screenshot | posnetek zaslona | *Android* |
| Continuous snapshots / Snapshot interval | Neprekinjeni posnetki / Interval posnetkov | |
| Motion sensor / Person sensor | Senzor gibanja / Senzor osebe | |
| Clear after | Počisti po | |
| Motion sensitivity | Občutljivost zaznavanja gibanja | |
| Startup delay | Zakasnitev zagona | |
| frame rate / resolution / bitrate | hitrost sličic / ločljivost / bitna hitrost | |
| streaming / stream | pretakanje / pretok | |
| Streaming protocol | Protokol pretakanja | |
| Require authentication | Zahtevaj preverjanje pristnosti | |
| username / password | uporabniško ime / geslo | |
| Connected Clients / client / viewer | Povezani odjemalci / odjemalec / gledalec | |
| Overlays (na pretoku) | Prekrivanja | |
| Encrypt stream | Šifriraj pretok | |
| camera view | pogled kamer | |
| Grid | Mreža | |
| codec | kodek | |
| Auto-dismiss after | Samodejno zapri po | |
| Playback | Predvajanje | |
| Import streams | Uvozi pretoke | |

## 11. Mediji

| EN | SL | Opomba |
|---|---|---|
| Media Player / player | Predvajalnik medijev / predvajalnik | [D9] |
| Floating Player | Plavajoči predvajalnik | |
| Now Playing | Zdaj se predvaja | ime funkcije, [D12] |
| Player source | Vir predvajalnika | |
| queue / Up next | čakalna vrsta / Sledi | |
| track | skladba | |
| Play / Pause | Predvajaj / Začasno ustavi | |
| Previous track / Next track | Prejšnja skladba / Naslednja skladba | |
| Turn shuffle on / off | Vklopi / Izklopi naključni vrstni red | |
| Repeat all / Repeat one / Turn repeat off | Ponavljaj vse / Ponavljaj eno / Izklopi ponavljanje | |
| Mute / Unmute / Muted | Izklopi zvok / Vklopi zvok / Utišano | |
| favorites | priljubljene | |
| lyrics | besedilo pesmi | |
| album art / album art cache | naslovnica albuma / predpomnilnik naslovnic | |
| cache | predpomnilnik | |
| speaker selection / speaker group | izbira zvočnika / skupina zvočnikov | |
| room (Sonos) | prostor | |
| line-in | linijski vhod | |
| Audio sync offset | Zamik sinhronizacije zvoka | |
| lossless / efficient / uncompressed | brez izgub / učinkovito / nestisnjeno | |
| chapter | poglavje | |
| DLNA Renderer | Sprejemnik DLNA | po vodniku: »Receiver controls« |

## 12. Interkom in klici

| EN | SL | Opomba |
|---|---|---|
| Intercom | Interkom | [D8] |
| call / Call a kiosk | klic / Pokliči kiosk | |
| ringing / Ring for / Ring sound | zvonjenje / Zvoni / Zvok zvonjenja | |
| Answer (gumb) / Answer mode / Answer automatically | Sprejmi / Način sprejemanja / Samodejno sprejmi | |
| Decline | Zavrni | |
| Missed call | Zgrešen klic | |
| Call back / Call again | Pokliči nazaj / Pokliči znova | |
| End call | Končaj klic | |
| Push to talk / Hands free | Pritisni in govori / Prostoročno | |
| Talk mode | Način govorjenja | |
| announcement / announce | razglas / razglasiti | [D7] |
| Accept announcements | Sprejemaj razglase | |
| intercom key | ključ interkoma | |
| Encrypt communications | Šifriraj komunikacijo | |
| Do not disturb | Ne moti | *Android* |

## 13. Kretnje

| EN | SL | Opomba |
|---|---|---|
| gesture | kretnja | vaše pravilo |
| trigger | sprožilec | |
| tap / double tap | dotik / dvojni dotik | navodilo: »dotaknite se« |
| hold | pridržanje | navodilo: »pridržite« |
| Multi-finger tap / hold | Dotik z več prsti / Pridržanje z več prsti | |
| corner / Corner sequence | kot / Zaporedje kotov | |
| top-left / top-right / bottom-left / bottom-right | zgoraj levo / zgoraj desno / spodaj levo / spodaj desno | |
| clap / Clap detection / Clapper | plosk / Zaznavanje ploskanja / Ploskanje | |
| Show fingers / open hand | Pokaži prste / odprta dlan | |
| Hand Gesture Tester | Preizkus kretenj z roko | |
| swipe / drag | povlecite / povlecite | |
| deep link | globoka povezava | |
| package name | ime paketa | |
| Fire an event / Run a script / Trigger an automation / Call a service | Sproži dogodek / Zaženi skripto / Sproži avtomatizacijo / Pokliči storitev | |
| Toggle | Preklopi | |

## 14. Vtičniki, posodobitve, datoteke, dnevniki

| EN | SL | Opomba |
|---|---|---|
| plugin / Plugin Manager | vtičnik / Upravitelj vtičnikov | vaše pravilo |
| Installed plugins | Nameščeni vtičniki | |
| Developer Tools | Orodja za razvijalce | |
| Trust and install / Trust and update | Zaupaj in namesti / Zaupaj in posodobi | |
| repository | repozitorij | |
| release / release tag / release asset | izdaja / oznaka izdaje / datoteka izdaje | |
| manifest | manifest | |
| hash / checksum | zgoščena vrednost | |
| package | paket | |
| native library / native capability | izvorna knjižnica / izvorna zmožnost | |
| entry class | vstopni razred | |
| Charts / Readings / samples | Grafi / Odčitki / vzorci | |
| Expose to Home Assistant | Izpostavi sistemu Home Assistant | |
| update / Check for updates | posodobitev / Preveri posodobitve | |
| Update available | Na voljo je posodobitev | |
| release notes | opombe ob izdaji | |
| version / build | različica / gradnja | *Android* |
| Update source / Custom Repository | Vir posodobitev / Repozitorij po meri | |
| Install from file / Uploaded APK | Namesti iz datoteke / Naložena datoteka APK | |
| download / upload | prenos / nalaganje | |
| File Manager | Upravitelj datotek | |
| Shared storage / App folder | Skupna shramba / Mapa aplikacije | |
| folder / file / path | mapa / datoteka / pot | |
| Logs / log | Dnevniki / dnevnik | |
| Web Console / console output | Spletna konzola / izpis konzole | |
| clipboard | odložišče | *Android* |
| Errors & crashes / Warnings / Info & debug | Napake in zrušitve / Opozorila / Informacije in razhroščevanje | |
| configuration / Export / Import configuration | konfiguracija / Izvozi / Uvozi konfiguracijo | |
| analytics / Usage / Diagnostics | analitika / Uporaba / Diagnostika | |
| About | O aplikaciji | |
| License / Source code / Attribution / Author / Website | Licenca / Izvorna koda / Navedba avtorstva / Avtor / Spletno mesto | |
| Localization Credits / Contributors by language | Zasluge za prevode / Sodelavci po jezikih | |

## 15. Glas (Voice Satellite) in ESPHome

| EN | SL | Opomba |
|---|---|---|
| wake word / wake word detection | aktivacijska beseda / zaznavanje aktivacijske besede | [D2] |
| stop word / Stop word interruption | beseda za ustavitev / Prekinitev z besedo za ustavitev | |
| wake word engine | mehanizem za aktivacijsko besedo | |
| engine | mehanizem | |
| sensitivity (Slightly / Moderately / Very sensitive) | občutljivost (Rahlo / Zmerno / Zelo občutljivo) | |
| noise gate | prag šuma | |
| arbitration / Arbitration window | usklajevanje / Okno usklajevanja | |
| cached models / custom models | predpomnjeni modeli / modeli po meri | |
| background listening / listening | poslušanje v ozadju / poslušanje | |
| Listening… | Poslušanje … | |
| natively / in the browser | izvorno / v brskalniku | |
| assistant / voice assistant | pomočnik / glasovni pomočnik | |
| pipeline | cevovod | |
| follow-up | nadaljevanje pogovora | **negotovo**, prosim za mnenje |
| conversation | pogovor | |
| chime / Chimes | zvočni signal / Zvočni signali | |
| Wake / Done / Error / Timer / Announcement sound | Zvok ob aktivaciji / ob koncu / ob napaki / časovnika / razglasa | |
| skin | preobleka | |
| overlay / Overlay mode | prekrivni sloj / Način prekrivnega sloja | |
| Docked / Full screen | Zasidrano / Celozaslonsko | |
| activity bar | vrstica dejavnosti | |
| timer / timer pills | časovnik / značke časovnikov | [D16] |
| text to speech | pretvorba besedila v govor | |
| voice | glas | |
| Realtime | Realni čas | [D15] |
| provider / Provider default | ponudnik / Privzeto pri ponudniku | |
| endpoint | končna točka | |
| Reasoning effort | Stopnja razmišljanja | |
| Instructions / Tools | Navodila / Orodja | |
| Session duration | Trajanje seje | |
| Talk over answers | Prekinjanje odgovorov z govorom | |
| migration / Migrate | selitev / Preseli | |
| Wake Word Tester | Preizkus aktivacijske besede | |
| Score / Threshold / Hits / Near misses / Peak | Ocena / Prag / Zadetki / Skoraj zadetki / Vrh | |
| Activations / Peak level / Average level / Clipped / Heard | Aktivacije / Najvišja raven / Povprečna raven / Porezano / Zaznano | |
| Finished speaking detection | Zaznavanje konca govora | |
| Debug logging | Beleženje za razhroščevanje | |
| Enable ESPHome | Omogoči ESPHome | |
| Expose (kiosk) entities / Excluded entities | Izpostavi entitete (kioska) / Izključene entitete | |
| Node name / Encryption key / API port | Ime vozlišča / Šifrirni ključ / Vrata API | |
| Bluetooth Proxy | Posrednik Bluetooth | |
| Scan intensity: Continuous / Balanced / Low power | Intenzivnost iskanja: Neprekinjeno / Uravnoteženo / Varčno | |
| Signal strength / Last seen | Moč signala / Nazadnje zaznano | |
| beacon | oddajnik | |
| rotating address | spremenljiv naslov | |
| Transparency / Background blur | Prosojnost / Zameglitev ozadja | |
| GPS Sensor / Report location / coordinates / GPS receiver | Senzor GPS / Sporočaj lokacijo / koordinate / sprejemnik GPS | |
| Spoof Wi-Fi MAC address | Ponaredi naslov MAC za Wi-Fi | |
| Advanced settings | Napredne nastavitve | |
| Configuration / Diagnostics / Sensor / Control (kategorije entitet) | Konfiguracija / Diagnostika / Senzor / Upravljanje | |

## 15a. Budilke, vreme, pisave, barve

| EN | SL | Opomba |
|---|---|---|
| alarm / Alarms | alarm / Alarmi | *Android, ura* |
| Set an alarm | Nastavi alarm | |
| Snooze / Snoozed until {time} | Dremež / Dremež do {time} | |
| Repeat / Label / Alarm tone | Ponavljanje / Oznaka / Ton alarma | |
| Sunrise | Sončni vzhod | postopno posvetlitev zaslona |
| Today / Tomorrow / Once / Every day / Weekdays / Weekends | Danes / Jutri / Enkrat / Vsak dan / Delavniki / Vikendi | |
| Rings in {duration} | Zazvoni čez {duration} | |
| Ease in the volume | Postopno povečaj glasnost | |
| Silence after | Utišaj po | |
| Phrase | Besedilo | glej razdelek 18 |
| Clear / Partly cloudy / Cloudy | Jasno / Delno oblačno / Oblačno | |
| Rain / Heavy rain / Snow / Snow and rain | Dež / Močan dež / Sneg / Sneg z dežjem | |
| Fog / Hail / Lightning / Lightning and rain | Megla / Toča / Strele / Strele in dež | |
| Wind / Wind and clouds / Exceptional weather | Veter / Veter in oblaki / Izjemno vreme | |
| Day / Night / Dawn/Dusk | Dan / Noč / Zora/mrak | |
| Feels like / Forecast / Humidity / Wind speed / Visibility | Občutena temperatura / Napoved / Vlažnost / Hitrost vetra / Vidljivost | B13: »Feels like {temperature}« = »Občuti se kot {temperature}« |
| apparent temperature | občutena temperatura | |
| font family / font weight | pisava / debelina pisave | |
| Light / Regular / Medium / Bold / Black (debelina) | Tanka / Navadna / Srednja / Krepka / Najkrepkejša | |
| Serif / Condensed / Monospace / Casual / Cursive | Serifna / Zožena / Enakomerno široka / Sproščena / Pisana | |
| Light / Medium / Strong (vibriranje) | Šibko / Srednje / Močno | opis: Light ni barva |
| White / Warm / Amber / Red / Green / Blue / Cyan / Dim | Bela / Topla / Jantarna / Rdeča / Zelena / Modra / Cian / Zatemnjena | pridevniki k »barva« |
| Monochromatic icons | Enobarvne ikone | |
| icon | ikona | |

---

## 16. Števila (ICU množina ni podprta)

Slovenščina ima ednino, dvojino in dve množinski obliki (1 pogled, 2 pogleda, 3 pogledi, 5 pogledov). Validator zavrne ICU, zato:

| Vzorec v angleščini | Slovenski vzorec | Primer |
|---|---|---|
| `{count} views` | samostalnik v množini + dvopičje | »Pogledi: {count}« |
| `{count} selected` | srednji spol + dvopičje | »Izbrano: {count}« |
| `{count} kiosks are ready.` | | »Pripravljeni kioski: {count}.« |
| `Showing {count} of {max}` | »od« ne zahteva sklona po številu | »Prikazano {count} od {max}« |
| `Step {n} of {total}` | | »Korak {n} od {total}« |
| `{count} seconds ago`, `{count}s ago` | okrajšana enota | »pred {count} s« |
| `{count} min ago`, `{count} h ago`, `{count} days ago` | okrajšana enota | »pred {count} min«, »pred {count} h«, »pred {count} d« |
| `Retrying in {seconds}s` | okrajšana enota | »Nov poskus čez {seconds} s« |
| `Rang for {seconds} seconds.` | | »Zvonjenje: {seconds} s.« |
| `{hours} h {minutes} min`, `{seconds} s` | enote že okrajšane | »{hours} h {minutes} min« |
| `{count}-finger tap` | | »Dotik z več prsti ({count})« ali »Dotik s prsti: {count}« |
| `{count} taps in the {corner} corner` | | »Dotiki v kotu {corner}: {count}« |
| ločeni nizi `1 view` / `{count} views` | »1 pogled« ostane; množinski niz po vzorcu zgoraj | |
| `2 taps`, `5 minutes` (fiksna števila) | pravilni sklon za to število | »2 dotika«, »5 minut«, »15 sekund« |

Vsa taka sporočila (približno 85) dobijo zastavico »preoblikovano zaradi števila«.

## 17. Ločila in oblika

| Pravilo | Primer |
|---|---|
| Narekovaji »…« namesto "…" (v JSON brez ubežnih znakov) | `Zamenjaj »{name}«` |
| Tri pike kot en znak …; za celo besedo s presledkom | »Nalaganje …«, »Prenašanje … {percent} %« |
| Odstotek in enote s presledkom [D11] | »10 %«, »5 s«, »3 min«, »48 kHz«, »{lux} lx«, »{value} °C« |
| Brez U+2013 in U+2014; razpon z »do«, ločitev z vejico, dvopičjem ali oklepajem | »vrata od 1024 do 65535«; »{status}: {source}« namesto »{status} - {source}« **(označeno)** |
| »e.g.« → »npr.« | »npr. https://homeassistant.local:8123« |
| Ure kot jih vstavi aplikacija ({time}) | »ob {time}« |
| `\n` ostane na istem mestu, enako število | |
| Puščice → v potih ostanejo | »Nastavitve → Naprave in storitve« |

---

## 18. Dodatki in spremembe med prevajanjem (za pregled)

| EN | SL | Serija | Opomba |
|---|---|---|---|
| Phrase (izgovorjeno besedilo) | Besedilo | B01 | **sprememba**: prej »Besedna zveza« |
| Built-in alarm (ton) | Vgrajeni ton | B01 | |
| blueprint (HA) | načrt | B01 | *HA* |
| LLM conversation agent | pogovorni agent LLM | B01 | |
| Already up to date | Že posodobljeno | B01 | |
| Starting… (pred prenosom) | Pripravljanje … | B01 | |
| Snoozed (alarm) | v dremežu | B01 | |
| Could not list the apps | Seznama aplikacij ni bilo mogoče pridobiti | B01 | |
| Retrying… | Nov poskus … | B01 | |
| camera server | strežnik kamer | B01 | |
| Add by IP | Dodaj prek IP | B02 | |
| Up one folder | Nadrejena mapa | B02 | |
| (kiosk) identity | identiteta (kioska) | B02 | |
| Joined the fleet / Left the fleet | Kiosk se je pridružil floti / Ni več v floti | B02 | brez preteklika s placeholderjem |
| {name} copy | {name} (kopija) | B02 | |
| renderer workarounds | nastavitve upodabljalnika | B02 | |
| None travel (poverilnice) | Nobena se ne prenese | B02 | |
| Looks good. | Videti je v redu. | B02 | |
| in view (kamera, roka) | v kadru | B02 | |
| Snooze the alarm (kretnja) | Dremež alarma | B02 | |
| build (različica brez funkcije) | različica | B02 | v besedilu naravnejše kot »gradnja« |
| Claps (vrsta sprožilca) | Ploskanje | B03 | |
| Mute (v klicu) | Utišaj | B03 | pri medijih ostane »Izklopi zvok« |
| {status} - {source} | {status} · {source} | B03 | vezaj kot pomišljaj zamenjan s piko na sredini |
| Hi-Res / CD quality / Lossy | Hi-Res / Kakovost CD / Z izgubami | B03 | |
| kbps | kb/s | B03 | |
| Dock (konzola) | Zasidraj | B03 | |
| Tip | Namig | B03 | |
| asset (datoteka v paketu vtičnika) | sredstvo | B04 | negotovo; »release asset« ostane »datoteka izdaje« |
| digest (SHA-256) | izvleček | B04 | |
| integrity check | preverjanje celovitosti | B04 | |
| did not stop cleanly | se ni pravilno ustavil | B04 | |
| Screen on / Screen off (hitra kontrola) | Vklopi zaslon / Izklopi zaslon | B04 | |
| Take snapshot | Zajemi posnetek | B04 | |
| display groups | skupine prikaza | B04 | |
| boolean / numeric / RGB hex color | logična / številska / šestnajstiška barva RGB | B04 | |
| WARNING: | OPOZORILO: | B04 | |
| Let alarms take over | Prikaži alarme na ohranjevalniku | B05 | |
| Snooze length / Sunrise length / Ease in over | Trajanje dremeža / Trajanje sončnega vzhoda / Trajanje povečevanja glasnosti | B05 | |
| Return after (seconds) | Vrnitev po (v sekundah) | B05 | vzorec za oznake »(seconds)« |
| Log access | Dostop do dnevnikov | B05 | |
| encoder / listener | kodirnik / poslušalnik | B05 | |
| Still / Live (posnetek zaslona) | Statično / V živo | B05 | |
| Temp | Temp. | B05 | |
| Running - N features | Deluje (funkcije: N) | B05 | vezaj zamenjan z oklepajem |
| grant dialog | pogovorno okno za odobritev | B05 | |
| Foreground app sensor | senzor aplikacije v ospredju | B06 | |
| Friendly name | prikazno ime | B06 | |
| Not offered (dovoljenje) | Ni ponujeno | B06 | |
| GPU | grafični procesor | B06 | |
| ongoing notification | stalno obvestilo | B06 | |
| (missing) | (manjka) | B06 | |
| Prefer X over Y | Daj prednost X pred Y | B06 | |
| GitHub (sklon) | storitev GitHub (»v storitvi GitHub«) | B07 | po D1, popravljen tudi B04 |
| wake lock Held / Released | Aktiven / Sproščen | B07 | |
| reverse proxy | obratni posredniški strežnik | B07 | |
| hostname | ime gostitelja | B07 | |
| downgrade | vrnitev na starejšo različico | B07 | |
| Scale UI | Velikost vmesnika | B07 | |
| announce action | dejanje announce | B07 | ime dejanja HA ostane |
| Made with {heart} by {author} | Z {heart} ustvarja {author} | B08 | sedanjik zaradi spola |
| Buy me a coffee | Častite me s kavo | B08 | |
| Clapper (razdelek) | Ploskanje | B08 | enako kot vrsta sprožilca |
| Strict / Standard | Strogo / Običajno | B08 | |
| Instant | Takoj | B08 | |
| decimalna števila v besedilu | vejica (0,2) | B08 | ne v tehničnih vrednostih |
| controls (entitete) | kontrolniki | B08 | |
| fix (GPS) | določitev položaja | B08 | |
| Act as the home screen | Deluj kot začetni zaslon | B09 | |
| Theme picker | Izbirnik teme | B09 | |
| thermostat dials | vrtljivi gumbi termostatov | B09 | |
| Answer (razdelek) / Talk (razdelek) | Sprejemanje / Govorjenje | B09 | |
| Ignore (možnost) | Prezri | B09 | |
| Regenerate | Ustvari znova | B09 | |
| N fast taps, holding the last | N hitrih dotikov, zadnji pridržan | B09 | |
| PIN (v stavku) | koda PIN | B09 | brez sklanjanja kratice »PIN-a« |
| Duck volume | Zmanjšaj glasnost | B10 | |
| Compact / Large with controls | Kompaktno / Veliko s kontrolniki | B10 | |
| Layout mode: Vertical / Horizontal / Album art only | Način postavitve: Navpično / Vodoravno / Samo naslovnica | B10 | |
| Override (nastavitev) | Preglasi | B10 | |
| Auth token | Žeton za preverjanje pristnosti | B10 | |
| Fallback to X | Nadomestno uporabi X | B10 | |
| Last view / Chosen view | Zadnji pogled / Izbrani pogled | B10 | |
| sample rate / bit depth | frekvenca vzorčenja / bitna globina | B10 | |
| Remote-only | samo na daljavo | B10 | |
| X screensaver (naslov razdelka) | Ohranjevalnik zaslona z X (npr. »z uro«); Black → »Črni ohranjevalnik zaslona« | B11 | |
| AM/PM | dop./pop. | B11 | |
| Forget (zvočnik) | Pozabi | B11 | |
| household (Sonos) | gospodinjstvo | B11 | |
| punch hole | luknja za kamero | B11 | |
| Always show time and info (Android) | Vedno pokaži čas in podatke | B11 | preveri v slovenskem Androidu |
| chips (entitete) | značke | B12 | po D16 |
| Tap edges to change slides | Menjava diapozitivov z dotikom robov | B12 | |
| slide (diaprojekcija) | diapozitiv | B12 | |
| Past N months/years | Zadnji 3 meseci, Zadnji 2 leti, Zadnjih 5 let | B12 | fiksna števila v pravilnem sklonu |
| YYYY-MM-DD | LLLL-MM-DD | B12 | negotovo |
| Anyone / No one / Any | Kdor koli / Nihče / Katera koli | B12 | |
| Timeframe | Časovno obdobje | B12 | |
| Feels like (oznaka) / Feels like {temperature} | Občutena temperatura / Občuti se kot {temperature} | B13 | **sprememba**: prej »Občutek« |
| occupancy sensor (razred HA) | senzor zasedenosti | B13 | oznaka Occupancy na strani osebe ostane »Prisotnost« |
| Clear (stanje senzorja) | Ni zaznano | B13 | |
| Lightning flashes | Bliskanje | B13 | |
| Background opacity | Neprosojnost ozadja | B13 | |
| Time of day | Del dneva | B13 | |
| Screen off never | Brez izklopa zaslona | B13 | |
| Summary »X on / X off« | X: vklopljeno / X: izklopljeno | B13 | vzorec brez ujemanja v spolu |
| Show titles (vremenska vrstica) | Pokaži nazive | B13 | |
| grant (samostalnik) | dovoljenje | B13 | |
| fader | drsnik | B13 | |
| relay (omrežni) | posredovalni strežnik | B14 | proxy ostane »posrednik« |
| bearer token | žeton Bearer | B14 | |
| Reasoning: Minimal / Low / Medium / High / Extra high | Minimalna / Nizka / Srednja / Visoka / Zelo visoka | B14 | pridevniki k »stopnja« |
| Home Assistant Setup (stran v aplikaciji, v besedilu) | nastavitve Home Assistant | B14 | **negotovo** |
| Settings, Devices & services (HA, v besedilu) | Nastavitve, Naprave in storitve | B14 | [D13] |
| uninstall from HACS | odstranite prek HACS | B14 | »Odmesti« ostane za aplikacije Android |
| Migration steps (Save the settings …) | samostalniki: Shranjevanje nastavitev … | B14 | |
| Run from the dashboard again | Vrni izvajanje na nadzorno ploščo | B14 | |
| Learn more about + povezava | Več informacij: + povezava | B14 | |
| inference (aktivacijska beseda) | prepoznavanje | B15 | |
| voice turn | glasovna izmenjava | B15 | |
| embedding window | okno vdelav | B15 | negotovo |
| pull to refresh (stikalo) | osvežitev s potegom navzdol | B15 | dopolni »Povleci za osvežitev« |
| URL Filter | Filter URL | B15 | |
| Wildcard / Regular expression | Nadomestni znaki / Regularni izraz | B15 | |
| Block / Allow only | Blokiraj / Dovoli samo | B15 | |
| dashboard rotation pages | strani v menjavanju pogledov nadzorne plošče | B15 | |
| Long-lived access tokens (HA meni) | Dolgotrajni dostopni žetoni | B15 | [D13] |
| Scan the QR code (gumb) | Preberi kodo QR | B15 | navodilo ostane »Preberite kodo QR« |
| instance (HA) | namestitev | B15 | |
| Flip camera | Zamenjaj kamero | B16 | |
| Restore backup (naslov razdelka) | Obnovitev varnostne kopije | B16 | gumb ostane »Obnovi …« |
| Recommended Service Permissions | Priporočena dovoljenja za storitev | B16 | |
| Built-in ring / Built-in chime | Vgrajeno zvonjenje / Vgrajeni zvočni signal | B16 | |
| sounds folder | mapa zvokov | B16 | |
| Open / High / Low / MCap (finance) | Otvoritev / Najvišja / Najnižja / Tržna kap. | B16 | negotovo |
| Set up\nKiosk Satellite | Nastavite\nKiosk Satellite | B16 | |
