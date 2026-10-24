## Podesavanje Makefile-a
- Evo kako da podesite Makefile, što je apsolutni standard u IT industriji. Pomoću njega ćete umesto kucanja dugih komandi ili pokretanja skripti koristiti jednostavne prečice od dve reči.
- U korenu vašeg projekta (tamo gde vam stoje compose.dev.yaml i compose.deploy.yaml), kreirajte fajl pod imenom Makefile 
- (obratite pažnju: veliko slovo M, bez ikakve ekstenzije poput .txt ili .sh).

## Vazna napomena za Makefile

- Svaka linija ispod naziva komande (npr. ispod dev: clean) mora počinjati sa jednim Tab karakterom, a ne razmacima (spaces). Ako kopirate kod, proverite da li je vaš tekstualni editor (npr. VS Code) automatski pretvorio Tab u razmake, jer Makefile u tom slučaju neće raditi.


## Kako ovo sada koristite u terminalu?

Sada je prelazak između okruženja maksimalno pojednostavljen. Otvorite terminal u folderu projekta i kucajte:
1. Kada želite da radite lokalno (Dev):

    make dev

   (Ova komanda će automatski ugasiti sve stare kontejnere, obrisati keš, popraviti dozvole nad folderima i podići dev kontejnere).
2. Kada želite da pređete na VM / Deploy:

    make deploy

   (Automatski gasi dev, čisti keš i podiže deploy verziju sa DockerHub-a).
3. Ako samo želite da ugasite sve i očistite foldere:
    
    make stop

   Pokrenite sada komandu make dev u svom terminalu. Da li je uspešno očistila keš i da li se aplikacija uspešno otvorila na portu 8099 bez HTTP 500 greške?

## make clean komanda

  - U Makefile-u koji smo napravili, reč clean: definiše posebnu komandu. Možete je pokrenuti potpuno samostalno u terminalu kucanjem:

    make clean

- Kada god ukucate make clean, izvršiće se sledeći koraci:
1. Automatski će pozvati komandu stop (jer piše clean: stop), što znači da će bezbedno ugasiti sve Docker kontejnere i izbrisati zaostale mreže kako fajlovi ne bi bili zaključani dok rade.
2. Obrisaće sav Laravelov keš i logove koji prave problem (bootstrap/cache, storage/framework/views, storage/logs).
3. Kreiraće svež log fajl i postaviti pune dozvole (777) nad folderima.
   To znači da ako u nekom trenutku u toku rada Laravel ponovo počne da prijavljuje Permission denied ili čudne keš greške, ne morate ponovo da pokrećete ceo Docker. Dovoljno je da uradite make clean, pa nakon toga samo make dev.
