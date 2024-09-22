#!/bin/bash

###
# Инициализируем бд
###

docker-compose exec -T configSrv mongo --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF

docker-compose exec -T shard1 mongo --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
        { _id : 1, host : "shard1-rs-1:27021" },
        { _id : 2, host : "shard1-rs-2:27022" }
      ]
    }
);
EOF

docker-compose exec -T shard2 mongo --port 27019 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2:27019" },
        { _id : 1, host : "shard2-rs-1:27023" },
        { _id : 2, host : "shard2-rs-2:27024" }
      ]
    }
);
EOF

docker-compose exec -T mongos_router mongo --port 27020 --quiet <<EOF
sh.addShard( "shard1/shard1:27018,shard1-rs-1:27021,shard1-rs-2:27022");
sh.addShard( "shard2/shard2:27019,shard2-rs-1:27023,shard2-rs-2:27024");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );

use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});
EOF


