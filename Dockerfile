FROM dustynv/ros:foxy-ros-base-l4t-r32.7.1

ENV ROS1_DISTRO=melodic
ENV ROS2_DISTRO=foxy

ARG ROS_PKG=ros_base
# ENV ROS_DISTRO=melodic
ENV ROS1_ROOT=/opt/ros/${ROS1_DISTRO}

RUN apt-get update && apt-get install vim -y
# RUN curl -s https://install.zerotier.com | sudo bash
# RUN zerotier-cli join db64858fed131582

RUN apt-get install gridsite-clients n2n iputils-ping openvpn -y

# RUN echo "export CYCLONEDDS_URI=file:///root/workspace/cyclonedds.xml" >> ~/.bashrc
# RUN echo "source /root/workspace/install/setup.bash" >> ~/.bashrc
# RUN echo "alias tcp-connector='ros2 run ros_tcp_endpoint default_server_endpoint --ros-args -p ROS_IP:=0.0.0.0'" >> ~/.bashrc
# RUN echo "alias zt-vpn='service zerotier-one start && zerotier-cli join db64858fed131582'" >> ~/.bashrc
# RUN echo "alias ovpn='openvpn /root/workspace/src/ovpn/client.conf" >> ~/.bashrc
# RUN echo "alias chatter='ros2 topic pub /chatter std_msgs/String \"data: Hello ROS Developers\"'" >> ~/.bashrc

# fix cmake version to compile custom ROS2 messages
# https://github.com/dusty-nv/jetson-containers/commit/d5e9d3aab9341ba4b66d01663256956a5b50d9bc
RUN /usr/bin/python3 -m pip install --upgrade pip

RUN /usr/bin/python3 -m pip install Cython scikit-build

RUN apt-get purge -y cmake && \
    /usr/bin/python3 -m pip install cmake==3.23.3 --upgrade --verbose 

RUN apt-get install -y --no-install-recommends \
    build-essential git libbullet-dev libpython3-dev \
    python3-colcon-common-extensions python3-flake8 \
    python3-numpy python3-pytest-cov python3-rosdep \
    cmake-data libarchive13 librhash0 libuv1 python3-argcomplete  \
    python3-colcon-argcomplete python3-colcon-bash python3-colcon-cd \
    python3-colcon-core python3-colcon-defaults python3-colcon-devtools \
    python3-colcon-library-path python3-colcon-metadata \
    python3-colcon-notification python3-colcon-output \
    python3-colcon-package-information python3-colcon-package-selection \
    python3-colcon-parallel-executor python3-colcon-pkg-config \
    python3-colcon-powershell python3-colcon-python-setup-py \
    python3-colcon-recursive-crawl python3-colcon-test-result python3-colcon-zsh \
    python3-distlib python3-empy python3-notify2

# install dependencies require for ROS2 packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libboost-all-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-tools \
    libgstreamer1.0-0 \
    gir1.2-gstreamer-1.0 \
    gstreamer1.0-plugins-base \
    libgstreamer-plugins-base1.0-0 \
    gir1.2-gst-plugins-base-1.0 \
    gstreamer1.0-plugins-good \
    libgstreamer-plugins-good1.0-0 \
    gstreamer1.0-plugins-ugly \
    python3-pytest \
    gstreamer1.0-alsa \
    python3-setuptools \
    festival \
    festvox-kallpc16k \
    python3-gi

# install ROS melodic
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
		cmake \
		build-essential \
		curl \
		wget \
		gnupg2 \
		lsb-release \
		ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
		ros-${ROS1_DISTRO}-`echo "${ROS_PKG}" | tr '_' '-'` \
		ros-${ROS1_DISTRO}-image-transport \
        python-rosdep \
        python-rosinstall \
        python-rosinstall-generator \
        python-wstool \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    cd ${ROS1_ROOT} && \
    #    rosdep init && \
    rosdep update && \
    rm -rf /var/lib/apt/lists/*

# ENV ROS_DISTRO=foxy
ENV ROS1_ROOT=/opt/ros/${ROS1_DISTRO}

# compile ROS1-ROS2 bridge
ENV ROS1_INSTALL_PATH=/opt/ros/${ROS1_DISTRO}
ENV ROS2_INSTALL_PATH=/opt/ros/${ROS2_DISTRO}/install

# RUN /bin/bash -c "source ${ROS1_INSTALL_PATH}/setup.bash"
#RUN /bin/bash -c "source ${ROS2_INSTALL_PATH}/setup.bash"

RUN mkdir /opt/ros1_bridge/src -p
WORKDIR /opt/ros1_bridge/src
RUN git clone https://github.com/ros2/ros1_bridge.git -b ${ROS2_DISTRO}
WORKDIR /opt/ros1_bridge
#RUN apt-get update && rosdep install --from-path /opt/ros1_bridge/src
RUN bash -c "source ${ROS1_INSTALL_PATH}/setup.bash && source ${ROS2_INSTALL_PATH}/setup.bash && colcon build --symlink-install --packages-select ros1_bridge --cmake-force-configure"

#RUN echo "source /opt/ros1_bridge/install/setup.bash" >> ~/.bashrc

WORKDIR /root