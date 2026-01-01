import csv
import cocotb
from pathlib import Path
import numpy as np
import plotly.graph_objects as go
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from plotly.subplots import make_subplots

# Fixed-point helpers (Q1.15)
FRAC_BITS = 15
SCALE = 1 << FRAC_BITS

# Dataset loader (Updated for Operators)
DATASET_FOLDER = "test_files"

def float_to_q15(x: np.ndarray) -> np.ndarray:
    """
    Convert float array to Q1.15 fixed-point representation.
    
    :param x: Input float array
    :return: Numpy array of int16 in Q1.15 format
    """
    x = np.clip(x, -0.999969, 0.999969)
    return np.round(x * SCALE).astype(np.int16)

def q15_to_float(q: np.ndarray) -> np.ndarray:
    """
    Convert Q1.15 fixed-point array to float representation.

    :param q: Input array in Q1.15 format (int16)
    :return: Numpy array of floats
    """
    return np.array(q, dtype=np.int16) / float(SCALE)

def load_dataset(signal_type="synthetic"):
    signals = {}
    fs = 2000.0
    duration = 0.5 

    if signal_type == "synthetic":
        # Create a chirp or mixed frequency to see operator responses
        t = np.arange(0, duration, 1.0 / fs)
        # Mix 10Hz and 100Hz to see how energy operators react to transients
        x = 0.6 * np.sin(2 * np.pi * 10 * t) + 0.3 * np.sin(2 * np.pi * 150 * t)
        signals["mixed_sine"] = {
            "fs": fs, "t": t, "x_float": x, "x_q15": float_to_q15(x),
        }
    elif signal_type == "lfp":
        filename = "test_signal_20170224_16.txt"
        print(f"Loading real LFP data. {DATASET_FOLDER}/lfp/{filename}")
        path_to_file = Path(__file__).parent.parent.parent / DATASET_FOLDER / "lfp" / filename
        data = np.loadtxt(path_to_file, dtype=np.int16)
        signals["lfp_real"] = {
            "fs": fs,
            "t": np.arange(len(data)) / fs,
            "x_float": q15_to_float(data),
            "x_q15": data,
        }
    return signals

# Run Operators DUT
async def run_operators(dut, x_q15):
    # Reset
    dut.rst.value = 1
    dut.data_in.value = 0
    for _ in range(10): await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    # Dictionary to store results
    res = {"tkeo": [], "ed": [], "aso": [], "ado": []}

    for sample in x_q15:
        dut.data_in.value = int(sample)
        await RisingEdge(dut.clk)
        
        # Capture current outputs
        res["tkeo"].append(int(dut.tkeo_out.value))
        res["ed"].append(int(dut.ed_out.value))
        res["aso"].append(int(dut.aso_out.value))
        res["ado"].append(int(dut.ado_out.value))

    return {k: np.array(v) for k, v in res.items()}

# Main cocotb test
@cocotb.test()
async def test_signal_emphasizers(dut):
    """
    Validation for TKEO, ED, ASO, and ADO
    """
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    await Timer(1, units="ns")

    # Change to "lfp" to test your real files
    signals = load_dataset(signal_type="lfp")

    for name, sig in signals.items():
        dut._log.info(f"Processing Operators with: {name}")

        t = sig["t"]
        results = await run_operators(dut, sig["x_q15"])

        # CSV Output
        csv_name = f"operators_comparison_{name}.csv"
        with open(csv_name, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["t", "input", "tkeo", "ed", "aso", "ado"])
            for i in range(len(results["tkeo"])):
                w.writerow([t[i], sig["x_q15"][i], results["tkeo"][i], 
                            results["ed"][i], results["aso"][i], results["ado"][i]])

        # Multi-Plot Comparison (Plotly)
        fig = make_subplots(
            rows=5, cols=1,
            shared_xaxes=True,
            vertical_spacing=0.05,
            subplot_titles=("Raw Input Signal", "TKEO Energy", "ED Energy", "ASO Magnitude", "ADO Magnitude")
        )

        fig.add_trace(go.Scatter(x=t, y=sig["x_q15"], name="Input"), row=1, col=1)
        fig.add_trace(go.Scatter(x=t, y=results["tkeo"], name="TKEO"), row=2, col=1)
        fig.add_trace(go.Scatter(x=t, y=results["ed"], name="ED"), row=3, col=1)
        fig.add_trace(go.Scatter(x=t, y=results["aso"], name="ASO"), row=4, col=1)
        fig.add_trace(go.Scatter(x=t, y=results["ado"], name="ADO"), row=5, col=1)

        fig.update_layout(height=1200, width=1000, title_text=f"Operator Validation: {name}", showlegend=False)
        
        html_name = f"report_{name}.html"
        fig.write_html(html_name)
        dut._log.info(f"Full analysis saved to {html_name}")