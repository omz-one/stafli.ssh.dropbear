
#
#    Debian 8 (jessie) standard profile (dockerfile)
#    Copyright (C) 2016 SOL-ICT
#    This file is part of the Docker General Purpose System Distro.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

FROM solict/general-purpose-system-distro:debian8_minimal
MAINTAINER Luís Pedro Algarvio <lp.algarvio@gmail.com>

#
# Arguments
#

ARG app_dropbear_listen_addr="0.0.0.0"
ARG app_dropbear_listen_port="22"
ARG app_dropbear_key_size="4096"

#
# Packages
#

# Install daemon and utilities packages
#  - supervisor: for supervisord, to launch and manage processes
#  - dropbear: for dropbear, a lightweight SSH2 server and client that replaces OpenSSH
#  - cron: for crond, the process scheduling daemon
#  - anacron: for anacron, the cron-like program that doesn't go by time
#  - rsyslog: for rsyslogd, the rocket-fast system for log processing
#  - logrotate: for logrotate, the log rotation utility
RUN printf "# Install the required packages...\n" && \
    apt-get update && apt-get install -qy \
      supervisor dropbear \
      cron anacron \
      rsyslog logrotate && \
    printf "# Cleanup the Package Manager...\n" && \
    apt-get clean && rm -rf /var/lib/apt/lists/*;

#
# Configuration
#

# Update daemon configuration
# - Supervisor
# - Rsyslog
# - Cron
# - Dropbear
RUN printf "Updading Supervisor configuration...\n"; \
    mkdir -p /var/log/supervisor; \
    \
    # ignoring /etc/default/supervisor \
    \
    # /etc/supervisor/supervisord.conf \
    file="/etc/supervisor/supervisord.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    perl -0p -i -e "s>\[supervisord\]\nlogfile>\[supervisord\]\nnodaemon=true\nlogfile>" ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/supervisor/conf.d/init.conf \
    file="/etc/supervisor/conf.d/init.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "# init\n\
[program:init]\n\
command=/bin/bash -c \"supervisorctl start rclocal; supervisorctl start rsyslogd; supervisorctl start crond; sleep 5; supervisorctl start dropbear;\"\n\
autostart=true\n\
autorestart=false\n\
startsecs=0\n\
\n" > ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/supervisor/conf.d/rclocal.conf \
    file="/etc/supervisor/conf.d/rclocal.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "# rclocal\n\
[program:rclocal]\n\
command=/bin/bash -c \"/etc/rc.local\"\n\
autostart=false\n\
autorestart=false\n\
startsecs=0\n\
\n" > ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # /etc/rc.local \
    file="/etc/rc.local"; \
    touch ${file} && chown root ${file} && chmod 755 ${file}; \
    \
    printf "Updading Rsyslog configuration...\n"; \
    \
    # /etc/supervisor/conf.d/rsyslogd.conf \
    file="/etc/supervisor/conf.d/rsyslogd.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "# rsyslogd\n\
[program:rsyslogd]\n\
command=/bin/bash -c \"\$(which rsyslogd) -f /etc/rsyslog.conf -n\"\n\
autostart=false\n\
autorestart=true\n\
\n" > ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # ignoring /etc/default/rsyslog \
    \
    # /etc/rsyslog.conf \
    file="/etc/rsyslog.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    # Disable kernel logging \
    perl -0p -i -e "s>\\$\\ModLoad imklog>#\\$\\ModLoad imklog>" ${file}; \
    # Enable cron logging \
    perl -0p -i -e "s>#cron\.\*>cron.*>" ${file}; \
    # Disable xconsole \
    perl -0p -i -e "s>daemon.*;mail>#daemon.*;mail>" ${file}; \
    perl -0p -i -e "s>\t*news.err;>#\tnews.err;>" ${file}; \
    perl -0p -i -e "s>\t\*\.\=debug>#\t*.debug>" ${file}; \
    perl -0p -i -e "s>\t\*\.\=debug>#\t*.debug>" ${file}; \
    perl -0p -i -e "s>\t*\*\.=notice;\*\.=warn\t\|/dev/xconsole>#\t*.=notice;*.=warn\t\|/dev/xconsole>" ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    printf "Updading Cron configuration...\n"; \
    \
    # /etc/supervisor/conf.d/crond.conf \
    file="/etc/supervisor/conf.d/crond.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "# crond\n\
[program:crond]\n\
command=/bin/bash -c \"\$(which cron) -f\"\n\
autostart=false\n\
autorestart=true\n\
\n" > ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # ignoring /etc/default/cron \
    touch /etc/crontab; \
    \
    printf "Updading Dropbear configuration...\n"; \
    \
    # /etc/supervisor/conf.d/dropbear.conf \
    file="/etc/supervisor/conf.d/dropbear.conf"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    printf "# dropbear\n\
[program:dropbear]\n\
command=/bin/bash -c \"opts=\$(grep -o '^[^#]*' /etc/dropbear/dropbear.conf) && exec \$(which dropbear) \$opts -F\"\n\
autostart=false\n\
autorestart=true\n\
\n" > ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # ignoring /etc/default/dropbear \
    \
    # /etc/dropbear/dropbear.conf \
    file="/etc/dropbear/dropbear.conf"; \
    # clear old file
    printf "#\n# dropbear.conf\n#\n" > ${file}; \
    # disable daemon/run in foreground \
    printf "\n# Run in foreground mode\n#-F\n" >> ${file}; \
    # change interface and port \
    printf "\n# Listen on specified address and port (Default: 0.0.0.0:22)\n-p ${app_dropbear_listen_addr}:${app_dropbear_listen_port}\n" >> ${file}; \
    # change ssh keys \
    printf "\n# Use the following ssh keys:\n-r /etc/dropbear/dropbear_rsa_host_key\n" >> ${file}; \
    printf "Done patching ${file}...\n"; \
    \
    # Remove persistent ssh keys \
    printf "\n# Removing persistent ssh keys...\n"; \
    rm -f /etc/dropbear/*host_key; \
    \
    # /etc/rc.local \
    file="/etc/rc.local"; \
    printf "\n# Applying configuration for ${file}...\n"; \
    perl -0p -i -e "s>\nexit 0>\n# exit 0\n>" ${file}; \
    printf "\n\
# Recreate dropbear private keys\n\
# https://github.com/simonswine/docker-dropbear/blob/master/run.sh\n\
CONF_DIR=\"/etc/dropbear\";\n\
SSH_KEY_RSA=\"\${CONF_DIR}/dropbear_rsa_host_key\";\n\
SSH_KEY_DSS=\"\${CONF_DIR}/dropbear_dss_host_key\";\n\
SSH_KEY_ECDSA=\"\${CONF_DIR}/dropbear_ecdsa_host_key\";\n\
\n\
# Check if conf dir exists\n\
if [ ! -d \${CONF_DIR} ]; then\n\
    mkdir -p \${CONF_DIR};\n\
fi;\n\
chown root:root \${CONF_DIR};\n\
chmod 755 \${CONF_DIR};\n\
\n\
# Check if keys exists\n\
if [ ! -f \${SSH_KEY_DSS} ]; then\n\
    rm -f \${SSH_KEY_DSS};\n\
fi;\n\
if [ ! -f \${SSH_KEY_ECDSA} ]; then\n\
    rm -f \${SSH_KEY_ECDSA};\n\
fi;\n\
\n\
# Generate only the RSA key
if [ ! -f \${SSH_KEY_RSA} ]; then\n\
    dropbearkey -t rsa -f \${SSH_KEY_RSA} -s ${app_dropbear_key_size};\n\
fi;\n\
chown root:root \${SSH_KEY_RSA};\n\
chmod 600 \${SSH_KEY_RSA};\n\
\n\
exit 0\n" >> ${file}; \
    printf "Done patching ${file}...\n";

