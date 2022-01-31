What's the problem? Supply Chain issues, in your Kubernetes Cluster: that's the problem.
This is because our apps aren't entirely ours anymore - I mean, it's likely only 20% of them, or less, is code we have written.  The rest is from various sources and repos with varying degrees of custody and control.  And that's just for openers, that's just libs and packages for our apps.  What about when we think about runtime in a Kubernetes cluster?  Sure, we can take steps to ensure our source code has some oversight.  But what about container respositories themselves, deploying into the cluster in Kubernetes, is there a way to have some semblance of control over that?  Enter the Kubernetes Admmission Controller, a relatively new concept that has come under the spotlight recently due in no small part to the urgency around supply chain attacks.  So, please join me on my journey to learn and share admission controllers in Kuberntes, and forgive my noob demeanor here, but even though it is January 2022, it turns out some of this is pretty bleeding edge.   This tale is quite something.  Well, it's a dramatic tale of high levels of frustration but balanced by a great deal of learning.

TLDR; I look forward (very, very much) to the day when hopefully soon, image signing and selectively admitting images based on their signing can be as smooth as what we already see today in Admission Controllers such as the one from Sysdig: 

![image](https://user-images.githubusercontent.com/4404271/151738456-2c55a5d7-386e-4626-a16a-a8468eb1eda4.png)

![kyverno](https://i.imgur.com/5r7JOIu.gif)

