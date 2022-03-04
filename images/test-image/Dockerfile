FROM public.ecr.aws/t0q8k6g2/vagator/image-builder:v20220403-8ef0c24

RUN apt-get update && \
    apt-get install -y \
    wget \
    zip 

# Go standard envs
ENV GOPATH /go
ENV PATH /usr/local/go/bin:$PATH

# install kubectl
ARG K8S_RELEASE=stable
RUN rm -f $(which kubectl) && \
    export KUBECTL_VERSION=$(curl https://storage.googleapis.com/kubernetes-release/release/${K8S_RELEASE}.txt) && \
        wget https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl && \
            chmod +x /usr/local/bin/kubectl

# install go
ARG GO_VERSION=1.17.8
ENV GO_TARBALL "go${GO_VERSION}.linux-amd64.tar.gz"
RUN wget -q "https://storage.googleapis.com/golang/${GO_TARBALL}" && \
    tar xzf "${GO_TARBALL}" -C /usr/local && \
        rm "${GO_TARBALL}"

ADD ["entrypoint.sh", "run.sh", "/usr/local/bin/"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

