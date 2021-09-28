# Keysight CloudLens sandbox on Google Cloud with Cloud IDS and 3rd party sensor

## Overview

This sandbox is targeting traffic monitoring scenario in Google Cloud with a combination of native Cloud IDS service and a 3rd party network traffic sensor. At the moment of writing, Google Cloud IDS does not support its simulteneous use with 3rd party sensors. There are cases, when Google Cloud customers have a need to use a 3rd party sensor, for example, Zeek network traffic analyzer, to enable threat hunting efforts, or any other reason. At the same time, they might find ease of use provided by Cloud IDS, appealing to enable network threat detection. Although such cases are not supported by Cloud IDS yet, it becomes possible to implement them via Keysight CloudLens - a distributed cloud packet broker. As with physical network packet brokers, CloudLens is capable of aggregating monitored cloud traffic via its collectors, and then feeding it to both 3rd party tools like Zeek, as well as Cloud IDS, for analysis and detection.

The goals of the sandbox are:

* Validate compatibility of CloudLens operational model with Cloud IDS.
* Provide a blueprint for CloudLens deployment in Google Cloud to feed multiple network analysis tools.

## Diagram

![CloudLens sandbox with Google Cloud IDS and 3rd party tool diagram](diagrams/GCP_CL_CIDS_DUO.png)
