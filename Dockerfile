# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

ARG BASE_IMAGE=mcr.microsoft.com/deployment-environments/runners/core
ARG IMAGE_VERSION=latest

FROM ${BASE_IMAGE}:${IMAGE_VERSION}
WORKDIR /

ARG IMAGE_VERSION

# Metadata as defined at http://label-schema.org
ARG BUILD_DATE

RUN az bicep install

RUN apk add --no-cache git curl

#RUN curl -fsSL https://aka.ms/install-azd.sh | bash

RUN curl -fsSL https://azuresdkreleasepreview.blob.core.windows.net/azd/standalone/pr/3552/install-azd.sh | bash -s -- --base-url https://azuresdkreleasepreview.blob.core.windows.net/azd/standalone/pr/3552 --version '' --verbose --skip-verify


RUN mkdir -p ~/.azd/bin
RUN cp ~/.azure/bin/bicep ~/.azd/bin/bicep
RUN chmod -R 755 ~/.azd/bin

RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh

RUN chmod +x ./dotnet-install.sh

RUN ./dotnet-install.sh --version latest -InstallDir /usr/share/dotnet \
&& ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

RUN echo 'export DOTNET_ROOT=/usr/share/dotnet' >> ~/.bashrc
RUN echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> ~/.bashrc

RUN dotnet workload install aspire

# Grab all .sh files from scripts, copy to
# root scripts, replace line-endings and make them all executable
COPY scripts/* /scripts/
RUN find /scripts/ -type f -iname "*.sh" -exec dos2unix '{}' '+'
RUN find /scripts/ -type f -iname "*.sh" -exec chmod +x {} \;
#ENTRYPOINT [ "/bin/bash" ]