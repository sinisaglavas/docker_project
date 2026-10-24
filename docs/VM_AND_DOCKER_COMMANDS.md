# Komande za VM i Docker projekat

Praktičan podsetnik za rad sa Laravel projektom u virtuelnoj mašini i Docker-u.

## 1. Ulazak u VM i projekat

    ssh korisnik@IP_ADRESA_VM

Povezuje se na VM preko SSH-a. Ako već radiš direktno u terminalu VM-a, ova komanda nije potrebna.

    pwd

Prikazuje trenutni direktorijum.

    cd /home/devops/docker_project

Ulazi u direktorijum projekta. Putanju prilagodi stvarnoj lokaciji projekta.

    cd ~/docker_project

Ulazi u projekat ako se nalazi u home direktorijumu korisnika.

    cd ..
    cd ~

Prva komanda vraća jedan nivo iznad, a druga vraća u home direktorijum.

    ls -la

Prikazuje sve fajlove, uključujući skrivene, sa dozvolama i vlasnikom.

    whoami

Prikazuje trenutno prijavljenog korisnika.

    clear

Čisti prikaz terminala; ne briše fajlove.

## 2. Provera IP adrese VM-a

    hostname -I

Brzo prikazuje IP adrese VM-a.

    ip addr

Detaljno prikazuje mrežne interfejse, IP adrese i njihov status. Kraći oblik je ip a.

    ping -c 4 8.8.8.8

Proverava da VM ima mrežnu/internet konekciju.

    ping -c 4 IP_ADRESA_VM

Proverava dostupnost VM-a sa druge mašine.

## 3. Git komande u projektu

Komande pokreći iz korena projekta:

    cd /home/devops/docker_project

    git status

Prikazuje izmene, nove fajlove i nekomitovane promene.

    git pull origin main

Preuzima poslednje izmene sa GitHub-a iz grane main.

    git branch --show-current
    git log -1 --oneline

Prikazuje trenutnu granu i poslednji commit.

## 4. Provera Docker-a na VM-u

    docker --version
    docker compose version

Proverava da li su Docker i Docker Compose instalirani.

    sudo systemctl status docker

Prikazuje da li Docker servis radi.

    sudo systemctl start docker

Pokreće Docker servis.

    sudo systemctl enable docker

Podešava automatsko pokretanje Docker-a posle startovanja VM-a.

## 5. Osnovne Docker komande

    docker ps

Prikazuje trenutno aktivne kontejnere.

    docker ps -a

Prikazuje aktivne i zaustavljene kontejnere.

    docker images

Prikazuje image-e koji se nalaze lokalno na VM-u.

    docker pull IMAGE:TAG

Preuzima image sa Docker Hub-a. Primer:

    docker pull sinisaglavas/docker-project-php-fpm:latest

    docker logs IME_KONTEJNERA

Prikazuje logove kontejnera.

    docker logs -f IME_KONTEJNERA

Prikazuje logove uživo; izlaz je Ctrl+C.

    docker exec -it IME_KONTEJNERA sh

Otvara shell unutar aktivnog kontejnera.

    docker stop IME_KONTEJNERA

Zaustavlja jedan kontejner.

    docker rm IME_KONTEJNERA

Briše zaustavljeni kontejner.

## 6. Docker Compose: provera konfiguracije

Komande se pokreću iz korena projekta:

    cd /home/devops/docker_project

    docker compose -f compose.dev.yaml config
    docker compose -f compose.deploy.yaml config

Proveravaju YAML sintaksu i prikazuju konačnu Compose konfiguraciju.

## 7. Development okruženje

    docker compose -f compose.dev.yaml up -d --build

Izgrađuje image-e i pokreće development kontejnere u pozadini.

    docker compose -f compose.dev.yaml ps

Prikazuje status development servisa.

    docker compose -f compose.dev.yaml logs -f

Prikazuje logove svih development servisa uživo.

    docker compose -f compose.dev.yaml down --remove-orphans

Zaustavlja development kontejnere i uklanja zaostale Compose kontejnere/mreže.

