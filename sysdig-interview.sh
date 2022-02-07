#!/bin/bash
#
# Sysdig Interview 1/31/2022
#
# Brett@Wolmarans.com
#
echo ---
echo ---   do we have any doggy pods?
echo ---
kubectl get pods | grep doggy

echo ---
echo ---   do we have any doggy images?
echo ---
docker images | grep doggy

echo ---
echo ---   Step 1. lets get these pushed up to ecr
echo ---
docker tag doggy-unsigned:latest public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned
docker tag doggy-signed:latest public.ecr.aws/v9f6i2g3/doggy:doggy-signed
docker push public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned
docker push public.ecr.aws/v9f6i2g3/doggy:doggy-signed

echo ---
echo ---   Step 2. lets sign these for supply chain protection downstream
echo ---
cosign sign -key cosign.key public.ecr.aws/v9f6i2g3/doggy:doggy-signed
cosign verify -key cosign.pub public.ecr.aws/v9f6i2g3/doggy:doggy-signed

echo ---
echo ---   use red namespace
echo ---
kubectl config set-context --current --namespace=red

echo ---
echo ---   Step 3. lets use AC in the cluster to WARN in the red namespace
echo ---
cat warn-signed-red-policy.yml
kubectl create -f warn-signed-red-policy.yml

echo ---
echo ---   this s signed and should be allowed
echo ---
kubectl run doggy-signed --image=public.ecr.aws/v9f6i2g3/doggy:doggy-signed

echo ---
echo ---   Even though the image is not signed, this should be allowed because we are doing an Audit in the Red namespace
echo ---
echo ---   Step 4: lets notify sysdig events consumer if we find failed signature
echo ---
if kubectl run doggy-unsigned --image=public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned 2>&1 >/dev/null | grep 'image signature verification failed' > /dev/null; then
    curl --request POST --url 'https://us2.app.sysdig.com/api/v1/eventsDispatch/ingest' -H "Authorization: Bearer $SYSDIG_API_TOKEN" --data '{ "events": [ { "timestamp": "2022-01-31T13:44:05+00:00", "rule": "Check image signature", "priority": "warning", "output": "The image signature verification failed for image {{doggy-unsigned}}", "source": "Kyverno 1.5 AC", "tags": [ "foo", "bar" ], "output_fields": { "image": "doggy-unsigned", "field2": "value2" } } ], "labels": { "label1": "label1-value", "label2": "label2-value" } }' -v
fi

echo ---
echo ---   lets look at the kyverno logs to see if this really was Audited and allowed with a warning
echo ---
kubectl -n kyverno logs kyverno-d4d6566fc-ccnkt | tail

echo ---
echo ---   use blue namespace - no more warnings here, we are going to enforce!
echo ---
kubectl config set-context --current --namespace=blue

echo ---
echo ---   lets use AC in the cluster to block in the blue namespace
echo ---
cat block-signed-blue-policy.yml
kubectl create -f block-signed-blue-policy.yml

echo ---
echo ---   this should be allowed
echo ---
kubectl run doggy-signed --image=public.ecr.aws/v9f6i2g3/doggy:doggy-signed

echo ---
echo ---   this should be blocked
echo ---
echo ---   step 4: lets notify sysdig events consumer if we find failed signature
if kubectl run doggy-unsigned --image=public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned 2>&1 >/dev/null | grep 'image signature verification failed' > /dev/null; then
    curl --request POST --url 'https://us2.app.sysdig.com/api/v1/eventsDispatch/ingest' -H "Authorization: Bearer $SYSDIG_API_TOKEN" --data '{ "events": [ { "timestamp": "2022-01-31T13:44:05+00:00", "rule": "Check image signature", "priority": "warning", "output": "The image signature verification failed for image {{doggy-unsigned}}", "source": "Kyverno 1.5 AC", "tags": [ "foo", "bar" ], "output_fields": { "image": "doggy-unsigned", "ac": "kyverno" } } ], "labels": { "label1": "label1-value", "label2": "label2-value" } }' -v
fi

echo ---
echo ---   do we have any doggy pods?
echo ---   we should only have the signed pod, the unsigned must be blocked by the AC
echo ---
kubectl get pods | grep doggy
