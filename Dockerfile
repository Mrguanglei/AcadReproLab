FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/python:3.11.1

# Debian apt 镜像源，可按需覆盖
ARG DEBIAN_MIRROR=https://mirrors.tuna.tsinghua.edu.cn

# Python/uv 镜像源，可按需覆盖
ARG PYPI_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ENV PIP_INDEX_URL=${PYPI_INDEX_URL}
ENV UV_INDEX_URL=${PYPI_INDEX_URL}

# npm 镜像源，可按需覆盖
ARG NPM_REGISTRY=https://registry.npmmirror.com
ENV NPM_CONFIG_REGISTRY=${NPM_REGISTRY}

# 安装 Node.js （满足 >=18）及必要工具
RUN sed -i "s|http://deb.debian.org/debian|${DEBIAN_MIRROR}/debian|g" /etc/apt/sources.list \
  && sed -i "s|http://security.debian.org/debian-security|${DEBIAN_MIRROR}/debian-security|g" /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends nodejs npm \
  && rm -rf /var/lib/apt/lists/*

# 安装 uv，避免依赖额外镜像仓库
RUN pip install --no-cache-dir uv

WORKDIR /app

# 先复制依赖描述文件以利用缓存
COPY package.json package-lock.json ./
COPY frontend/package.json frontend/package-lock.json ./frontend/
COPY backend/pyproject.toml backend/uv.lock ./backend/

# 安装依赖（Node + Python）
RUN npm ci \
  && npm ci --prefix frontend \
  && cd backend && uv sync --frozen

# 复制项目源码
COPY . .

EXPOSE 3000 5001

# 同时启动前后端（开发模式）
CMD ["npm", "run", "dev"]
