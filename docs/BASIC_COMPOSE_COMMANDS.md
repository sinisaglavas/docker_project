### docker compose build
- sluzi za izgradnju ili osvezavanje docker slika koje su definisane u docker-compose.yaml fajlu
- priprema staticke slike na osnovu lokalnih docker fajlova
- ne pokrece kontejnere

### docker compose up
- pokrece sve sto je definisano u docker compose
- pokrenuti svi servisi definisani u compose.yaml
- pisace svi logovi i blokirace terminal

### docker compose up -d
- pokrece se u pozadini bez logova
- nece biti blokiran terminal

### docker compose down -> docker compose -f compose.dev.yaml down
- zaustavlja sve kontejnere - stop nasem docker-u
- kada hocemo da stopiramo razvoj

### docker ps
- da proverimo status pokrenutih kontejnera
- cesto se koristi i znacajna je
- podaci koji se dobijaju:
1. container id - svaki container ima svoj id
2. image - iz kog image-a je kreiran ovaj container
3. command - koja komanda se pokrece kada se ovaj container ukljuci
4. created - kada je pokrenut container
5. status - trenutni status
6. ports - na kom portu rade
7. names - naziv container-a

### docker images
- prikazuje sve image koji postoje
- vidimo velicinu koju imaju
