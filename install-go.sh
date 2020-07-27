# Golang Installation
wget https://golang.org/dl/go1.14.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.14.6.linux-amd64.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile && \
echo 'export GOPATH=$HOME/gopath' | tee -a $HOME/.profile && \
echo 'export GOROOT=$HOME/go' | tee -a $HOME/.profile && \
echo 'export PATH=$PATH:$GOROOT/bin' | tee -a $HOME/.profile && \
mkdir -p $HOME/go/{src,pkg,bin}
