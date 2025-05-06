docker build -t centos-dev .

docker run -it --rm \
  -v "$HOME":"/home/$(id -un)" \
  -e UID="$(id -u)" -e GID="$(id -g)" \
  -e HOME="/home/$(id -un)" -e USERNAME="$(id -un)" \
  centos-dev
