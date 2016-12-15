FROM paddledev/paddle:gpu-demo-v0.9.0a0
MAINTAINER PaddlePaddle Authors
ENV work_dir /root
WORKDIR ${work_dir}
RUN cp -r /paddle/ /root/
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
