# BEAR inputs

This folder contains the Datasets, queries and results of [BEAR](https://aic.ai.wu.ac.at/qadlod/bear.html). 
It's intended to be a local cache of the official website:

```
bear-inputs/
└── {datasetName}/
    ├── datasets/
    │   └── {granularity}-{policy}.{ext}
    │
    ├── queries/
    │   ├── raw/
    │   │   └── {name}.txt
    │   ├── rq/
    │   │   └── {name}.rq
    │   └── extra/               # optional, drop additional .rq/.sparql files here
    │       └── custom-name.rq
    │
    └── results/
        └── {name}-{granularity}-{resultType}/
            └── {queryIndex}.txt
```

Files are not committed, but their hash are committed in `locked-sources.json` to unsure reproducibility.

If you want to use a new version of a file : delete the file in its bear-inputs subfolder (`rm <path>`), replace the hash by `""` in `locked-sources.json` and run `./download-and-verify.sh <path>`

### Adding extra queries

You can extend a dataset with custom queries by placing ready-to-run `.rq` (or `.sparql`) files inside `bear-inputs/{datasetName}/queries/extra/`. They will be copied next to the generated queries when `prepare-rq-queries.sh` runs and will therefore be executed by `run-experiment.sh`. To remove an extra query, delete it from the `extra/` directory and rerun the preparation script with the `--force` flag so the generated directory is refreshed.
