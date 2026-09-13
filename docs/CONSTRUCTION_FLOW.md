### Prvi projekat koji se podize u Docker okruzenju

- Kreiranje Laravel projekta
- Kopiranje (sa drugog projekta) compose.dev.yaml fajla u koren projekta
- Kopiranje docker foldera u koren projekta
- Kopiranje .enf fajla i podesavanje
- Podizanje kontejera i otvaranje web porta:8099 koji je proradio

### Otklanjanje gresaka nastalih pri premestanju aplikacije iz C particije u Ubuntu

- docker compose -f compose.dev.yaml up -d

delovi komande znače:

docker                    Docker komandni alat

compose                   Compose dodatak

-f compose.dev.yaml       YAML fajl koji treba pročitati

up                        napravi i pokreni servise

-d                        pokreni ih u pozadini

Compose fajl je običan tekstualni YAML fajl. On nije izvršni program, već konfiguracija koju Compose čita.

Naziv servisa i PHP-FPM program nisu ista stvar.



- Posle komande iznad ↑ dobijam gresku: Bind for 0.0.0.0:3307 failed: port is already allocated, sto znači da port 3307 već koristi 
drugi Docker kontejner ili neki drugi program. Zbog toga MySQL kontejner ne može da se pokrene.

1. Prekidam trenutno prikazivanje logova

Ctrl + C

2. Proveravam koji kontejner koristi port 3307

docker ps --filter publish=3307

Ovde se videlo da u pozadini radi kontejner mysql vec 7 sati, zatim gasim preko docker desktopa prethodnu aplikaciju koja je radila
u pozadini.

Sada rade svi kontejneri normalno.
- Sledeca greska na ekranu je
  ErrorException
  HTTP 500 Internal Server Error
  tempnam(): file created in the system's temporary directory
- Pošto sam projekat premestio sa Windows particije u Ubuntu, vlasništvo/dozvole direktorijuma su se verovatno promenili.
- Najčešći uzrok posle premeštanja projekta su upravo dozvole ili nedostajući storage/framework/views direktorijum.
- Posle ovih komandi je sve proradilo:

  docker compose -f compose.dev.yaml exec -u root php-fpm sh -lc \
  'mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache &&
  chown -R www-data:www-data storage bootstrap/cache &&
  chmod -R 775 storage bootstrap/cache'

Ciscenje Laravel kesa:

  docker compose -f compose.dev.yaml exec php-fpm php artisan optimize:clear

### Kreiranje novog kontejnera koji treba da automatski izvrsi migracije pri podizanju

- Potrebne izmene se integrisu unutar fajla compose.dev.yaml
- Na osnovu konfiguracije php-fpm i mysql servisa, prvi praktičan korak je da MySQL servisu dodamo healthcheck.
- Migracioni kontejner ne sme da pokrene php artisan migrate samo zato što je MySQL kontejner pokrenut. 
- MySQL procesu treba nekoliko sekundi da postane spreman za konekcije.

Važno je da healthcheck bude poravnat sa image, ports, volumes i networks.
Ispod networks koji postoji od ranije, dodaje se healtcheck i redovi ispod njega

networks:
- laravel-development
healthcheck:
test: ["CMD-SHELL", "mysqladmin ping -h localhost -u root -p$${MYSQL_ROOT_PASSWORD} --silent"]
interval: 5s
timeout: 5s
retries: 10
start_period: 10s

- Njegova funkcija:

  - na svakih 5 sekundi izvršava mysqladmin ping;
  - proverava da li MySQL prihvata konekcije;
  - dok baza nije spremna, kontejner ima status starting;
  - kada baza odgovori, dobija status healthy;
  - migracioni servis će kasnije čekati taj status pre izvršavanja migracija.

- Dvostruki znak:

$${MYSQL_ROOT_PASSWORD}

je nameran. On govori Docker Compose-u da promenljivu ne obrađuje unapred, već da je pročita unutar MySQL kontejnera.

- Nakon izmene ponovo pokrecem kontejnere:

docker compose -f compose.dev.yaml up -d

Zatim proveri stanje:

docker compose -f compose.dev.yaml ps

