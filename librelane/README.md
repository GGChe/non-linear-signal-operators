# Librelane Flow for Non-Linear Operators

This directory contains the configuration to run the LibreLane ASIC flow for the `operators_top` design.

## Usage

To run the full RTL-to-GDSII flow:

```bash
cd librelane
librelane config.json
```

## View Results

To view the final layout in KLayout:

```bash
librelane --last-run --flow openinklayout config.json
```

To view the design in OpenROAD GUI (useful for debugging placement/routing):

```bash
librelane --last-run --flow OpenInOpenROAD config.json
```

Or manually loading the design:
1. Launch: `openroad -gui`
2. Load DEF: `read_def runs/<RUN_TAG>/results/routing/operators_top.def`
3. Load LEF: `read_lef runs/<RUN_TAG>/tmp/merged.lef`

## Configuration

The design targets a 20ns clock (50 MHz) and includes the top-level module `operators_top` along with all submodules:
- `tkeo.v` (Teager-Kaiser Energy Operator)
- `ed.v` (Energy of Derivative)
- `aso.v` (Amplitude Slope Operator)
- `ado.v` (Amplitude Difference Operator)
