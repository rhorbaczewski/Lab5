# STAGE 1

# Budowa obrazu from scratch
# AS build - nazwa nadana etapowi, zgodnie z dobrymi praktykami dla budowania wieloetapowego
FROM scratch AS build

# Uzyty Alpine - lekki system Linux (wersja z zajec)
ADD alpine-minirootfs-3.23.3-aarch64.tar /

# Wersja aplikacji
ARG VERSION=1.0

# Deklaracja katalogu roboczego
WORKDIR /usr/app

# Skrypt do tworzenia HTML. Uruchamiany przy starcie kontenera, aby pobrać informacje o serwerze
RUN echo '#!/bin/sh' > create_html.sh && \
    echo 'echo "<html><body>" > /www/index.html' >> create_html.sh && \
    echo 'echo "<h1>Informacje</h1>" >> /www/index.html' >> create_html.sh && \
    echo 'echo "<p>IP serwera: $(hostname -i)</p>" >> /www/index.html' >> create_html.sh && \
    echo 'echo "<p>Hostname: $(hostname)</p>" >> /www/index.html' >> create_html.sh && \
    echo 'echo "<p>Wersja: '"$VERSION"'</p>" >> /www/index.html' >> create_html.sh && \
    echo 'echo "</body></html>" >> /www/index.html' >> create_html.sh && \
    chmod +x create_html.sh


# STAGE 2

# Uzyty obraz busybox - lzejszy od nginx i wystarczajacy dla malej strony
FROM busybox

# Deklaracja katalogu roboczego
WORKDIR /www

# Kopiuje skryptu z pierwszego etapu do obrazu koncowego
COPY --from=build /usr/app/create_html.sh /create_html.sh

# Informacja o porcie wewnetrznym kontenera, na ktorym nasluchuje aplikacja
EXPOSE 80

# Procedura Healthcheck - zautomatyzowana weryfikacja dzialania uruchomionej aplikacji
HEALTHCHECK --interval=10s --timeout=2s \
  CMD wget -q -O - http://localhost:80 || exit 1

# Domyslne polecenie przy starcie kontenera
CMD sh -c "sh /create_html.sh && httpd -f -p 80 -h /www"