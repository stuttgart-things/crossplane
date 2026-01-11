# DAGGER-CI

<details><summary><b>DEPLOY FUNCTIONS</b></summary>

```bash
dagger call -m ./.dagger deploy-functions \
--kube-config file:///home/sthings/.kube/xplane \
--progress plain
```

</details>

<details><summary><b>DEPLOY CONFIGURATIONS</b></summary>

```bash
dagger call -m ./.dagger deploy-configurations \ --kube-config file:///home/sthings/.kube/xplane \
--progress plain
```

</details>
