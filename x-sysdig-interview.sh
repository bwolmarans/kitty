#!/bin/bash
echo ---
echo --- Sysdig Interview 1/31/2022
echo ---
echo --- Brett@Wolmarans.com
echo ---
echo ---
echo ---   Kyverno AC Signing Policy Small POC in EKS
echo ---
echo ---   We will have some signed and unsigned doggy images in public ECR registry
echo ---   Kyverno will audit unsigned in the Red namespace, but block in the Blue namespace.
echo ---   Kyverno will allow signed in all namespaces
echo ---
echo ---   Requirements:
echo ---   - SYSDIG_API_TOKEN env var set
echo ---   - Kyverno installed via Helm
echo ---   - delete any doggy-signed or doggy-unsigned pods in the blue and red ns before proceeding
echo ---
read -p "Press enter to continue"

echo ---
echo --- By the way, it may be good to know what context are we in?
echo ---
read -p "Press enter to continue"
(set -x; kubectl config get-contexts)
echo ---
echo ---  do we have any doggy pods?
echo ---
(set -x; (set -x; kubectl get pods | grep doggy ))
read -p "Press enter to continue"

echo ---
echo ---   do we have any doggy images locally?
echo ---
read -p "Press enter to continue"
(set -x; docker images | grep doggy)
read -p "Press enter to continue"

echo ---
echo ---   lets get these pushed up to ecr
echo --
read -p "Press enter to continue"
echo ---
echo ---'---   we must login to ecr-public (command supported only in us-east-1 as of today not any other region)'
echo ---
read -p "Press enter to continue"
(set -x; aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws)
read -p "Press enter to continue"

echo ---
echo ---   tag our local images with our public registry
echo ---
read -p "Press enter to continue"
(set -x; docker tag doggy-unsigned:latest public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned)
(set -x; docker tag doggy-signed:latest public.ecr.aws/v9f6i2g3/doggy:doggy-signed)
read -p "Press enter to continue"

echo ---
echo ---   and push at last
echo ---
read -p "Press enter to continue"
(set -x; docker push public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned)
(set -x; docker push public.ecr.aws/v9f6i2g3/doggy:doggy-signed)
read -p "Press enter to continue"

echo ---
echo ---   lets sign these for supply chain protection downstream
echo ---
read -p "Press enter to continue"
(set -x; cosign sign -key cosign.key public.ecr.aws/v9f6i2g3/doggy:doggy-signed)
(set -x; cosign verify -key cosign.pub public.ecr.aws/v9f6i2g3/doggy:doggy-signed)
read -p "Press enter to continue"

echo ---
echo --- We must install Kyverno...
echo ---
read -p "Press enter to continue"

echo ~$ helm repo add kyverno https://kyverno.github.io/kyverno/
echo "kyverno" already exists with the same configuration, skipping
echo ~$ helm repo update
echo Hang tight while we grab the latest from your chart repositories...
echo ...Successfully got an update from the "gatekeeper" chart repository
echo ...Successfully got an update from the "eks" chart repository
echo ...Successfully got an update from the "kyverno" chart repository
echo ...Successfully got an update from the "sysdig" chart repository
echo ...Successfully got an update from the "prometheus-community" chart repository
echo ...Successfully got an update from the "bitnami" chart repository
echo Update Complete. Happy Helming!
echo ~$ helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace
echo NAME: kyverno
echo LAST DEPLOYED: Fri Feb 11 05:40:58 2022
echo NAMESPACE: kyverno
echo STATUS: deployed
echo REVISION: 1
echo NOTES:
echo Thank you for installing kyverno v2.2.1 😀
echo
echo Your release is named kyverno, app version v1.6.0
echo ---
read -p "Press enter to continue"

echo ---
echo ---   use red namespace
echo ---
read -p "Press enter to continue"
(set -x; kubectl create namespace red)
(set -x; kubectl config set-context --current --namespace=red)
read -p "Press enter to continue"

echo ---
echo ---   lets use AC in the cluster to WARN in the red namespace
echo ---
read -p "Press enter to continue"
(set -x; cat warn-signed-red-policy.yml )
(set -x; kubectl create -f warn-signed-red-policy.yml)
read -p "Press enter to continue"

