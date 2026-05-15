# Servidor web automatizado con Vagrant, Docker y WordPress


## Lo que necesitas antes de empezar

Necesitas tener instalados en tu ordenador los dos programas siguientes.

- **VirtualBox** 
- **Vagrant**

Para comprobar que ambos están instalados correctamente, abre una terminal en tu ordenador y escribe esto:

```bash
vagrant --version
```

Si ves un número de versión, Vagrant está bien instalado.

---

## Estructura de archivos del proyecto

- **`Vagrantfile`** orquesta todo el proceso de provisioning. Declara la box de Ubuntu 22.04, redirige el puerto 8080 del host al 8080 del guest, ejecuta `script-docker.sh` en el primer arranque, copia `docker-compose.yml`, `Dockerfile.git-sync` y `git-sync.sh` al directorio `~/compose/` de la VM, y lanza `docker compose up -d` como paso final del provisioning.

- **`script-docker.sh`** instala el Docker Engine oficial sobre Ubuntu e instala `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` y `docker-compose-plugin`. Se ejecuta una sola vez durante el primer `vagrant up`.

- **`docker-compose.yml`** define tres servicios. El servicio `db` corre MariaDB 10.6 con las credenciales de WordPress y el volumen `db_data`. El servicio `wordpress` usa la imagen de WordPress, depende de `db`, expone el puerto 8080 y monta dos volúmenes: `wp_content` para los archivos de WordPress y `git_content` en `/var/www/html/git` para el código descargado de GitHub. El servicio `git-sync` se construye desde `Dockerfile.git-sync`, monta `git_content` en `/git-site` y recibe la URL del repositorio a descargar mediante la variable de entorno `REPO_URL`.

- **`Dockerfile.git-sync`** construye la imagen del sincronizador. Parte de Alpine Linux, instala `git`, copia `git-sync.sh` al interior del contenedor, le da permisos de ejecución y lo declara como comando de arranque.

- **`git-sync.sh`** es el script que ejecuta el contenedor git-sync al arrancar. Comprueba si ya existe un repositorio clonado en `/git-site`. Si existe, ejecuta `git pull --ff-only` para traer los cambios nuevos. Si no existe, ejecuta `git clone` con la URL definida en `REPO_URL`. El resultado se deja en el volumen compartido `git_content`, que WordPress monta directamente en `/var/www/html/git`.

---

## Paso 1: Descarga el proyecto

Abre una terminal en tu ordenador y escribe:

```bash
git clone https://github.com/blaaw/Proyecto-Final-AMPSIS.git
```

Esto descarga todos los archivos del proyecto a una carpeta llamada `Proyecto-Final-AMPSIS`. Entra en esa carpeta:

```bash
cd Proyecto-Final-AMPSIS
```

![](img/paso-1.png)

## Paso 2: Arrancar el sistema

Desde la carpeta del proyecto, ejecuta:

```bash
vagrant up
```

El proceso completo tarda varios minutos la primera vez. En las siguientes ejecuciones es mucho más rápido.

Cuando termine, la terminal vuelve al prompt sin mostrar errores.

![](img/paso-2.png)

## Paso 3: Comprobar que los servicios están activos

Entra en la máquina virtual:

```bash
vagrant ssh
```

Comprueba que Docker está corriendo y que los tres contenedores están activos:

```bash
sudo systemctl status docker
docker ps
```

El primer comando muestra `Active: active (running)` en verde. El segundo muestra una tabla con tres filas para `wp_db`, `wp_site` y el contenedor de git-sync, todas con `STATUS: Up`.

![](img/paso-3.png)

Para salir de la máquina virtual:

```bash
exit
```


## Paso 4: Ver el sitio web en el navegador

Abre tu navegador y escribe en la barra de direcciones:

```
http://localhost:8080/
```

Deberías ver la pantalla de instalación de WordPress o el sitio web si ya estaba configurado previamente.

![](img/paso-4.png)

Lo más probable es que tu página aparezca en:
 
```
http://localhost:8080/git/
```
 
![](img/paso-4-git.png)

## Cómo cambiar el repositorio de GitHub que se descarga

Por defecto el sistema descarga `https://github.com/blaaw/trial-webpage`. Para apuntar a tu propio repositorio, abre `docker-compose.yml` en tu editor de texto y localiza esta línea dentro del servicio `git-sync`:

```yaml
environment:
  REPO_URL: https://github.com/blaaw/trial-webpage
```

Cambia la URL por la de tu repositorio:

```yaml
environment:
  REPO_URL: https://github.com/tu-usuario/tu-repositorio
```

Guarda el archivo y vuelve a provisionar la máquina para que el cambio tenga efecto:

```bash
vagrant reload --provision
```

![](img/cambio-repo.png)

## Cómo actualizar el código desde GitHub

Cuando hayas subido cambios a tu repositorio de GitHub y quieras que el servidor los descargue sin reiniciar todo el sistema, ejecuta este comando desde la carpeta del proyecto en tu ordenador:

```bash
vagrant ssh -c "cd ~/compose && docker compose run git-sync"
```

Este comando lanza de nuevo el contenedor git-sync. El script `git-sync.sh` detecta que el repositorio ya existe y ejecuta `git pull` para traer solo los cambios nuevos.


## Cómo borrar todo y empezar desde cero

Si quieres destruir la máquina virtual por completo y volver a empezar:

```bash
vagrant destroy
```

Vagrant pedirá confirmación, escribe `y` y pulsa Enter. Esto borra la máquina virtual de VirtualBox pero no borra los archivos del proyecto en tu ordenador. Para volver a crearlo todo:

```bash
vagrant up
```

Ten en cuenta que los datos de WordPress como páginas creadas o ajustes configurados se perderán, porque los volúmenes de Docker viven dentro de la máquina virtual.


## Estructura de archivos dentro de la máquina virtual tras el arranque

Una vez que `vagrant up` ha terminado, la máquina virtual tiene esta organización de directorios relevante:

`/home/vagrant/compose/` es el directorio de trabajo de Docker Compose. Contiene `docker-compose.yml`, `Dockerfile.git-sync` y `git-sync.sh`, copiados desde tu ordenador durante el provisioning. Desde esta carpeta se lanzaron los contenedores.

`/var/lib/docker/volumes/compose_db_data/` es donde Docker guarda los datos de MariaDB de forma persistente.

`/var/lib/docker/volumes/compose_wp_content/` contiene todos los archivos de la instalación de WordPress: temas, plugins y subidas de medios.

`/var/lib/docker/volumes/compose_git_content/` es el volumen compartido entre el contenedor git-sync y WordPress. Aquí llega el código descargado de GitHub. Dentro del contenedor de WordPress este volumen está montado en `/var/www/html/git`.

![](img/estructura.png)

---

*Beckham Lawrence, Pablo Lopez & David Muñoz -- DAW1A*
