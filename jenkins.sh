#Default compose args
COMPOSE_ARGS=" -f jenkins.yml -p jenkins "
USER="esaka"
USER_EMAIL="esaka.tom@gmail.com"
USER_PASS="*******"

#Mare sure old containers are gone
sudo docker-compose $COMPOSE_ARGS stop
sudo docker-compose $COMPOSE_ARGS rm --force -v

#build the system
sudo docker-compose $COMPOSE_ARGS build --no-cache
sudo docker-compose $COMPOSE_ARGS up -d

#Run unit tests
sudo docker-compose $COMPOSE_ARGS run --no-deps --rm -e ENV=UNIT identidock
ERR=$?

#Run system test if unit tests passed
if [ $ERR -eq 0 ]; then
  IP=$(sudo docker inspect -f {{.NetworkSettings.IPAddress}} \
    jenkins_identidock_1)
  CODE=$(curl -sL -w "%{http_code}" $IP:9090/monster/bla -o /dev/null) || true
  if [ $CODE -eq 200 ]; then
    echo "Test passed - Tagging"
    HASH=$(git rev-parse --short HEAD)
    sudo docker tag jenkins_identidock $USER/identidock:$HASH
    sudo docker tag jenkins_identidock $USER/identidock:newest
    echo "Pushing"
    sudo docker login -e $USER_EMAIL -u $USER -p $USER_PASS
    sudo docker push $USER/identidock:$HASH
    sudo docker push $USER/identidock:newest
  else
    echo "Site returned" $CODE
    ERR=1
  fi
fi

#Pull down the system
sudo docker-compose $COMPOSE_ARGS stop
sudo docker-compose $COMPOSE_ARGS rm --force -v

return $ERR
