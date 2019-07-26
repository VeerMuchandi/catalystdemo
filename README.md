# OpenShift and Tools Demo

## Prerequisites

* OCP 4.1 cluster
* Install developer console  (currently alpha) as explained here [https://github.com/VeerMuchandi/ocp4-extras/tree/master/devconsole](https://github.com/VeerMuchandi/ocp4-extras/tree/master/devconsole)
*  Install CodeReady Workspaces from OperatorHub Once installed, create a user for yourself. Prior knowledge using CRW is required. Instructions in this document are concise. You may want to learn using CRW first using this  tutorial [https://github.com/VeerMuchandi/CodeReadyWorkspacesAndLauncherTutorial](https://github.com/VeerMuchandi/CodeReadyWorkspacesAndLauncherTutorial)
* Download `tkn` dev build for Mac from [here](https://github.com/VeerMuchandi/catalystdemo/blob/master/tekton-nodejs-todoapp/tkn-20190722.tar)
*




## Demo Setup

### Deploy the two tiered NodeJS todo app

Add a project

```
$ oc new-project catalyst1
```

Create todo list application based on the code from [https://github.com/VeerMuchandi/nodejs-todo-app](https://github.com/VeerMuchandi/nodejs-todo-app) with name  `todo`

```
$ oc new-app https://github.com/VeerMuchandi/nodejs-todo-app --name=todo
```

Patch the `deploymentconfiguration` to disable automatic image change trigger for deployment

```
oc patch dc todo --patch '{"spec":{"triggers": [{"imageChangeParams": {"automatic": false,"containerNames": ["todo"],"from": {"kind": "ImageStreamTag","name": "todo:latest","namespace": "catalyst1"}},"type": "ImageChange"}]}}'
```

This app listens on port `3000`. So change the target port of the service to `3000`.
```
oc patch svc todo --patch '{"spec": { "ports": [{"port": 8080,"targetPort": 3000}]}}'
```


Create a route for the application

```
$ oc expose svc todo
```

Create a database to attach to the application. *Currently the database credentials are hard coded in the app. This code will be changed soon.*

```
oc new-app --template=mongodb-ephemeral \
--param=DATABASE_SERVICE_NAME=mongodb \
--param=MONGODB_USER=user \
--param=MONGODB_PASSWORD=password \
--param=MONGODB_DATABASE=todos \
--param=MONGODB_ADMIN_PASSWORD=password
```

Group the application components together by labeling them

```
oc label dc todo app.kubernetes.io/part-of=todolist 
oc label dc mongodb app.kubernetes.io/part-of=todolist
```

Apply these labels to display technology in the topology view:

```
oc label dc todo app.kubernetes.io/name=nodejs
oc label dc mongodb app.kubernetes.io/name=mongodb
```


If the image change trigger was removed before the build completed, then the app wouldn't be deployed. Roll out the app manually.

```
oc rollout latest todo
```

Test the application at url displayed by the following command:

```
echo $(oc get route todo --template={{.spec.host}})/todo
```
Or go to developer console and click on the route link.

### Fork the repository 

Fork the code  [https://github.com/VeerMuchandi/nodejs-todo-app](https://github.com/VeerMuchandi/nodejs-todo-app) to your git repo.

### Update badge 
* Set up a factory in Code Ready Workspaces for your app.
* Update the badge in the README file, (https://github.com/VeerMuchandi/nodejs-todo-app/blob/master/README.md) to point to your factory. Do this in your fork.

Change the value of `href` to point to your factory.

```
## Deploying to OpenShift

Deploy this sample application to Red Hat CodeReady Workspaces:
<a href="http://codeready-crw.apps.ocp4.home.ocpcloud.com/f?id=factorym3giwt4ttfmvfxgq">
    <img src="http://beta.codenvy.com/factory/resources/codenvy-contribute.svg" width="130" alt="Push" align="top">
</a>
```


### Setting up a workspace in CodeReady

* Login to Code Ready Workspaces
* Create a new workspace with  `NodeJS 10x Stack`, by adding your forked git repo
* Go to terminal and run `npm install`
* Set up a custom `RUN` command with the following :
     * Goal: `run`
    *  Command Line: `cd nodejs-todo-app && npm start`
    * Preview URL: `${server.3000/tcp}/todo`
 
* Run the command and test with the preview url displayed

###  Setting up pipeline

This pipeline will do canary deployment of the same application as a separate deployment but uses the same image stream.

```
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/tekton-nodejs-todoapp/todo-canary.yaml
```

Group canary with the regular app in the topology view

```
oc label dc todo-canary app.kubernetes.io/part-of=todolist --overwrite
```


Add pipeline tasks:

```
oc create -f https://raw.githubusercontent.com/openshift/pipelines-catalog/master/s2i-nodejs/s2i-nodejs-task.yaml

oc create -f https://raw.githubusercontent.com/tektoncd/catalog/master/openshift-client/openshift-client-task.yaml

```

Create pipeline

```
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/tekton-nodejs-todoapp/pipeline.yaml
```

Add pipeline resources. You will have to download this file and edit and add. Your forked repository would be different from mine.

```
wget https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/tekton-nodejs-todoapp/pipeline-resources.yaml
```
Edit the file

Deploy

```
oc create -f pipeline-resources.yaml
```

Add pipeline SA

```
oc create serviceaccount pipeline
```

As a cluster-administrator grant `privileged` SCC to the SA.

```
oc adm policy add-scc-to-user privileged -z pipeline
```

Provide edit role to the SA
```
oc adm policy add-role-to-user edit -z pipeline
```





## Demo Playbook

**to add recording link later**

* Create a workspace with factory

* Edit code in CRW and commit
Code changes in todo.ejs
```

        <!--Edit proposed -->
        <!-- <div id="h1">Red Hat's Todo List</div> -->
```
remove comments
```
<div id="h1">Red Hat's Todo List</div> 
```
```

        <!--Edit proposed -->
        <!-- <div id="h1">Items List</div> -->
```
and here
```
<div id="h1">Items List</div>
```
* Commit to your git repo

* Start Pipeline (your pipeline resources point to your git repo)

```
tkn pipeline start deploy-pipeline -r app-git=sourcecode-git -r app-image=tasks-image -s pipeline
Pipelinerun started: deploy-pipeline-run-q9mpq
```


Look at the running pipelines with `tkn pipelinerun list`. Note the name of pipelinerun that starts. 

Watch pipelinerun logs

```
$ tkn pipelinerun logs deploy-pipeline-run-q9mpq -f
[build : build-step-git-source-sourcecode-git-p7bxv] {"level":"warn","ts":1564115763.6520889,"logger":"fallback-logger","caller":"logging/config.go:65","msg":"Fetch GitHub commit ID from kodata failed: \"KO_DATA_PATH\" does not exist or is empty"}
[build : build-step-git-source-sourcecode-git-p7bxv] {"level":"info","ts":1564115769.7459407,"logger":"fallback-logger","caller":"git/git.go:102","msg":"Successfully cloned https://github.com/VeerMuchandi/nodejs-todo-app @ master in path /workspace/source"}

[build : build-step-generate] Application dockerfile generated in /gen-source/Dockerfile.gen

[build : build-step-image-digest-exporter-generate-4mscq] []


..
...
...
...

```

* Watch running pipeline in devconsole.

* Eventually Canary gets deployed. Test the same using its `route` add `/todo` to the route for testing todolist.

* Show that only canary is new version whereas other app is still old.

* Show metrics in Grafana. Explain the need for serverless

* Deploy Knative app (need to login as admin. unable to do this as a regular user)

```
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/5dbf3e12bcdf9a8e68ee9aa89f684dcdf88aff65/serverless/todo-serverless.yaml
```

* Watch serverless app coming up in a min and test the same.

* Wait for a couple of mins and watch the pod scaling down to 0.







