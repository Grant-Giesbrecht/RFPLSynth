# RFPLSynth
Automatic Microwave Network Synthesis using:
	* Simplified Real Frequency Technique
	* Foster Network Synthesis
	* Cauer Network Syntehsis

## Installation Process
Once the dependencies (listed below) are fullfilled, installing the package just
requires saving the entire RFPLSynth directory somewhere permanent, then running
the installer script 'install.m'. This script adds the directories containing
the source code to MATLAB's path and verifys the required toolboxes are
installed.

## Uninstalling the Package:
To uninstall the package completely:
	1. From within MATLAB, modify the Path to remove every directory contained within RFPLSynth.
 	2. Delete the SRFTSynth directory.
	3. If desired, individually remove the dependent toolboxes and MSTD. MSTD is removed the same way,
	by erasing it from the path and deleting the MSTD folder.


### Dependencies

 * MSTD (https://github.com/Grant-Giesbrecht/MSTD)
 * Toolboxes:
 	* control_toolbox
	* optimization_toolbox
	* rf_toolbox


## Basics

### How This Package Works
This package performs simple network synthesis from abstract design goals using
a combination of methods. The abstract parameters are converted to a series of
polynomials which describe the circuit's S-parameters using the Simplified Real
Frequency Technique (SRFT). These polynomials are called f(s), h(s), and g(s).
From them the input impedance, transfer function, and many other metrics can be
found.

Once the polynomials are found, a physical circuit is derived from the
polynomials using the processes described by Foster and Cauer. The user can
specify their desired circuit architecture at this point, selecting from 1st and
2nd for Foster and Cauer networks.

### Sources and Documentation

This project implemented SRFT as described by P. Jarry & J. Beneat in "Microwave Amplifier and Active Circuit
Design Using the Real Frequency Technique". Unless otherwise stated, all
equation numbers, chapter numbers, sections, etc will refer to this book.
Additionally, the authors and their book are frequently referred to in comments
as JB or J+B.

## Contact

Author: Grant Giesbrecht

Institution: University of Colorado Boulder, Electrical and Computer Engineering

email: grant.giesbrecht@colorado.edu
