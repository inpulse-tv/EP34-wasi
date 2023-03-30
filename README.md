# EP34-wasi

Ce dépôt contient les ressources relatives à l'épisode 34 de inpulse.tv 👉 

## Capability-based security

* Prérequis :

    * 🦀 [Rust](https://www.rust-lang.org/fr/tools/install) avec la target wasm
    * 🟪 [Wasmtime](https://wasmtime.dev/)
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
# Install WebAssembly target for Rust
rustup target add wasm32-wasi
# Install wasmtime
curl https://wasmtime.dev/install.sh -sSf | bash
```

Pour démontrer les capacités de sécurité de WASI, vous trouverez un petit programme à compiler en wasm qui ne fera que copier un fichier

``` bash
cd file-copy
cargo build --target wasm32-wasi --release
cp target/wasm32-wasi/release/file_copy.wasm .
```

A partir de la on peut utiliser le module avec notre runtime :
* sans parametre 
``` bash
wasmtime file_copy.wasm file.txt file.copy.txt
``` 
> ❌ `error opening input file.txt: failed to find a pre-opened file descriptor through which "file.txt" could be opened`

* avec le parametre `--dir`
``` bash
wasmtime --dir="." file_copy.wasm file.txt file.copy.txt
ls *.txt
``` 
> ✔️ `file.copy.txt  file.txt # le fichier et sa copie`

* en copiant un fichier sensible 
``` bash
$ wasmtime --dir="." file_copy.wasm /etc/passwd file.copy.txt
``` 
> ❌ `opening input /etc/passwd: failed to find a pre-opened file descriptor through which "/etc/passwd" could be opened`

## Microservice sécurisé et léger avec une base de données

Dans cette section, nous présentons un microservice écrit en Rust, connecté à une base de données MySQL. Il prend en charge les opérations CRUD sur une table de base de données via une interface de service HTTP. Le microservice est compilé en WebAssembly (Wasm) et s'exécute dans le runtime WasmEdge, qui est une alternative sécurisée et légère aux applications Rust compilées nativement dans des conteneurs Linux. 

Le runtime WasmEdge peut être géré et orchestré par des outils de conteneur tels que Docker, Podman, ainsi que presque toutes les variantes de Kubernetes.

### Démarrage rapide avec Docker

Le moyen le plus simple de commencer est d'utiliser une version de Docker Desktop ou Docker CLI avec prise en charge de Wasm.

🐋  [Install Docker Desktop + Wasm (Beta)](https://docs.docker.com/desktop/wasm/)

🐋  [Install Docker CLI + Wasm](https://github.com/chris-crone/wasm-day-na-22/tree/main/server)

Ensuite, vous n'avez besoin que de taper une commande.

```bash
docker compose up
```
Cela va construire le code source Rust, exécuter le serveur Wasm et démarrer une base de données MySQL. Il lance également une interface web STATIQUE basique (disponible à l'adresse http://localhost:8090)

Consultez les fichiers Dockerfile et docker-compose.yml pour plus d'informations 

### CRUD tests

Avec n'importe quel client http vous pouvez interragir avec les différents endpoint. Ci-dessous les exemples avec `curl`

Lorsque le microservice reçoit une demande GET vers l'endpoint /init, il initialise la base de données avec la table des commandes.

```bash
curl http://localhost:8080/init
```

Lorsque le microservice reçoit une demande POST vers l'endpoint /create_order, il extrait les données JSON du corps de la requête POST et insère un enregistrement de commande dans la table de la base de données. Pour plusieurs enregistrements, utilisez l'endpoint /create_orders et envoyez un tableau JSON d'objets de commande.

```bash
curl http://localhost:8080/create_orders -X POST -d @orders.json
```
Lorsque le microservice reçoit une demande GET vers l'endpoint /orders, il récupère toutes les lignes de la table des commandes et renvoie le résultat sous forme de tableau JSON dans la réponse HTTP.

```bash
curl http://localhost:8080/orders
curl http://localhost:8080/update_order -X POST -d @update_order.json
curl http://localhost:8080/delete_order?id=2
```

