# Gunakan base image Ubuntu
FROM ubuntu:22.04

# Install paket yang dibutuhkan
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y sudo git ffmpeg nodejs npm wget mc imagemagick curl shellinabox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install FileBrowser
RUN curl -fsSL https://filebrowser.org/install.sh | bash

# Install Caddy sebagai reverse proxy
RUN apt-get install -y debian-keyring debian-archive-keyring apt-transport-https && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/deb.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list && \
    apt-get update && apt-get install -y caddy

# Buat direktori untuk FileBrowser dan Shellinabox
RUN mkdir -p /split /root/.filebrowser
WORKDIR /split

# Konfigurasi default FileBrowser
RUN filebrowser config set --address 0.0.0.0 --port 8080 --database /root/.filebrowser/filebrowser.db --root /split

# Tambahkan konfigurasi Caddy
RUN echo '
:80 {
    handle_path /terminal* {
        reverse_proxy localhost:3200
    }
    handle_path /files* {
        reverse_proxy localhost:8080
    }
}' > /etc/caddy/Caddyfile

# Expose port untuk akses
EXPOSE 80

# Jalankan semua layanan
CMD bash -c "/usr/bin/shellinaboxd -t -s /:LOGIN & filebrowser -c /root/.filebrowser/filebrowser.db & caddy run --config /etc/caddy/Caddyfile"
