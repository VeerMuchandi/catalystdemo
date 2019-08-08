DATABASE_SERVICE_NAME=mongodb
MONGODB_USER=user
MONGODB_PASSWORD=password
MONGODB_ADMIN_PASSWORD=password
MONGODB_DATABASE=todos

oc new-project catalyst1

#deploy database
oc new-app --template=mongodb-ephemeral \
--param=DATABASE_SERVICE_NAME=$DATABASE_SERVICE_NAME \
--param=MONGODB_USER=$MONGODB_USER \
--param=MONGODB_PASSWORD=$MONGODB_PASSWORD \
--param=MONGODB_DATABASE=$MONGODB_DATABASE \
--param=MONGODB_ADMIN_PASSWORD=$MONGODB_ADMIN_PASSWORD



#deploy application
oc new-app https://github.com/VeerMuchandi/nodejs-todo-app --name=todo \
-e MONGODB_USER=$MONGODB_USER \
-e MONGODB_PASSWORD=$MONGODB_PASSWORD \
-e MONGODB_DATABASE=$MONGODB_DATABASE \
-e DATABASE_SERVICE_NAME=$DATABASE_SERVICE_NAME

#disable autotrigger for deployment
oc patch dc todo --patch '{"spec":{"triggers": [{"imageChangeParams": {"automatic": false,"containerNames": ["todo"],"from": {"kind": "ImageStreamTag","name": "todo:latest","namespace": "catalyst1"}},"type": "ImageChange"}]}}'

#use port 3000
oc patch svc todo --patch '{"spec": { "ports": [{"port": 8080,"targetPort": 3000}]}}'

#create routes
oc expose svc todo --path="/todo"
oc expose svc todo --name=todo1 --hostname=$(oc get route todo --template='{{.spec.host}}')

#make them part of todolist group
oc label dc todo app.kubernetes.io/part-of=todolist 
oc label dc mongodb app.kubernetes.io/part-of=todolist

#display technology in topology view
oc label dc todo app.kubernetes.io/name=nodejs
oc label dc mongodb app.kubernetes.io/name=mongodb

#labels to connect instances
oc label dc todo app.kubernetes.io/instance=todo
oc label dc mongodb app.kubernetes.io/instance=mongodb

#add pointer
oc annotate dc todo app.openshift.io/connects-to=mongodb


# add deployment config for canary
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/tekton-nodejs-todoapp/todo-canary.yaml

# add environemnt variables to connect to DB
oc set env dc/todo-canary MONGODB_USER=$MONGODB_USER \
MONGODB_PASSWORD=$MONGODB_PASSWORD \
MONGODB_DATABASE=$MONGODB_DATABASE \
DATABASE_SERVICE_NAME=$DATABASE_SERVICE_NAME

# add additional route
oc expose svc todo-canary --name=todo-canary1 --hostname=$(oc get route todo-canary --template='{{.spec.host}}')

#add it to the group
oc label dc todo-canary app.kubernetes.io/part-of=todolist --overwrite

#connect canary with a line to database in topology
oc annotate dc todo-canary app.openshift.io/connects-to=mongodb

#add pipeline tasks
oc create -f https://raw.githubusercontent.com/openshift/pipelines-catalog/master/s2i-nodejs/s2i-nodejs-task.yaml
oc create -f https://raw.githubusercontent.com/tektoncd/catalog/master/openshift-client/openshift-client-task.yaml

#create pipeline
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/tekton-nodejs-todoapp/pipeline.yaml

# add pipeline resoruces
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/tekton-nodejs-todoapp/pipeline-resources.yaml

#service account for pipeline
oc create serviceaccount pipeline

#pipeline account needs edit access
oc adm policy add-role-to-user edit -z pipeline

#pipeline sa needs privileged access. YOU NEED TO BE AN ADMIN TO DO THIS
oc adm policy add-scc-to-user privileged -z pipeline

#rollout app. THIS WILL HAVE TO RUN AFTER INITIAL BUILD COMPLETES
oc rollout latest todo

