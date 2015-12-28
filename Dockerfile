#FROM heroku/nodejs
FROM node:0.10.37

RUN apt-get update && apt-get install -y vim zsh less nmap dnsutils mtr-tiny python-software-properties

#TODO also install sysstat - but it doesn't work
#RUN echo 'ENABLED="true"' >/etc/default/sysstat && service sysstat restart

RUN git clone git://github.com/robbyrussell/oh-my-zsh.git /root/.oh-my-zsh && cp /root/.oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc

RUN git clone https://github.com/VundleVim/Vundle.vim.git /root/.vim/bundle/Vundle.vim
COPY docker_vimrc /root/.vimrc
RUN vim +PluginInstall +qall

RUN npm install -g coffee-script forever mocha nodemon

RUN mkdir -p /app/wowfeed/
WORKDIR /app/wowfeed/

COPY package.json /app/wowfeed/
COPY npm-shrinkwrap.json /app/wowfeed/
RUN npm install

VOLUME /app/wowfeed/

#COPY . .

#ONBUILD COPY . /usr/src/app


#RUN ls node_modules
#RUN node -v && \
#    coffee -v && \
#    coffee --compile --output js/ src/ spec/ src_common && \
#    coffee --compile --output public/js-cs src_client src_common
