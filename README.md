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

## Secure & lightweight microservice with a database backend

In this repo, we demonstrate a microservice written in Rust, and connected to a MySQL database. It supports CRUD operations on a database table via a HTTP service interface. The microservice is compiled into WebAssembly (Wasm) and runs in the WasmEdge Runtime, which is a secure and lightweight alternative to natively compiled Rust apps in Linux containers. The WasmEdge Runtime can be managed and orchestrated by container tools such as the Docker, Podman, as well as almost all flavors of Kubernetes.

### Quickstart with Docker

The easiest way to get started is to use a version of Docker Desktop or Docker CLI with Wasm support.

🐋  [Install Docker Desktop + Wasm (Beta)](https://docs.docker.com/desktop/wasm/)

🐋  [Install Docker CLI + Wasm](https://github.com/chris-crone/wasm-day-na-22/tree/main/server)

Then, you just need to type one command.

```bash
docker compose up
```

This will build the Rust source code, run the Wasm server, and startup a MySQL backing database. It also starts a basic STATIC web interface (available at http://localhost:8090). See the [Dockerfile](Dockerfile) and [docker-compose.yml](docker-compose.yml) files. You can jump directly to the [CRUD tests](#crud-tests) section to interact with the web service.

### CRUD tests

Open another terminal, and you can use the `curl` command to interact with the web service.

When the microservice receives a GET request to the `/init` endpoint, it would initialize the database with the `orders` table.

```bash
curl http://localhost:8080/init
```

When the microservice receives a POST request to the `/create_order` endpoint, it would extract the JSON data from the POST body and insert an `Order` record into the database table.
For multiple records, use the `/create_orders` endpoint and POST a JSON array of `Order` objects.

```bash
curl http://localhost:8080/create_orders -X POST -d @orders.json
```

When the microservice receives a GET request to the `/orders` endpoint, it would get all rows from the `orders` table and return the result set in a JSON array in the HTTP response.

```bash
curl http://localhost:8080/orders
curl http://localhost:8080/update_order -X POST -d @update_order.json
curl http://localhost:8080/delete_order?id=2
```

