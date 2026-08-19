# What the Heck is H3?

H3 is an open-source spatial indexing system that covers the entire surface of the Earth in a continuous grid of **hexagons**.

Instead of dealing with complex map shapes or raw latitude/longitude coordinates, H3 assigns a unique **64-bit ID number** to every single hexagon on the planet.

---

## Who created it and why?
It was created by **Uber**.

Uber deals with millions of live GPS signals every second (riders, drivers, food deliveries). They needed a stupidly fast way to:
* Calculate **Surge Pricing** in real-time for hyper-local areas.
* Match riders to the closest drivers in milliseconds.
* Aggregate massive spatial metrics without melting their database servers.

---

## What problem does it actually fix?

Traditional map analysis has three massive pain points that H3 solves:

1. **City boundaries make no statistical sense:** Neighborhoods and ZIP codes come in completely random shapes and sizes. You can't compare a massive suburban area to a tiny downtown block without distorting your data.
2. **Polygon math is brutally slow:** Checking if a GPS point $(lat, lon)$ falls inside a complex city boundary requires heavy geometry calculations (`ST_Contains`). Doing that on millions of rows will choke your CPU.
3. **Square grids lie about distance:** In a grid of squares, the 4 corner neighbors are farther away than the 4 edge neighbors (by a factor of $\sqrt{2}$). This distorts proximity calculations, radius searches, and heatmaps.

---

## How does H3 fix it?

H3 turns a heavy geometry problem into a simple math problem:

* **Hexagons are perfect for spatial math:** Every hexagon has 6 neighbors, and all 6 are at the **exact same distance** from the center. No diagonal bias.
* **Fast ID lookups instead of geometry:** It converts a GPS point into a plain integer ID (like `8a2a1072b59ffff`). Doing a database `JOIN` or `GROUP BY` on plain numbers takes milliseconds, whereas vector geometry operations take minutes.
* **16 Zoom Levels (Resolutions):** H3 supports 16 nested resolution levels (from continent-sized hexagons down to sub-meter backyard hexes). You can aggregate data up or drill down instantly just by changing the resolution parameter.

---

## In Short

H3 throws out slow vector polygons and replaces them with **fast numerical IDs**, allowing you to run spatial analytics at standard SQL speed.
