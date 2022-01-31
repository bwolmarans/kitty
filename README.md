# What's the problem? 
![image](https://user-images.githubusercontent.com/4404271/151739357-36e75897-4ba6-4582-8d3f-4ec16930faec.png)

## Supply Chain issues, in your Kubernetes Cluster: that's the problem.

But why?

Well, this is because our apps aren't entirely ours anymore - I mean, it's likely only 20% of them, or less, is code we have written.  
The other 80% of our apps are from various sources and repos with varying degrees of custody and control. 
Now, as developers, we can take steps to ensure our source code has some oversight.  

But what about container respositories themselves, and the moment of truth when we are deploying containers into the cluster in Kubernetes, is there a way to have some semblance of control over that?  

Enter the **Kubernetes Admmission Controller**, a relatively new concept that has come under the spotlight recently due in no small part to the urgency around supply chain attacks.  After all, if we can control admission into the cluster, it is the last line of defense.

**Integrity** and **provenance** of container images deployed to a Kubernetes cluster can be ensured via digital signatures. 

**Integrity** means the image has not changed since it was in a known good state, and has not been altered or corrupted.

What is **Provenance**? Provenance is a collection of verifiable data about an image. Provenance  includes details such as the digests of the built images, the repository the code came from, and arguments used to deploy it. 

To achieve this, we sign container images after building, and we must verify  the image signatures before deployment

So, please join me on my journey to learn and share admission controllers in Kuberntes, and forgive my noob demeanor here, but even though it is January 2022, it turns out some of this is pretty bleeding edge.   This tale is quite something.  Well, it's a dramatic tale of high levels of frustration but balanced by a great deal of learning.

TLDR; I look forward (very, very much) to the day when hopefully soon, image signing and selectively admitting images based on their signing can be as smooth as what we already see today in Admission Controllers such as the one from Sysdig: 

:+1: This PR looks great - it's ready to merge! :shipit:

![image](https://user-images.githubusercontent.com/4404271/151738456-2c55a5d7-386e-4626-a16a-a8468eb1eda4.png)

![kyverno](https://i.imgur.com/5r7JOIu.gif)

