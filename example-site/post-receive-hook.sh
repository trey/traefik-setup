#!/bin/bash
# https://blog.pythonanywhere.com/87/
# https://www.digitalocean.com/community/tutorials/how-to-set-up-automatic-deployment-with-git-with-a-vps
# I live in ~/repos/example-project.git/hooks/post-receive

# Update the live code. The `-f` is to force git to blow away any differences in
# that codebase to what just came in from the git push.
# If you want to use a non main/master branch, add its name after `checkout`.
GIT_WORK_TREE=/home/trey/apps/example-project git checkout -f

# Go to the live code folder.
cd /home/trey/apps/example-project

# Do whatever you need to update and run the app.
docker-compose exec web python manage.py migrate
mkdir -p staticfiles
docker-compose exec -T web python manage.py collectstatic --noinput
docker-compose down && docker-compose up -d --build
