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
$ ./build_gandiva_jar.sh
```
4. You can check the created jar inside the `arrow/java/gandiva/target`
folder.