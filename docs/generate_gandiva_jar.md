# Generate Gandiva Jar
This guide will show how to generate the Gandiva jar using the `arrow-dev-environment` docker image from this repo.

## Steps
1. Download the docker image.
```shell
$ docker pull anthonysimbiose/arrow-dev-environment:gandiva
```
2. Create a container using the downloaded image as base.  
    1. Change the `/home/user` to the absolute path in your machine
    where the `arrow` and the `.m2` folders are located.
```shell
$ docker run -d --name "gandiva-dev-env" -v /home/user/arrow:/arrow -v /home/user/.m2:/root/.m2 anthonysimbiose/arrow-dev-environment:gandiva
```   
3. Enter in container and execute the script to build the gandiva jar.
The script is already inside the container.
```shell
$ docker exec -it gandiva-dev-env bash
$ ./build_gandiva_jar.sh
```
4. You can check the created jar inside the `arrow/java/gandiva/target` 
folder, and the cpp binaries inside the `arrow/cpp/build/lib` folder.

## Important Details
When the script to build gandiva is being executing inside the docker,
it can change the permissions for some files inside the `.m2` and
`arrow` directories to the `root` user.  

To avoid permission problems when accessing these directories later
it is recommend to change the permissions for all files of these two
directories when you finish to use the container:
```shell
$ sudo chown your-user:your-user-group -R /home/user/.m2
$ sudo chown your-user:your-user-group -R /home/user/arrow
```

In the given example, remember to change the `user` in the `chown`
command to your user in linux and its respective group and change
the `/home/user` path to the correct absolute path where the `.m2` 
and the `arrow` directories are located inside your machine.