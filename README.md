# Exploring the Kubernetes Admission Controller
![image](https://user-images.githubusercontent.com/4404271/151740166-10bdef5e-a98c-4a2b-a104-4ff79756b209.png)

## Software Supply Chain management in your Kubernetes Cluster is the problem du jour.

But why?

[Software Supply Chain Issues](https://sysdig.com/blog/software-supply-chain-security/) are top of mind because our apps aren't entirely ours anymore - it would not be uncommon to have more 3rd (and 4th and 5th and onwards) party code in your apps than code you have written yourself. 
[Once study found that the average application includes 118 libraries](https://www.contrastsecurity.com/hubfs/DocumentsPDF/2021-Contrast-Labs-Open-Source-Security-Report.pdf).  

But what about container respositories themselves, and the moment of truth when we are deploying containers into the cluster in Kubernetes, is there a way to have some semblance of control over that?  

Every organization has policies. Some exist to meet legal or governance goals, while others may help ensure best practices and conventions. Approaching compliance manually would be prone to the usual basket of human-error issues and frustrations. If we can automate policy enforcement into the deployment flow, we could achieve consistency, increase development efficiency through immediate feedback, and be more agile by giving developers the freedom to operate independently within a structure of compliance.

Kubernetes allows decoupling policy decisions from the inner workings of the API Server by means of admission controller webhooks, which are executed whenever a resource is created, updated or deleted.

# The Challenge

So to write this blog, I was given some great guidelines, a challenge to embark on:

1. Sign and publish a container image to an OCI registry
2. Demonstrate how the signature verification is performed in the cluster
3. Block signed images in a specific namespace, allow but warn on other namespaces
4. Notify of blocked or noncompliant images in Sysdig events UI

Enter the **Kubernetes Admmission Controller**, a relatively new concept that has come under the spotlight recently due in no small part to the urgency around supply chain 
attacks.  After all, if we can control admission into the cluster, it is the last line of defense.

**Integrity** and **provenance** of container images deployed to a Kubernetes cluster can be ensured via digital signatures. 

## Step 1 of the Challenge

Please take a look in this repo at my [Github Actions](https://github.com/bwolmarans/kitty/actions/workflows/main.yml) where I [build my image,push it to ECR, use cosign to Sign it](https://github.com/bwolmarans/kitty/blob/main/.github/workflows/main.yml) 

![image](https://user-images.githubusercontent.com/4404271/151818873-7efe2add-930c-4532-8089-82824229af26.png)


## Second

*Please join me on my journey to learn and share admission controllers in Kuberntes, and forgive my noob demeanor here, but even though it is January 2022, it turns out some of this is pretty bleeding edge.   This tale is quite something.  Well, it's a dramatic tale of high levels of frustration but balanced by a great deal of learning.


## TLDR; I look forward (very, very much) to the day when hopefully soon, image signing and selectively admitting images based on their signing can be as smooth as what we already see today in Admission Controllers such as the one from Sysdig: 

:+1: This PR looks great - it's ready to merge! :shipit:


![image](https://user-images.githubusercontent.com/4404271/151738456-2c55a5d7-386e-4626-a16a-a8468eb1eda4.png)

And here is what it looks like in the overview:
![image](https://user-images.githubusercontent.com/4404271/151739851-5978365e-ff7a-499d-857f-b04044e13b74.png)

So as shown below, we can utilize Cosign and Kyverno.  This is the part of the blog where I learn the hard way that Container image signing has been and still is a bit of a gap in the security landscape, and that solutions here are very much in flux.  Pardon the pun.  It seems that the good folks at Docker Content Trust/Notary came out of the gates with v1, but that never really gained traction, and while v2 is out now, there are multiple options floating around including projects including Kyverno, looks very interesting, it’s still in the design phase (AFAIK).


## Step 2 and 3 of the Challenge
So seeing the Cosign project come along as part of the Sigstore initiative, I was interested to take a look at it and see how it works. Sigstore has some really interesting ideas about software transparency logs, but for this blog, I’ll just be looking at the raw image signing process.

As shown below, we can *sign*, and verify, and use *Kyverno* to verify signed images *in the cluster*.

![doggy2](https://user-images.githubusercontent.com/4404271/151875416-e84f53bb-487d-47b0-b778-94841f25730a.gif)

But actually getting a single Kyverno policy to Audit or Enforce in multiple namespaces reliably?  I don't think we're there yet.  I'm quite sure of it, as shown by my flow below.

![kyverno](https://i.imgur.com/5r7JOIu.gif)

Kyverno is on version 1.5.  Hopping on the Kyverno slack channel (a very helpful community) I was told that 1.6 will have better namespace support, but I wasn't brave enough to try 1.6 because it wasn't released yet, and honestly I would need more time than this weekend to test this out.

![image](https://user-images.githubusercontent.com/4404271/151742099-841d4806-6530-4401-a497-20f2072f4c79.png)

I also tried [Gatekeeper](https://github.com/open-policy-agent/gatekeeper) the mutating webhook ( can we say Admissions Controller? ) for [OPA](https://github.com/open-policy-agent/opa) but even though OPA is a Graduated CNCF project, the examples in their repo were more basic, focusing on resource limits and avoiding duplicates; I couldn't find any good examples of using Gatekeeper for verification of signed images.  What's worse is installing Gatekeeper failed because I had previously intalled Kyverno, and Gatekeeper actually uses Kyverno under the hood.  Simply un-installing Kyverno manually or via the Helm charts didn't work.  But after I posted some questions on the OPA Slack channel with my logs, the community came to my rescue and helped my manually install the mutating webooks that my original Kyverno install left behind!  After that I was able to get Gatekeepr installed, but by now it was 8PM on Sunday night and I was out of time.

My conclusion is we need a enterprise, user-friendly solution to this.  I would like to see the [Sysdig Admission Controller](https://docs.sysdig.com/en/docs/sysdig-secure/scanning/admission-controller/) give me a nice way to handle this the same way it support the other features it has today.   

# I think that would make life easier for me, and all K8S admins!



