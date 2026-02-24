Audio engineers speak a different language than electrical engineers, even
though they share some elements of their discipline.

# Speakers

You need to know what you're driving in order to design an amplifier. Speaker
construction turns out to be pretty complicated. The speaker box construction
impacts the quality of the audio, and multi-driver speakers need to include an
internal crossover to maximize speaker performance. There used to be a company
called Meniscus Audio that produced speaker building kits. You can still buy
their designs through Caritas Audio. The specifications for these are available
without purchasing the design, and it seems that SB Acoustics is a popular
choice for speaker drivers. Dayton Audio is also mentioned.

Amplifier designers might use $P = \frac{V^2}{R}$ to determine the voltage gain
needed to drive the speaker, and look to match the output impedance of the
amplifier to the speaker. In this case, P is the _rated power handling_ of the
speaker and R is the _nominal impedance_.

# Inputs

Audio signals generally fall into "levels":

1. Instrument level
2. Line level
3. Microphone level
4. Speaker level

These are typically specified in dB, with one of two reference voltages--either
dBm (potentially dBu for unbalanced) or dBV. Some signals will travel on
_balanced connections_, which just means they're differential pairs with
impedance-matched conductors.

# Effects Boxes

# Preamp Stages

# Transformers

# Enclosures

# Decals and Labels

# Tagboard and Terminal Strips

# Measuring Performance

* [How to Measure Total Harmonic Distortion of an Op-Amp][1]
* Power?

# Design and Simulation

Questions:
1. If a multi-driver speaker uses a crossover, the drivers must be wired in
   parallel. So how does the speaker manufacturer guarantee a nominal impedance
   of 4-8 ohms? Just with plain ol' resistors?
2. What is the output impedance of a typical effects box? I presume it would be
   in the ~100 Ohm range. I can review the FuzzFace schematic to determine
   this, and generalize.
3. I presume preamp stages are not used in Hi-Fi home audio (except for a
   cathodyne phase-inverter to feed a push-pull power amp). Can I confirm this?
4. How do I build a mains detector?
5. How does one obtain transformers for tube amps?

[1]: https://www.ti.com/lit/an/sboa580/sboa580.pdf
