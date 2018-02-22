Do this after running terraform, so the ECR repo exists.
```
$(aws ecr get-login --no-include-email --region us-west-2)
docker build -t ecs-autoscaling-dev-timed-stress .
docker tag ecs-autoscaling-dev-timed-stress:latest 519765885403.dkr.ecr.us-west-2.amazonaws.com/ecs-autoscaling-dev-timed-stress:latest
docker push 519765885403.dkr.ecr.us-west-2.amazonaws.com/ecs-autoscaling-dev-timed-stress:latest
```
