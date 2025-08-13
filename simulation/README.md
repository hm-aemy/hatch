# Run Verilator simulation

First, build the system:

```bash
make build-verilator
```

After that you can run the system with different software configurations by using the following command:

```bash
SW_HEX=<path-to-sw-hex> make sim-verilator
```