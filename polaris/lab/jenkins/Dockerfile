FROM quay.io/fairwinds/polaris:10.1 AS polaris

FROM jenkins/jenkins:2.528.3-lts-jdk21

ARG KUBECTL_VERSION=v1.32.0
# Set by BuildKit (amd64 or arm64), so the image also works on Apple Silicon / ARM hosts
ARG TARGETARCH

USER root
COPY --from=polaris /usr/local/bin/polaris /usr/local/bin/polaris
RUN curl -fsSLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    && chmod +x /usr/local/bin/kubectl \
    && git config --system --add safe.directory '*'
USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Outside jenkins_home, so rebuilding the image always applies the latest config
COPY casc.yaml /usr/share/jenkins/casc.yaml
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/casc.yaml
# Skip the setup wizard and allow checkout from the local demo repo (file://)
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"
