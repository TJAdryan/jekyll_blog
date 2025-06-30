---
title: "Building Data Pipelines with Dagster: A Practical Guide"
date: 2025-06-29
categories: [Data Engineering, Python, Orchestration]
tags: [Dagster, data pipelines, Python, orchestration, data engineering]
---

I am always looking for ways to improve my data pipelines, and Dagster has been really good to me so far.  I am definitely planning on diving further into it in the future but my initials have been favorable.  Of course, I ran into a a few issues.  But mostly I was able to get things up and running, without too much trouble.  


<img src="/assets/img/streamdagster.png" alt="Dagster streamlit image" width="600px">

I tried to keep it simple, flowing from the NYC Open Data API through various Dagster assets, eventually feeding into both static PNG charts and the dynamic Streamlit dashboard. 

Dagster updates the information and then it is displayed in the Streamlit app.  Here is an exmple of what the Streamlit app looks like:

<img src="/assets/img/streamdagster.png" alt="Dagster streamlit image" width="600px">

The visual representation of the data flow in the README which I encourage you to check out directly on the [GitHub repo](https://github.com/TJAdryan/dagster_starter) walks through the process step by step. 

It was great to be able to use Dagster's built-in decorators to define assets and jobs, making the code cleaner and more maintainable. The use of `@asset` for defining assets and `@job` for was helpful for organizing the jobs.  I did get tripped up from time to time, but the Dagster documentation was really helpful.  I also found the [Dagster Slack community](https://dagster.io/community) had a lot of great hints and encouraging advice.

The scheuduling from inside Dagster is also really nice.  As well as the logs and the ability to find the origins of errors relatively quickly.  I would love to see how other people are using Dagster in their projects.  If you have any tips or tricks, please let me know.  

