# SPECTACEWEB

Este proyecto está pensado para mostrar mis habilidades como **DevOps / Cloud / Platform Engineer (junior)**. Consiste en lo siguiente: infraestructura desplegada en **Azure** usando **Terraform**, **dockerización** de una aplicación y despliegue en **Kubernetes (AKS)**, y pipeline de **CI/CD con GitHub Actions**, además de una capa básica de **monitorización (Prometheus + Grafana)**.

El objetivo principal no ha sido optimizar costes, sino **demostrar dominio de las herramientas más utilizadas en entornos profesionales**. Todo el proceso está documentado para que cualquiera pueda seguirlo y entender las decisiones que se han tomado.

Dentro de este README encontrarás tanto las instrucciones para replicar el proyecto, como el paso a paso de cómo se ha llevado a cabo:

[INSTRUCCIONES](#instrucciones)

[PASO A PASO](#paso-a-paso)

#### Tecnologías y habilidades principales:

- Contenedores: **Docker**
- Orquestación: **Kubernetes (AKS) + Helm**
- Infraestructura como código: **Terraform**
- Cloud: **Microsoft Azure**
- Control de versiones: **Git**
- Automatización y CI/CD: **GitHub Actions**
- Monitorización: **Prometheus + Grafana**

------------

## INSTRUCCIONES:

Estas son las instrucciones para replicar el proyecto. Las instrucciones están enfocadas para replicarse en un sistema operativo **linux**. Se asume que ya se ha clonado el repositorio.

**NOTA**: Se puede crear la imágen opcionalmente, o se puede **comenzar por el paso 2** y utilizar la imágen por defecto creada originalmente.

#### REQUISITOS PREVIOS: 
- Git, Docker, Kubectl, Helm, Terraform, y Azure CLI instalados.
- Cuenta en Azure. 

## 1. Crear la imágen.

##### 1.1. Dentro de app/, ejecutamos:
`docker build -t usuario/nombre-repo:tag .`
##### 1.2. Creamos una cuenta en Dockerhub y creamos un repositorio.
##### 1.3. Iniciamos sesión en la terminal mediante `docker login`.
##### 1.4. Publicamos la imágen mediante:
`docker push usuario/nombre-repo:tag`

## 2. Desplegar infraestructura.

##### 2.1. Nos logueamos en Azure mediante `az login`
##### 2.2. Creamos un .env, en el que añadimos lo siguiente (aplicar los comandos para sacar los datos):
		export ARM_SUBSCRIPTION_ID="az account show --query id -o tsv"
		export ARM_TENANT_ID="az account show --query tenantId -o tsv"
##### 2.3. Dentro de la carpeta infra/ ejecutamos:
		terraform init
		source .env
		terraform apply

## 3. Publicar en GitHub.

##### 3.1. Creamos un repositorio vacío en GitHub.
##### 3.2. Inicializamos el repositorio local con `git init`.
##### 3.3. Añadimos todos los archivos al staging `git add .`.
##### 3.4. Creamos el commit `git commit -m “primer commit"`.
##### 3.5. Nos conectamos al repositorio de GitHub:
`git remote add origin url_repositorio`
##### 3.6. Subimos a github `git push -u origin master`

## 4. Configurar workflow CI/CD.

##### 4.1. Seguimos las instrucciones del workflow (.github/workflows/cicd-aks.yml) para configurarlo.

## 5. Monitorización

##### 5.1. Dentro de monitoring/, aplicamos `kubectl apply -f namespace.yaml` para crear el namespace.
##### 5.2. Añadimos los repositorios aplicando:
		helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
		helm repo add grafana https://grafana.github.io/helm-charts
		helm repo update
##### 5.3. Instalamos con:
`helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring -f values-monitoring.yaml`
##### 5.4. Desplegamos:
`kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80`
##### 5.5. Accedemos mediante nuestro navegador a “localhost:3000” (user: admin, password: change_me)


------------

## PASO A PASO

Esto es la documentación del proceso desde el comienzo hasta el final del proyecto.

**OBJETIVO**: Desplegar una página web estática (únicamente con un link que lleva a Amazon) en un cluster de kubernetes de Azure (AKS) usando terraform para desplegar la infraestructura, automatizar build de la imagen con cada push (CI), y desplegarla en el cluster (CD), usando github actions. Sacamos métricas con prometheus, y usamos grafana para visualizarlas.

### FASE 1: Creamos la imágen

Para la web vamos a usar una imagen base **nginx**. Creamos el **dockerfile** y copiamos nuestra carpeta con la app dentro de la carpeta pública que nginx sirve por defecto. Exponemos el **puerto 80** para indicarle a kubernetes por dónde atenderá el contenedor. Creamos también .dockerignore, en el que ignoramos todo (por si se añaden cosas posteriormente) menos la carpeta **“site”**, en la que se encuentra la web. Creamos la imágen, la **publicamos en dockerhub**, y comprobamos que funcione correctamente creando un contenedor y accediendo a él.

### FASE 2: Declaramos y creamos la infraestructura con terraform

Para crear la infraestructura usaremos **terraform y azure**. Primero, declaramos dentro de **“main.tf”** el clúster de aks. Declaramos las variables y sus valores por defecto en **“variables.tf”**. Además, subimos también el **“terraform.tfvars (.example, como plantilla)”** para poder asignar valores concretos a las variables. Nos logueamos con la **Azure CLI** a nuestra cuenta, y creamos el .env con la **Suscripción ID y el Tenant ID**. Desplegamos la infraestructura, y estamos listos para conectarnos al cluster. Para ello, descargamos las credenciales (kubeconfig) para poder comunicarnos con él mediante **kubectl** (previamente instalado).

### FASE 3: Desplegar en kubernetes

Ahora vamos a desplegar la aplicación en **kubernetes**. Para ello, creamos **namespace**, **deployment** sencillo (con la imágen previamente publicada en dockerhub), y service tipo **LoadBalancer**, que creará una **IP pública** que expondrá la web a internet. Lo aplicamos, **sacamos la ip externa**, nos conectamos mediante http para comprobar si funciona, y ya podríamos conectarlo a nuestro **dominio** opcionalmente. Ahora estamos listos para crear nuestro pipeline en github actions.

### FASE 4: Configuramos CICD

Escogemos un **workflow** de **github actions** que consiste en construir y desplegar una imágen a AKS con ACR, y lo modificamos para que, entre otras cosas, sea con **dockerhub**. El workflow consistirá en que con cada push a master, se logueará a dockerhub con las credenciales configuradas en los **secretos del repositorio**, y hará build y push de la nueva imágen, poniéndole a esta la etiqueta del hash del commit. Una vez completado, se loguea en Azure usando los secretos configurados y la **App Registration** previamente creada (junto con un **Federated Credential** para habilitar el inicio de sesión desde github actions) , y despliega la aplicación. Una vez configurado el workflow, comprobamos que funcione correctamente.

### FASE 5: Monitorización del cluster con Prometheus + Grafana

Con el AKS y kubectl funcionando, descargamos **helm**, y creamos un **namespace** para la monitorización. Después, añadimos los **repositorios de helm**, creamos un **values** para personalizar el chart, e instalamos. Creamos un túnel local para acceder a grafana a través del puerto 3000, y ya tenemos lista la monitorización del cluster. Con esto, podremos crear alertas a nuestro gusto.
