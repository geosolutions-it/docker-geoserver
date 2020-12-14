FROM jenkins/agent
LABEL maintainer="Jose Macchi<jose.macchi@geo-solutions.it>"

# install docker client inside container and set permissions
USER root
RUN git config --global user.email "jenkins@unavco.org"
RUN git config --global user.name "Jenkins Agent"
RUN apt-get update && apt-get install -y curl git sudo && curl -sSL https://get.docker.com/ | sh
RUN sudo usermod -aG docker jenkins
RUN echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/90-custom && chmod 0440 /etc/sudoers.d/90-custom
USER 1001