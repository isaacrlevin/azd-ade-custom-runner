FROM isaaclevin/ade-custom-runner-base:latest
WORKDIR /

RUN mkdir -p ~/.azd/bin
RUN cp ~/.azure/bin/bicep ~/.azd/bin/bicep
RUN chmod -R 755 ~/.azd/bin

# Grab all .sh files from scripts, copy to
# root scripts, replace line-endings and make them all executable
COPY scripts/* /scripts/
RUN find /scripts/ -type f -iname "*.sh" -exec dos2unix '{}' '+'
RUN find /scripts/ -type f -iname "*.sh" -exec chmod +x {} \;