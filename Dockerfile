# A generic CentOS container with JNLP agent installed.
ARG CENTOS_VERSION=6
FROM centos:${CENTOS_VERSION}

# Define some variables for use in the Dockerfile.
ARG JENKINS_AGENT_VERSION=4.5
ARG JENKINS_AGENT_SCRIPT_VERSION=4.3-9
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG AGENT_WORKDIR=/home/${user}/agent

# Upgrade the CentOS OS to the latest version.
RUN yum upgrade -y

# Install sudo and java-openjdk 1.8.
RUN yum install -y sudo git java-1.8.0-openjdk

RUN yum clean all

# Label the container.
LABEL Description="This is a CentOS ${CENTOS_VERSION} base image, which provides the Jenkins agent executable (agent.jar)" Vendor="Jenkins project" Version="${VERSION}"

# Add a dedicated jenkins system group and user.
RUN groupadd -g ${gid} ${group}
RUN useradd -c "Jenkins user" -d /home/${user} -u ${uid} -g ${gid} -m ${user}

# Define location of the Oracle JDK and added it to /etc/environment.
RUN sh -c "echo export JAVA_HOME=$(rpm -ql java-1.8.0-openjdk | sed -n '1p' | cut -d/ -f1-5)/jre >> /etc/environment"

# Download the Jenkins Slave JAR.
RUN curl --create-dirs -sSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JENKINS_AGENT_VERSION}/remoting-${JENKINS_AGENT_VERSION}.jar
RUN chmod 755 /usr/share/jenkins
RUN chmod 644 /usr/share/jenkins/agent.jar
RUN ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

# Download the Jenkins Slave StartUp Script.
RUN curl --create-dirs -sSLo /usr/local/bin/jenkins-agent https://raw.githubusercontent.com/jenkinsci/docker-inbound-agent/${JENKINS_AGENT_SCRIPT_VERSION}/jenkins-agent
RUN chmod a+x /usr/local/bin/jenkins-agent
RUN ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

# sudo the jenkins user - Not sure it needs it but what the hell.
RUN echo "jenkins ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/jenkins

# Switch to user `jenkins`.
USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}

# Prepare the workspace for user `jenkins`.
RUN mkdir -p /home/${user}/.${user}
RUN mkdir -p ${AGENT_WORKDIR}
VOLUME /home/${user}/.${user}
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