Ili proveriti samo mysql:

docker compose -f compose.dev.yaml ps mysql

- Pored MySQL kontejnera trebalo bi, posle nekoliko sekundi, da piše:

Up ... (healthy)

Ako bude uspesno sledeci korak je dodavanje samog migrate servisa koji koristi postojeći myapp-php-fpm:dev image

- Sledece je dodavanje linija koda za novi servis migrate koji mora biti poravnat sa ostalim servisima

  migrate:
  image: myapp-php-fpm:dev
  working_dir: /var/www
  command: php artisan migrate --force
  env_file:
  - .env
  volumes:
  - ./:/var/www
  networks:
  - laravel-development
  depends_on:
  mysql:
  condition: service_healthy
  restart: "no"

- Šta radi svaka linija?
- 
image: myapp-php-fpm:dev

Koristi isti PHP image kao Laravel php-fpm servis. Zato migracioni kontejner ima PHP, Composer ekstenzije i sve što Laravel zahteva.

working_dir: /var/www

Postavlja Laravelov direktorijum kao trenutni direktorijum kontejnera.

command: php artisan migrate --force

To je komanda koju kontejner izvršava nakon pokretanja. Laravel izvršava samo migracije koje još nisu evidentirane u tabeli migrations.

env_file:
- .env

Omogućava kontejneru da koristi promenljive za povezivanje sa bazom.

volumes:
- ./:/var/www

Laravel projekat sa Ubuntu sistema postaje dostupan unutar kontejnera u /var/www.

depends_on:
mysql:
condition: service_healthy

Migracije čekaju da MySQL postane potpuno spreman.

restart: "no"

Kontejner se ne pokreće ponovo nakon uspešnog završetka. Normalno je da se ugasi.

- Pre pokretanja proveri da nema greške u uvlačenju:

docker compose -f compose.dev.yaml config

### Kreiranje produkcionog fajla: compose.prod.yaml

- Najvažnija ideja je:

compose.prod.yaml se ne pravi prema nekom obaveznom šablonu, već prema tome šta je Laravel aplikaciji potrebno da radi u produkciji.

- Od čega se polazi?

Pre pisanja produkcijskog fajla:

Ko prima HTTP zahtev? → Nginx

Ko izvršava Laravel? → PHP-FPM

Koja baza se koristi? → MySQL

Gde se trajno čuvaju podaci? → Docker volume

Da li aplikacija koristi Redis? → proverava se .env

Da li migracije treba automatski izvršiti? → migrate servis

Koji port treba da bude dostupan spolja? → Nginx port 80/443

Iz odgovora nastaju servisi.

- Prazan Compose fajl počinje ovako:

services:

- Zatim dodaješ potrebne servise:

services:

    web:

    php-fpm:

    migrate:

    mysql:

- To je početna arhitektura produkcije:

Korisnik → Nginx → PHP-FPM → Laravel → MySQL

1. MySQL servis

- Baza je nezavisna od Laravel koda, pa koristi gotov image:

services:

    mysql:

        image: mysql:8.3

        restart: unless-stopped

        environment:

            MYSQL_DATABASE: ${MYSQL_DATABASE}

            MYSQL_USER: ${MYSQL_USER}

            MYSQL_PASSWORD: ${MYSQL_PASSWORD}

            MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}

        volumes:

            - mysql-data-production:/var/lib/mysql
        healthcheck:
            test:
                - CMD-SHELL
                - mysqladmin ping -h localhost -u root -p$${MYSQL_ROOT_PASSWORD} --silent
            interval: 10s
            timeout: 5s
            retries: 10
            start_period: 10s

- Ovde su linije dodate jer:

image određuje koji program koristimo

environment konfiguriše MySQL

volumes trajno čuva bazu

healthcheck proverava kada je baza spremna

restart je koristan na produkcijskom serveru

2. PHP-FPM servis

- PHP kontejner mora biti izgrađen iz Dockerfile-a projekta:

php-fpm:

    build:

        context: .

        dockerfile: ./docker/common/php-fpm/Dockerfile

        target: production

    image: myapp-php-fpm:prod

    restart: unless-stopped

    env_file:

        - .env

    depends_on:

        migrate:

            condition: service_completed_successfully