U ovoj konfiguraciji aplikacija je na portu 8080, a phpMyAdmin na portu 8081.

## 8. Deploy/produkcijsko okruženje

    docker compose -f compose.deploy.yaml pull

Preuzima najnovije image-e sa Docker Hub-a.

    docker compose -f compose.deploy.yaml up -d

Pokreće deploy okruženje u pozadini.

    docker compose -f compose.deploy.yaml ps

Prikazuje status servisa i health status baze/php-fpm servisa.

    docker compose -f compose.deploy.yaml logs -f

Prikazuje deploy logove uživo.

    docker compose -f compose.deploy.yaml down --remove-orphans

Zaustavlja deploy okruženje, ali ne briše named volume-e.

## 9. Osvežavanje verzije sa Docker Hub-a

    docker compose -f compose.deploy.yaml pull
    docker compose -f compose.deploy.yaml up -d

Preuzima nove image-e i ponovo kreira servise kada je potrebno. Ovo je standardni redosled nakon uspešnog GitHub Actions build/push procesa.

## 10. Migracije i Laravel komande

    docker compose -f compose.deploy.yaml run --rm migrate php artisan migrate --force

Ručno izvršava Laravel migracije u deploy okruženju i briše privremeni migrate kontejner.

    docker compose -f compose.deploy.yaml exec php-fpm php artisan migrate:status

Prikazuje status Laravel migracija.

    docker compose -f compose.dev.yaml exec php-fpm php artisan optimize:clear

Čisti Laravel cache u development okruženju.

    docker compose -f compose.deploy.yaml exec php-fpm php artisan optimize:clear

Čisti Laravel cache u deploy okruženju.

## 11. Makefile prečice

    make dev

Zaustavlja prethodno okruženje, čisti Laravel fajlove i pokreće development konfiguraciju.

    make deploy

Zaustavlja prethodno okruženje i pokreće deploy konfiguraciju.

    make stop

Zaustavlja development i deploy Compose okruženja.

    make clean

Poziva make stop, čisti odabrane Laravel cache/log fajlove i podešava dozvole.

## 12. Provera portova

    docker ps

Portovi kontejnera prikazuju se u koloni PORTS.

    sudo ss -tulpn | grep ':80'
    sudo ss -tulpn | grep ':8080'
    sudo ss -tulpn | grep ':8081'

Proveravaju procese koji koriste navedene portove.

    docker ps --filter publish=8080

Prikazuje kontejner koji objavljuje port 8080.

## 13. Docker mreže i volume-i

    docker network ls

Prikazuje Docker mreže.

    docker volume ls

Prikazuje Docker volume-e, uključujući volume sa MySQL podacima.

    docker volume inspect IME_VOLUME-A

Prikazuje detalje i lokaciju određenog volume-a.

## 14. Važan oprez pri brisanju

    docker compose -f compose.deploy.yaml down

Zaustavlja kontejnere, a čuva named volume-e i podatke baze.

    docker compose -f compose.deploy.yaml down -v

Zaustavlja kontejnere i briše Compose volume-e. Ne koristiti rutinski jer može obrisati bazu.

    docker system prune -a --volumes

Agresivno čisti nekorišćene Docker resurse. Ne koristiti bez provere, posebno na VM-u sa važnim podacima.

Pre čišćenja proveri stanje:

    docker ps -a
    docker images
    docker volume ls
    docker compose -f compose.deploy.yaml ps

## 15. Preporučeni redosled posle restarta VM-a

    cd /home/devops/docker_project
    sudo systemctl status docker
    docker compose -f compose.deploy.yaml ps
    docker compose -f compose.deploy.yaml pull
    docker compose -f compose.deploy.yaml up -d
    docker compose -f compose.deploy.yaml ps

Ako servis nije zdrav, pregledaj poslednjih 100 logova:

    docker compose -f compose.deploy.yaml logs --tail=100 web
    docker compose -f compose.deploy.yaml logs --tail=100 php-fpm
    docker compose -f compose.deploy.yaml logs --tail=100 mysql

