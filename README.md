## Twigs (not STIX)

This is my personal take at my ideal form for the next versions of STIX and CybOX. In other words, this is my personal opinion, informed by what happens on the lists and in OASIS but not following with that consensus.

**Again: These are not STIX or CybOX!! These are not STIX 2.0 and CybOX 3.0!! Official development happens in OASIS. I just wanted a place where I could try things out.**

## Design Goals

1. Remain true to the core goals of STIX and CybOX. The core of these languages is very solid: the top-level constructs, the data in them, etc. Some of the non-related design decisions could use some work. To that end, my goal is to stay as true as possible to the basic data model while simplifying how that data model is implemented.

2. Solve 90% of the problem with 20% of the code. That means some use cases will be unaddressed. Those can be implemented as extensions to this model.

3. One way to do things. That one way might be more complicated for some usages, but IMO having a single more complicated way is actually less complicated than one more complicated way and one less complicated way.

4. Prefer simple representations whenever possible.

5. Solve use cases we have now, evolve in the future as we expand.

## High-level decisions

1. Implemented as JSON. XML encourages complexity and a binary encoding is harder to work with. If scale becomes an issue, reconsider. (See #5 above)

2. The data model is layer: an abstract data model, a binding to JSON that adds fields necessary for automated processing, and finally a set of messages that define the actual exchanges.

3. Top-level relationships, and any other references between objects are always by id. In other words, no embedding top-level constructs in other top-level constructs.

4. Data markings are at the object level, no more and no less. More granular markings could be done either by extension or by issuing multiple versions of the object.

5. Refactor CybOX to remove the Observable layer. CybOX becomes just the objects. STIX has a "Sighting" object that's what used to be Observable. Patterning is in Indicator.

6. Add a CTI-Common specification for high-level constructs used across all languages.

7. All top-level objects have a `_type` field that indicate what they are.

8. Remove controlled vocabularies and replace with hardcoded enumerations. In most cases, implement these as a "Statement" that also allows for descriptive text.

## Open Questions

1. Sightings are very tricky:
  1. Do you sight objects or indicators?
  2. Do you represent a list of times that it was seen? A single time? A count?
  3. Do you include the full object or just the fact that something was seen?

2. What do you do about producer?

3. What do you do about versioning?

4. How do you encode allowed relationships?

5. Names vs. titles

6. Patterning in CybOX is unaddressed
