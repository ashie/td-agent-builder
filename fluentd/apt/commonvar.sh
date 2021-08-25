code_name=$(lsb_release --codename --short)
architecture=$(dpkg --print-architecture)
repositories_dir=/fluentd/td-agent/apt/repositories
java_jdk=openjdk-11-jre
case ${code_name} in
  xenial)
    distribution=ubuntu
    channel=universe
    mirror=http://archive.ubuntu.com/ubuntu/
    java_jdk=openjdk-8-jre
    ;;
  bionic|focal|hirsute)
    distribution=ubuntu
    channel=universe
    mirror=http://archive.ubuntu.com/ubuntu/
    ;;
  buster|bullseye)
    distribution=debian
    channel=main
    mirror=http://deb.debian.org/debian
    ;;
esac
