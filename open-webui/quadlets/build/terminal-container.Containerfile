FROM fedora:latest

RUN dnf -y \
        --setopt=max_parallel_downloads=20 \
        --setopt=install_weak_deps=False \
        --setopt=tsflags=nodocs \
    install texlive-scheme-basic \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN dnf -y \
        --setopt=max_parallel_downloads=20 \
        --setopt=install_weak_deps=False \
        --setopt=tsflags=nodocs \
    install \
        python3 python3-pip R-devel R fd-find ripgrep findutils patch less openssh rsync curl wget net-tools iputils bind-utils netcat socat telnet vim neovim git cmake perl ruby lua jq xmlstarlet sqlite3 ffmpeg poppler-utils ImageMagick zip unzip tar gzip bzip2 htop lsof strace tmux screen iptables openssl gnupg nodejs nodejs-npm buildah make automake gcc gcc-c++ kernel-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN python3 -m pip install --no-cache-dir --break-system-packages \
        open-terminal \
        numpy pandas scipy scikit-learn \
        matplotlib seaborn plotly \
        jupyter ipython \
        requests beautifulsoup4 lxml \
        sqlalchemy psycopg2-binary \
        pyyaml toml jsonlines \
        tqdm rich \
        openpyxl weasyprint \
        python-docx python-pptx pypdf csvkit

RUN useradd --create-home --shell /bin/bash user \
    && printf 'user ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/user \
    && chmod 0440 /etc/sudoers.d/user \
    && visudo --check --file=/etc/sudoers.d/user \
    && install -d --owner=user --group=user /var/log/open-terminal /home/user/workspace

USER user
WORKDIR /home/user/workspace

ENV SHELL=/bin/bash
ENV OPEN_TERMINAL_FILE_BROWSER_ROOT=/home/user/workspace

EXPOSE 8000

ENTRYPOINT ["open-terminal"]
CMD ["run", "--host", "0.0.0.0", "--port", "8000"]
