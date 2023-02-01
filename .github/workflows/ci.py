import os
import sys
import dagger

with dagger.Connection(dagger.Config(log_output=sys.stdout, execute_timeout=1800)) as client:

    for svc in ["front", "api"]:
        src = (client
               .host()
               .directory(svc))

        _ = (client
             .container()
             .build(src, "Dockerfile")
             .publish("ghcr.io/" + os.environ["OWNER"]+"/wasi-demo-" + svc + ":latest"))
