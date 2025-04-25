FROM centos:7

ARG USERNAME=xpto
ARG HOME=/home/$USERNAME

# Instalações essenciais de compilação
RUN yum -y update && \
    yum -y groupinstall "Development Tools" && \
    yum -y install \
        gcc \
        gcc-c++ \
        make \
        cmake3 \
        clang \
        gmp \
        gmp-devel \
        readline-devel \
        ncurses-devel \
        zlib-devel \
        bzip2-devel \
        xz-devel \
        git \
        wget \
        curl \
        which \
        tar \
        unzip && \
    yum clean all

# Criação do usuário xpto com UID 1000 (padrão típico, pode ser alterado no runtime)
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID $USERNAME && \
    useradd -u $UID -g $GID -m -s /bin/bash $USERNAME

# Corrige CMake para nome padrão
RUN ln -s /usr/bin/cmake3 /usr/local/bin/cmake

# Define usuário e diretório
USER $USERNAME
WORKDIR $HOME
ENV PATH="$HOME/.local/bin:$PATH"

CMD ["/bin/bash"]

