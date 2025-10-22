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
    │   └── {name}.txt
    │
    └── results/
        └── {name}-{granularity}-{resultType}/
            └── {queryIndex}.txt
```

Files are not committed, but their hash are committed in `locked-sources.json` to unsure reproducibility.

If you want to use a new version of a file : delete the file in its bear-inputs subfolder (`rm <path>`), replace the hash by `""` in `locked-sources.json` and run `./download-and-verify.sh <path>`
