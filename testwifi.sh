
    echo "Stopping wifi service"
    PIDFile=/home/ApolloMusicStrips/raspberry-wifi-conf/node.pid
    if [ -f $PIDFile ]; then
        sudo kill -9 $(cat $PIDFile)
        sudo kill -9 $(($(cat $PIDFile) + 1))
        sudo rm $PIDFile
    fi
  echo "starting up wifi service"
    cd /home/ApolloMusicStrips/raspberry-wifi-conf
    sudo /usr/bin/node server.js &
    echo $! > node.pid