echo ---
echo ---   this is the signed image, and therefore should be allowed
echo ---
read -p "Press enter to continue"
(set -x; kubectl run doggy-signed --image=public.ecr.aws/v9f6i2g3/doggy:doggy-signed)
read -p "Press enter to continue"

echo ---
echo ---   Even though the image is not signed, this should be allowed because we are doing an Audit in the Red namespace
echo ---
read -p "Press enter to continue"
echo ---
echo ---   lets notify sysdig events consumer if we find failed signature
echo ---
read -p "Press enter to continue"
set -x
if kubectl run doggy-unsigned --image=public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned 2>&1 >/dev/null | grep failed > /dev/null; then
        curl --request POST --url 'https://us2.app.sysdig.com/api/v1/eventsDispatch/ingest' -H "Authorization: Bearer $SYSDIG_API_TOKEN" --data '{ "events": [ { "timestamp": "2022-01-31T13:44:05+00:00", "rule": "Check image signature", "priority": "warning", "output": "The image signature verification failed for image {{doggy-unsigned}}", "source": "Kyverno 1.5 AC", "tags": [ "foo", "bar" ], "output_fields": { "image": "doggy-unsigned", "field2": "value2" } } ], "labels": { "label1": "label1-value", "label2": "label2-value" } }' -v;
fi
set +x
read -p "Press enter to continue"

echo ---
echo ---   lets look at the kyverno logs to see what it thought of the situation
echo ---
read -p "Press enter to continue"
BLAH=`kubectl get pods -n kyverno | awk 'FNR==2 {print $1}'`
kubectl -n kyverno logs $BLAH | tail
read -p "Press enter to continue"

echo ---
echo ---   use blue namespace - no more warnings here, we are going to enforce!
echo ---
read -p "Press enter to continue"
(set -x; kubectl create namespace blue)
(set -x; kubectl config set-context --current --namespace=blue)
read -p "Press enter to continue"

echo ---
echo ---   lets use AC in the cluster to block in the blue namespace
echo ---
read -p "Press enter to continue"
(set -x; cat block-signed-blue-policy.yml)
(set -x; kubectl create -f block-signed-blue-policy.yml)
read -p "Press enter to continue"

echo ---
echo ---   this is signed, and should be allowed
echo ---
read -p "Press enter to continue"
(set -x; kubectl run doggy-signed --image=public.ecr.aws/v9f6i2g3/doggy:doggy-signed)
read -p "Press enter to continue"

echo ---
echo ---   this is un-signed, and in blue namespace, should be blocked
echo ---
echo ---   lets notify sysdig events consumer if we find failed signature
echo ---
read -p "Press enter to continue"
set -x
if kubectl run doggy-unsigned --image=public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned 2>&1 >/dev/null | grep failed > /dev/null; then
     curl --request POST --url 'https://us2.app.sysdig.com/api/v1/eventsDispatch/ingest' -H "Authorization: Bearer $SYSDIG_API_TOKEN" --data '{ "events": [ { "timestamp": "2022-01-31T13:44:05+00:00", "rule": "Check image signature", "priority": "warning", "output": "The image signature verification failed for image {{doggy-unsigned}}", "source": "Kyverno 1.5 AC", "tags": [ "foo", "bar" ], "output_fields": { "image": "doggy-unsigned", "field2": "value2" } } ], "labels": { "label1": "label1-value", "label2": "label2-value" } }' -v;
fi
set +x
read -p "Press enter to continue"

echo ---
echo ---   lets look at the kyverno logs to see what it thought of the situation
echo ---
read -p "Press enter to continue"
BLAH=`kubectl get pods -n kyverno | awk 'FNR==2 {print $1}'`
kubectl -n kyverno logs $BLAH | tail
read -p "Press enter to continue"

echo ---
echo ---   do we have any doggy pods? in the blue namespace?
echo ---   we should have ONLY the signed pod, the unsigned must be blocked by AC, we will not see it.
echo ---   check your sysdig event log
echo ---
read -p "Press enter to continue"
(set -x; kubectl get pods -n blue | grep doggy)
read -p "Press enter to continue"

echo ---
echo --- Do we have doggy pods in the red namespace? we should have both.
echo ---
read -p "Press enter to continue"
(set -x; kubectl get pods -n red | grep doggy)
read -p "Press enter to continue"


echo ---
echo ---   The End
echo ---
~$