- Ovde su važne linije:

dockerfile: ./docker/common/php-fpm/Dockerfile

Govori gde se nalaze instrukcije za pravljenje PHP image-a.

target: production

- Bira produkcijski deo Dockerfile-a.

env_file:
- .env

- Daje Laravelu konfiguraciju baze, APP_KEY, mail podešavanja i ostale promenljive.

3. Migracioni servis

- On koristi isti PHP image:

migrate:

    image: myapp-php-fpm:prod

    working_dir: /var/www

    command: php artisan migrate --force

    env_file:

        - .env

    depends_on:

        mysql:

            condition: service_healthy

    restart: "no"

- Posebnost ovog servisa je:

command: php artisan migrate --force

On ne pokreće PHP-FPM, već samo migracije, a zatim završava rad.

4. Nginx servis

- Nginx prima zahteve korisnika:

web:

    build:

        context: .

        dockerfile: ./docker/production/nginx/Dockerfile

    restart: unless-stopped

    ports:

        - "${NGINX_PORT:-80}:80"

    depends_on:

        php-fpm:

            condition: service_healthy

Ovde je ports potreban zato što korisnik spolja mora da pristupi Nginxu.

MySQL nema ports jer mu Laravel pristupa unutar Docker mreže.

5. Mreža i volume

- Na kraju možeš definisati:

networks:

    laravel-production:

volumes:

    mysql-data-production:

- A svaki servis povezujem na mrežu, tj. treba dodati mrežu svakom servisu:


networks:

- laravel-production

- Bez eksplicitne mreže Compose bi napravio podrazumevanu mrežu, ali imenovana mreža jasno pokazuje strukturu.

#### Kako znam koja linija mi treba?

| Compose opcija | Dodajem je kada                                               |
| -------------- |---------------------------------------------------------------|
| `image`        | Koristim gotov ili već napravljen image                       |
| `build`        | Imam sopstveni Dockerfile                                     |
| `ports`        | Servis mora biti dostupan izvan Dockera                       |
| `volumes`      | Podaci moraju opstati ili se dele između kontejnera           |
| `env_file`     | Programu trebaju environment promenljive                      |
| `environment`  | Direktno podešavam promenljive servisa                        |
| `depends_on`   | Servis treba da sačeka drugi servis                           |
| `healthcheck`  | Moram proveriti da li je servis stvarno spreman               |
| `restart`      | Servis treba ponovo pokrenuti nakon pada ili restarta servera |
| `command`      | Menjam podrazumevanu komandu image-a                          |
| `networks`     | Servisi treba međusobno da komuniciraju                       |


- Ne mora svaki servis imati svaku opciju.

Gde onda pomaže compose.dev.yaml?

Ne koristim ga kao obaveznu osnovu, već kao inventar:

php-fpm:
dockerfile: ./docker/common/php-fpm/Dockerfile

Iz toga saznajem gde je PHP Dockerfile.

mysql:
image: mysql:8.3

Iz toga saznajem koju bazu i verziju koristi projekat.

redis:

Iz toga vidim da možda postoji Redis, ali moram proveriti da li je potreban produkciji.

volumes:
- ./:/var/www

Prepoznajem development bind mount i ne prenosim ga automatski u produkciju.

Praktično pravilo

Najbolji redosled kreiranja od nule je:

1. Dodaj bazu.
2. Dodaj PHP-FPM.
3. Dodaj Nginx.
4. Poveži ih mrežom.
5. Dodaj trajne volume-e.
6. Dodaj healthcheck.
7. Dodaj redosled pokretanja.
8. Dodaj migracioni servis.
9. Redis, queue worker i scheduler dodajem samo ako ih aplikacija koristi.
10. Proverim konfiguraciju: docker compose -f compose.prod.yaml config

Dakle, compose.dev.yaml nije nacrt koji moraš pratiti liniju po liniju. Pravi izvor istine su potrebe aplikacije, 
Dockerfile-ovi i produkcijsko okruženje. Dev fajl mi samo pomaže da te informacije lakše pronađem.
