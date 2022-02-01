#!/bin/bash
#
# Sysdig Interview 1/31/2022
#
# Brett@Wolmarans.com
#

# do we have any doggy pods?
kubectl get pods | grep doggy

# do we have any doggy images?
docker images | grep doggy

# lets get these to ecr
docker tag doggy-unsigned:latest public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned

docker tag doggy-signed:latest public.ecr.aws/v9f6i2g3/doggy:doggy-signed

docker push public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned

docker push public.ecr.aws/v9f6i2g3/doggy:doggy-signed

# lets sign these for supply chain protection downstream
cosign sign -key cosign.key public.ecr.aws/v9f6i2g3/doggy:doggy-signed

cosign verify -key cosign.pub public.ecr.aws/v9f6i2g3/doggy:doggy-signed

# lets use AC in the cluster to enforce this signing
cat kyverno-doggy.yml

kubectl create -f kyverno-doggy.yml
# this should be allowed
kubectl run doggy-signed --image=public.ecr.aws/v9f6i2g3/doggy:doggy-signed

# step 4: lets notify sysdig events consumer if we find failed signature
if kubectl run doggy-unsigned --image=public.ecr.aws/v9f6i2g3/doggy:doggy-unsigned 2>&1 >/dev/null | grep 'image signature verification failed' > /dev/null; then
    curl --request POST --url 'https://us2.app.sysdig.com/api/v1/eventsDispatch/ingest' -H "Authorization: Bearer $SYSDIG_API_TOKEN" --data '{ "events": [ { "timestamp": "2022-01-31T13:44:05+00:00", "rule": "Check image signature", "priority": "warning", "output": "The image signature verification failed for image {{doggy-unsigned}}", "source": "Kyverno 1.5 AC", "tags": [ "foo", "bar" ], "output_fields": { "image": "doggy-unsigned", "field2": "value2" } } ], "labels": { "label1": "label1-value", "label2": "label2-value" } }' -v
fi

# do we have any doggy pods?
# we should only have the signed pod, the unsigned must be blocked by the AC
kubectl get pods | grep doggy
