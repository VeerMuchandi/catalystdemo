oc new-project catalyst2

# add database secret
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/deployments/vl-db-secret.yaml

#add db deployment config
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/deployments/vl-db-dc.yaml

# add app secret
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/deployments/vl-secret.yaml

# add db service
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/deployments/vl-db-svc.yaml

# add frontend build config
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/deployments/vl-bc.yaml

# add imagestream
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/deployments/vl-is.yaml

# add frontend service
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/deployments/vl-svc.yaml

# add frontend deployment config
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/deployments/vl-dc.yaml

oc annotate dc vivacious-line app.openshift.io/connects-to=vivacious-line-database

# create routes
oc expose svc vivacious-line --path="/fruit/index.html"
oc expose svc vivacious-line --name=vl1 --hostname=$(oc get route vivacious-line --template='{{.spec.host}}')

# add pipeline service account and privileges needed
oc create serviceaccount pipeline
oc adm policy add-scc-to-user privileged -z pipeline
oc adm policy add-role-to-user edit -z pipeline

# add pipeline tasks
oc create -f https://raw.githubusercontent.com/tektoncd/catalog/master/openshift-client/openshift-client-task.yaml

# add frontend pipeline
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/tekton-vl/frontend-pipeline.yaml

# add database pipeline
oc create -f https://raw.githubusercontent.com/VeerMuchandi/catalystdemo/master/tekton-vl/database-pipeline.yaml

# run pipelines first time
tkn pipeline start deploy-frontend -s pipeline
tkn pipeline start deploy-database -s pipeline




