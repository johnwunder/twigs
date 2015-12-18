## Twigs (not STIX)

http://twigs-cti.herokuapp.com

## Design Goals

1. Simplicity
  * Target the 80%
  * Easy to implement
  * Easy to understand
  * One way of doing things
1. Reduce Optionality
  * Support customization in a standardized way
  * Don’t allow customization everywhere, only where likely to be used
1. Standardization
  * Do things the same way across STIX and CybOX
  * Reuse similar structures across similar yet distinct parts of the model
1. Modularity
  * Provide building blocks that can be reused
  * Ensuring tight cohesion and low coupling
1. Flexibility
  * Use modularity to provide flexibility
  * Flexibility is not as important as simplicity or reducing optionality
1. Improve Analysis
  * Explicitly modeled as a graph
  * Ensure data structures are separate from metadata
1. STIX 1.x compatibility (i.e., content conversion ala STIX Ramrod)
  * Upconverting is a higher priority than downconverting

## High-level decisions

1. Implemented in JSON and JSON Schema per the CTI TC ballot and CTI TC JSON style guide.

1. Add a CTI Common specification for high-level constructs used across all languages.

1. The Observable and Event layers are removed from CybOX, which becomes a library of CybOX objects. In STIX, the "Observation" object covers observable instances, and indicator patterning covers observable patterns. Sightings are accomplished using a relationship between an Observation and an Indicator.

1. Controlled vocabularies are limited, and where used they allow both a hardcoded enum in the STIX default vocabulary as well as an extension value in an external vocabulary.
