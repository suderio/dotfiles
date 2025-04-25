echo $1

exit 1

docker build -t centos-dev .

docker run -it --rm \
  -v $1:$1 \
  -e UID=$(id -u) -e GID=$(id -g) \
  -e HOME=$HOME -e USERNAME=$(id -un) \
  centos-dev

