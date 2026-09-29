# JTAG TAP testing on VexRiscv
Github repository: https://github.com/snapaa257/bringup_jtag.git

## Introduction
VexRiscv core with TAP generated using the GenSmallAndProductive.scala config + EmbededRiscvJtag. 
This test seeks to verify the TAP wiring is a success after the regeneration.
NOTE: GenSmallAndProductive scala config does not come with TAP unlike GenFull.

Motive of test is to hand-clock the TAP, and read the IDCODE back to verify a successfull wiring.

## Installation
As time of this testing done, Ubuntu used.
1. **Prerequisity**: Icarus Verilog
   ```bash
    sudo apt install iverilog
   ```

## Usage examples
A small note on the two test options here.

1. **full test**
Runs a test on the VexRiscv generated with GenFullWithOfficialDebug.scala config
   ```bash
   ./full.sh   
    ```

2. **small test**
Runs a test on the VexRiscv generated with GenSmallAndProductiveWithOfficialDebug.scala config
   ```bash
   ./small.sh   
    ```

## Addition
**[Optional]** To regenerate the VexRiscv core. Github repository: {working on it}
