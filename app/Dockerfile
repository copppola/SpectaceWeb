# ---------------------------------------------
# 1) Elegimos una imagen base ligera con Nginx.
#    - "alpine" = distribución mínima de Linux muy ligera (~5 MB base).
#    - Nginx servirá nuestros ficheros estáticos (index.html).
# ---------------------------------------------
FROM nginx:1.27-alpine

# ---------------------------------------------
# 2) Establecemos variables de entorno útiles.
#    - NGINX_ENVSUBST_OUTPUT_DIR no es estrictamente necesario para
#      una página estática, pero es común verlo; lo dejamos por claridad.
# ---------------------------------------------
ENV NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d

# ---------------------------------------------
# 3) Eliminamos la página por defecto que trae Nginx
#    para evitar que tape nuestra web.
#    - /usr/share/nginx/html = carpeta pública de Nginx.
# ---------------------------------------------
RUN rm -rf /usr/share/nginx/html/*

# ---------------------------------------------
# 4) Copiamos nuestra carpeta con la web (site/) dentro de la carpeta
#    pública que Nginx sirve por defecto.
#    - COPY <origen> <destino>
# ---------------------------------------------
COPY site/ /usr/share/nginx/html/

# ---------------------------------------------
# 5) Exponemos el puerto 80 para que Kubernetes (o Docker)
#    sepa por dónde atenderá el contenedor.
#    *EXPOSE no abre el puerto, solo documenta la intención.
# ---------------------------------------------
EXPOSE 80

# ---------------------------------------------
# 6) Añadimos una comprobación de salud (HEALTHCHECK).
#    - Docker ejecutará periódicamente este comando.
#    - Si falla varias veces, marcará el contenedor como "unhealthy".
# ---------------------------------------------
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ || exit 1

# ---------------------------------------------
# 7) Comando por defecto del contenedor.
#    - Nginx en primer plano (daemon off) para que Docker
#      pueda mantener el proceso principal.
# ---------------------------------------------
CMD ["nginx", "-g", "daemon off;"]
