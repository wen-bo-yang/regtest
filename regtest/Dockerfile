FROM paddledev/paddle:gpu-demo-v0.9.0a0
MAINTAINER PADDLE QA TEAM
ENV work_dir /root
WORKDIR ${work_dir}
COPY build_docker.sh /
RUN /build_docker.sh
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
